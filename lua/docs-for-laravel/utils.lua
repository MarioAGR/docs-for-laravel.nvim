local M = {}

M.available_docs = { 'master', '12.x', '11.x', '10.x', '9.x' }

M.local_docs = {}

M.scan_local_docs = function(opts)
    local doc_directories_availables = vim.fn.systemlist({ 'ls', opts.docs_path })
    for count = 1, #doc_directories_availables do
        local full_path = string.format('%s/%s', opts.docs_path, doc_directories_availables[count])
        local version_wo_dir_prefix = doc_directories_availables[count]:gsub('version_', '')
        local files_list = vim.fn.systemlist({ 'ls', '-1', full_path })
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
        vim.notify(string.format('Cannot format path to be used, the version %s does not exist.', version), vim.log.levels.ERROR)
    end

    return string.format('%s/version_%s/', path, version)
end

return M
