---@class docsForLaravel.options
---@field version string # Version of the docs to view when running :DocsForLaravel <doc>
--- # Maybe use curl https://api.github.com/repos/laravel/docs/branches | jq '.[].name' ?
---| 'latest'
---| 'master'
---| '12.x'
---| '11.x'
---| '10.x'
---| '9.x'
---| '8.x'
---| '7.x'
---| '6.x'
---| '5.8'
---| '5.7'
---| '5.6'
---| '5.5'
---| '5.4'
---| '5.3'
---| '5.2'
---| '5.1'
---| '5.0'
---| '4.2'
---| '4.1'
---| '4.0'
---@field docs_path string # Where the markdown files will be stored, by default will be vim.fn.stdpath('data')/docs-for-laravel/
return {
    version = 'latest',
    docs_path = vim.fn.stdpath('data') .. '/docs-for-laravel/',
}
