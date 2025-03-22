local M = {}

-- TODO: Add warning or anything that this depends on  a markdown viewer
-- TODO: Add requirement to have Nvim 0.10? idk

-- List of available docs to download. The order is latest LTS, then master, then ...
Available_docs = { '12.x', 'master', '11.x', '10.x', '9.x' }
Plugin_opts = require('docs-for-laravel.options')
local utils = require('docs-for-laravel.utils')
local scanned_docs = {}

---@param user_opts? DocsForLaravelOptions
M.setup = function(user_opts)
    -- Merge default options and those provided by the user
    Plugin_opts = vim.tbl_deep_extend('force', Plugin_opts, user_opts or {})

    -- Scan directories already saved
    local doc_directories_availables = vim.fn.systemlist({ 'ls', Plugin_opts.docs_path })
    for count = 1, #doc_directories_availables do
        local full_path = Plugin_opts.docs_path .. doc_directories_availables[count]
        local dir_version = doc_directories_availables[count]:gsub('version_', '')
        local files_list = vim.fn.systemlist({ 'ls', '-1', full_path })
        scanned_docs[dir_version] = files_list
    end

    -- Create user commands
    -- TODO:
    -- 1. Docs4LaravelDownload
    --   1.1 List (:command-complete) the available docs (git branches)
    --   Maybe use https://api.github.com/repos/laravel/docs/branches ?
    --   curl https://api.github.com/repos/laravel/docs/branches | jq '.[].name'
    -- 2. Whe using DocsForLaravel (D4L) list the available markdown files
    --   2.1 First argument can be the version (list the downloaded versions (:command-complete))

    vim.api.nvim_create_user_command('DocsForLaravelDownload', function(command_opts)
        -- NOTE: ¿Redundant due to nargs?
        if #command_opts.fargs > 1 then
            vim.notify('Please provide just one argument', vim.log.levels.ERROR)
            return
        end

        local selected_version = command_opts.fargs[1] or utils.get_latest_version()

        if not vim.tbl_contains(Available_docs, selected_version) then
            vim.notify('The given version ' .. selected_version .. ' is not available for download, please select a valid one.', vim.log.levels.WARN)
            return
        end

        local version_directory = utils.directory_for_saving(selected_version)

        if not (vim.uv or vim.loop).fs_stat(version_directory) then
            local laravel_docs_repo = 'https://github.com/laravel/docs.git'
            -- TODO: Maybe show progress in some way?
            local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=' .. selected_version, laravel_docs_repo, version_directory })
            if vim.v.shell_error ~= 0 then
                vim.api.nvim_echo({
                    { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
                    { out, 'WarningMsg' },
                    { '\nPress any key to exit...' },
                }, true, {})
                vim.fn.getchar()
                os.exit(1)
            else
                vim.notify('Downloaded the docs at:\n' .. version_directory, vim.log.levels.INFO)
            end
        else
            vim.notify('The docs already exists at:\n' .. version_directory, vim.log.levels.INFO)
        end
    end, {
        desc = 'Download Laravel docs, if given an argument then download that version',
        nargs = '?',
        ---@see https://github.com/laravel/docs/branches/all
        ---@see https://laravel.com/docs/12.x/releases#support-policy
        complete = function(ArgLead)
            local results = vim.iter(Available_docs)
                :filter(function(v)
                    -- Pass plain as true to ignore "magic" characters and do a "substring"
                    return (string.find(v, ArgLead, 1, true) ~= nil)
                end)
                :totable()
            return results
        end,
    })

    vim.api.nvim_create_user_command('DocsForLaravelShow', function(command_opts)
        local selected_version = command_opts.fargs[1]
        local doc_to_show = command_opts.fargs[2] or command_opts.fargs[1]
        -- TODO: Take in account :command-modifiers
    end, {
        desc = 'Read Laravel docs in a buffer like :help',
        nargs = '+',
        complete = function(ArgLead, CmdLine)
            -- TODO: Wtf did I did?
            local version = utils.get_latest_version()

            -- 2 and 3 cause it includes the name of the command
            local first_arg = vim.fn.split(CmdLine, ' ')[2] or nil
            local second_arg = vim.fn.split(CmdLine, ' ')[3] or nil

            if first_arg == nil then
                return scanned_docs[version]
            end

            local exists_version = vim.iter(vim.tbl_keys(scanned_docs)):any(function(v)
                return (string.find(v, first_arg or '', 1, true) ~= nil)
            end)

            if exists_version and (ArgLead == first_arg) then
                local first_arg_versions = vim.iter(Available_docs)
                    :filter(function(v)
                        if first_arg then
                            return (string.find(v, first_arg, 1, true) ~= nil)
                        else
                            return false
                        end
                    end)
                    :totable()

                if first_arg_versions then
                    return first_arg_versions
                end
            end

            local results = vim.iter(scanned_docs[first_arg])
                :filter(function(v)
                    -- Pass plain as true to ignore "magic" characters and do a "substring"
                    return (string.find(v, ArgLead, 1, true) ~= nil)
                end)
                :totable()
            return results
        end,
    })
end

return M
