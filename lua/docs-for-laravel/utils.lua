local M = {}

-- TODO: Find a way to truly select the latest version
-- Maybe use the URL to fetch the versions (and cache it somehow)
--  then sort
--    then use the greatest number?
M.get_latest_version = function()
    local version = Plugin_opts.version
    if version == 'latest' then
        version = Available_docs[1]
    end
    return version
end

M.directory_for_saving = function(version)
    local exists_version = vim.iter(Available_docs):any(function(v)
        return v == version
    end)

    if not exists_version then
        vim.notify(string.format('Cannot construct directory to be used, the version %s does not exist.', version), vim.log.levels.ERROR)
    end

    local base_directory = require('docs-for-laravel.options').docs_path
    -- Remove trailing "/" in case there's one
    base_directory = string.gsub(base_directory, '/$', '', 1)

    return string.format('%s/version_%s/', base_directory, version)
end

return M
