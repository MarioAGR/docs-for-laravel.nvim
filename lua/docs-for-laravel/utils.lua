local M = {}

M.available_docs = { '12.x', 'master', '11.x', '10.x', '9.x' }

-- TODO: Find a way to truly select the latest version
-- Maybe use the URL to fetch the versions (and cache it somehow)
--  then sort
--    then use the greatest number?
M.get_latest_version = function(opts)
    local version = opts.version
    if version == 'latest' then
        version = M.available_docs[1]
    end
    return version
end

M.directory_for_saving = function(path, version)
    local exists_version = vim.iter(M.available_docs):any(function(v)
        return v == version
    end)

    if not exists_version then
        vim.notify(string.format('Cannot construct directory to be used, the version %s does not exist.', version), vim.log.levels.ERROR)
    end

    return string.format('%s/version_%s/', path, version)
end

return M
