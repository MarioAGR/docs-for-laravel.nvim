local M = {}

-- List of available docs to download. The order is latest LTS, then master, then ...
local opts = require('docs-for-laravel.options')
local utils = require('docs-for-laravel.utils')
local uv = vim.uv

---@param user_opts? docsForLaravel.options
M.setup = function(user_opts)
    if vim.fn.has('nvim-0.10') == 0 then
        error('docs-for-laravel requires Neovim 0.10 or higher')
    end

    -- Merge default options and those provided by the user
    opts = vim.tbl_deep_extend('force', opts, user_opts or {})

    -- Remove trailing "/" if there's one
    opts.docs_path = string.gsub(opts.docs_path, '/$', '', 1)

    utils.scan_local_docs(opts)

    vim.api.nvim_create_user_command('DocsForLaravelDownload', function(command_opts)
        local selected_version = command_opts.fargs[1] or utils.get_latest_version(opts)

        if not vim.tbl_contains(utils.available_docs, selected_version) then
            vim.notify('The given version ' .. selected_version .. ' is not available or is invalid, please select a valid one.', vim.log.levels.ERROR)
            return
        end

        local version_directory = utils.directory_for_saving(opts.docs_path, selected_version)

        if command_opts.bang and uv.fs_stat(version_directory) then
            utils.rm_dir(version_directory)
        end

        if not uv.fs_stat(version_directory) then
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
                utils.local_docs[selected_version] = utils.scan_directory(version_directory)
                vim.notify('Downloaded the docs for version ' .. selected_version)
            end
        else
            vim.notify('The docs already exists, to force a `git clone` call the command with a bang (!)', vim.log.levels.WARN)
        end
    end, {
        desc = 'Download Laravel docs for configured version (latest by default), if given an argument then download that version.',
        nargs = '?',
        bang = true,
        complete = function(ArgLead, CmdLine, CursorPos)
            local args_num = #vim.fn.split(CmdLine, ' ')
            local current_arg = vim.fn.split(CmdLine, ' ')[2]

            local results_not_local = vim.iter(utils.available_docs)
                :filter(function(v)
                    return (vim.iter(vim.tbl_keys(utils.local_docs)):find(v) == nil)
                end)
                :filter(function(v)
                    return (string.find(v, ArgLead, 1, true) ~= nil)
                end)
                :totable()

            if args_num == 1 or ArgLead == current_arg then
                return results_not_local
            end

            return {}
        end,
    })

    vim.api.nvim_create_user_command('DocsForLaravelShow', function(command_opts)
        local selected_version = command_opts.fargs[1]
        local doc_to_show = command_opts.fargs[2] or command_opts.fargs[1]

        if selected_version == doc_to_show then
            selected_version = utils.get_latest_version(opts)
        end

        if not vim.iter(vim.tbl_keys(utils.local_docs)):find(selected_version) then
            vim.notify(string.format("You haven't downloaded version %s.", selected_version), vim.log.levels.ERROR)
            return
        end

        if not vim.iter(utils.local_docs[selected_version]):find(doc_to_show) then
            vim.notify(string.format('%s file does not exist, try selecting a diferent version or checking the name.', doc_to_show), vim.log.levels.ERROR)
            return
        end

        vim.cmd('split')

        local new_buf = vim.api.nvim_create_buf(false, false)
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, new_buf)
        vim.api.nvim_buf_set_name(new_buf, doc_to_show)

        local full_path = string.format('%s/version_%s/%s.md', opts.docs_path, selected_version, doc_to_show)
        vim.cmd('read ' .. full_path)
        vim.api.nvim_set_option_value('ft', 'markdown', {
            buf = new_buf,
        })
        vim.api.nvim_set_option_value('modifiable', false, {
            buf = new_buf,
        })
    end, {
        desc = 'Read Laravel docs in a buffer like :help',
        nargs = '+',
        complete = function(ArgLead, CmdLine, CursorPos)
            local version = utils.get_latest_version(opts)
            local results = {}

            local fargs = vim.fn.split(CmdLine, ' ')

            -- 2 and 3 cause it includes the name of the command
            local first_arg = fargs[2] or nil
            local second_arg = fargs[3] or nil

            -- Show results for downloaded versions and the docs for the "latest" version
            if first_arg == nil then
                results = vim.tbl_extend('keep', results, vim.tbl_keys(utils.local_docs), utils.local_docs[version])
                return results
            end

            -- Check if the first argument is a version and it exists
            local exists_version = vim.iter(vim.tbl_keys(utils.local_docs)):any(function(v)
                return (string.find(v, first_arg or '', 1, true) ~= nil)
            end)

            -- If the first argument is looking for a version and it exists
            -- return current available downloaded versions
            if (ArgLead == first_arg) and exists_version then
                local first_arg_versions = vim.iter(utils.local_docs)
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

            -- If there are more arguments ignore them and dont "show" anything
            -- NOTE: When doing <DocsForLaravelShow 12.x db > shows mongodb.md,
            -- I want to progress and don't be stuck here so...
            -- I'll leave it like that .-.
            if #fargs <= 3 and (string.find(CmdLine, '%s$') ~= nil) and exists_version then
                -- If the first argument is satifesied then return available docs
                -- which satisfies second argument
                results = vim.iter(utils.local_docs[first_arg])
                    :filter(function(v)
                        return (string.find(v, second_arg or '', 1, true) ~= nil)
                    end)
                    :totable()
                return results
            end

            return {}
        end,
    })
end

return M
