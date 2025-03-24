local M = {}
local uv = vim.uv

M.available_docs = { 'master', '12.x', '11.x', '10.x', '9.x' }

M.local_docs = {}

M.scan_directory = function(path)
    local entries = {}
    local dir = uv.fs_scandir(path)

    if not dir then
        error('Error reading path ' .. path)
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local name, type = uv.fs_scandir_next(dir)
    while name do
        -- NOTE: Maybe filter by type?
        table.insert(entries, name)
        ---@diagnostic disable-next-line: param-type-mismatch
        name, type = uv.fs_scandir_next(dir)
    end

    return entries
end

M.rm_dir = function(dir_path)
    -- NOTE: Is it asynchronous? If not, make it
    local function delete_content(path)
        local dir = uv.fs_scandir(path)

        if not dir then
            error('Error reading path ' .. path)
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        local name, type = uv.fs_scandir_next(dir)
        while name do
            local full_path = path .. '/' .. name
            if type == 'directory' then
                delete_content(full_path)
            else
                uv.fs_unlink(full_path)
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            name, type = uv.fs_scandir_next(dir)
        end

        local dir_was_removed, err = uv.fs_rmdir(path)
        if not dir_was_removed then
            vim.notify(vim.inspect(err), vim.log.levels.ERROR)
        end
    end

    delete_content(dir_path)
end

M.scan_local_docs = function(opts)
    local doc_directories_availables = M.scan_directory(opts.docs_path)
    for count = 1, #doc_directories_availables do
        local full_path = string.format('%s/%s', opts.docs_path, doc_directories_availables[count])
        local version_wo_dir_prefix = doc_directories_availables[count]:gsub('version_', '')
        local files_list = M.scan_directory(full_path)
        files_list = vim.iter(files_list)
            :map(function(v)
                local s = string.gsub(v, '%.md$', '')
                return s
            end)
            :totable()
        M.local_docs[version_wo_dir_prefix] = files_list
    end
end

-- NOTE: Find a way to truly select the latest version?
-- Maybe use the URL to fetch the versions
--  Cache it somehow
--   Then `sort(..., 'n')[2]` to select whatever is latest release ignoring master
M.get_latest_version = function(opts)
    local version = opts.version
    if version == 'latest' then
        version = M.available_docs[2] -- Ignore master and select the next
    end
    return version
end

M.directory_for_saving = function(path, version)
    local exists_version = vim.iter(M.available_docs):any(function(v)
        return v == version
    end)

    if not exists_version then
        error(string.format('Cannot format path to be used, the version %s does not exist.', version))
    end

    return string.format('%s/version_%s', path, version)
end

return M
