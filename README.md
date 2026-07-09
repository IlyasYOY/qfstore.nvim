# qfstore.nvim

`qfstore.nvim` persists Neovim quickfix and location lists as project-local
JSON files. Lists can be restored in later sessions without relying on
transient buffer numbers.

## Requirements

- Neovim 0.11 or newer
- No required plugin dependencies
- [oil.nvim](https://github.com/stevearc/oil.nvim) is optional and is used by
  the browse commands when available

## Installation

With Neovim's built-in `vim.pack`:

```lua
vim.pack.add {
    { src = "https://github.com/IlyasYOY/qfstore.nvim" },
}
```

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "IlyasYOY/qfstore.nvim",
}
```

The plugin registers its commands automatically. There is no `setup()` call.

## Commands

| Command | Description |
| --- | --- |
| `:QfStore [name]` | Store the current quickfix list. |
| `:QfLoad [name]` | Load a named quickfix list, or select one when no name is given. |
| `:QfRemove` | Select and remove a stored quickfix or location-list entry. |
| `:QfBrowseStore` | Browse the store with Oil, falling back to `:edit`. |
| `:LlStore [name]` | Store the current window's location list. |
| `:LlLoad [name]` | Load a named location list, or select one when no name is given. |
| `:LlRemove` | Select and remove a stored quickfix or location-list entry. |
| `:LlBrowseStore` | Browse the store with Oil, falling back to `:edit`. |

When no name is provided, store commands use a `YYYYMMDD-HHMMSS` timestamp.
Storing under an existing name asks before overwriting.

## Storage

Entries are stored relative to Neovim's current working directory:

```text
<cwd>/.vim/lists/<name>.json
```

Each JSON file records the original title, list kind, save time, working
directory, and items. Buffer numbers are converted to filenames so entries
remain usable after restarting Neovim.

The format is compatible with the original implementation from
[IlyasYOY/dotfiles](https://github.com/IlyasYOY/dotfiles).

## Lua API

```lua
local qfstore = require "qfstore"

qfstore.exists "build"
qfstore.list()
qfstore.store { name = "build", loclist = false }
qfstore.load { name = "build" }
qfstore.remove "build"
qfstore.open_store()
qfstore.pick_entry(function(entry)
    if entry then
        print(entry.name)
    end
end)
```

The public functions preserve the same argument and return contracts as the
original dotfiles module.

## Development

```sh
make help
make check
```

`make help` lists the available development targets and options.
Running `make` without a target shows the same help output.
`make check` checks formatting, runs Luacheck, and executes the isolated
headless Neovim test suite. Set `NVIM_VERSION` to test a downloaded release,
for example `make test NVIM_VERSION=v0.11.7`.

## License

MIT
