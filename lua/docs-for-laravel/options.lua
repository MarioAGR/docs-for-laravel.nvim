---@class DocsForLaravelOptions
---@field version # Version of the docs to view when running :DocsForLaravel <doc>
---| 'latest'
---| '12.x'
---| '11.x'
---| '10.x'
---| '9.x'
---@field docs_path string # Where the markdown files will be stored, by default will be the <stdpath>/docs-for-laravel/
return {
    version = 'latest',
    docs_path = vim.fn.stdpath('data') .. '/docs-for-laravel/',
}
