# Almost like `:help` but for Laravel docs

- Why _almost_ like `:help` ?
  Cause if you have configured sessions in nvim, when a file of yours is in a window and the docs in another, you may
  think that if you close nvim the docs window would conserve, but no :(.

- Is it better than consulting them via web browser?
  Maybe not, but was fun learning and doing it.

## Requirements:
1. Neovim >= 0.10.0 (recommended)
1. git (used to clone [laravel/docs](https://github.com/laravel/docs))
1. ls (used to list folders)
1. Not strictly required but is nice having a plugin to preview markdown (like
   [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim))

## Installation

```lua
   return {
      'MarioAGR/docs-for-laravel',
   }
```

## Options

```lua
{
   --[[
      By latest it means the LTS release, ex: 12.x
      For now the available versions are defined in lua/docs-for-laravel/options.lua
      Maybe in the future it can be dynamic by fetching the branches from laravel/docs.
   --]]
   version = 'latest',
   --[[
      By default uses the data path, which would be something like:
      ~/.local/share/nvim/docs-for-laravel/
   --]]
   docs_path = vim.fn.stdpath('data') .. '/docs-for-laravel/', 
}
```

## How to use it

To download (git clone --depth=1) just use the following command
- You can use the bang (!) to delete the current downloaded version and git clone it again.
  > I don't want to think about dealing with fetching or pulling each directory.

- If no version specified it will use the one configured in options.
  You can specify a version like `master`, `12.x`, `5.8`, etc.

`DocsForLaravelDownload(!) (version?)`

To view the documentation you can use the following command
- The first argument can be a version (`9.x`) followed by the name of the documentation to open (`blade.md`)

`DocsForLaravelShow (version|file) (file?)`

## TODOs?

- Use GitHub API, list branches, cache then use that as a valid list of versions available.
