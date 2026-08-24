# qfstore.nvim Agent Guidelines

## Scope and compatibility

- Support Neovim 0.11 and newer.
- Preserve every `Qf*` and `Ll*` command and the Lua API documented in
  `README.md` and `doc/qfstore.txt`.
- Preserve the project-local `.vim/lists/*.json` format without migration.
- Keep quickfix loads as new stack entries and continue opening the quickfix
  window when configured. Location-list loads remain window-local.
- Oil is optional and browse commands must continue falling back to `:edit`.

## Repository structure

- Runtime modules and focused specs live together under `lua/qfstore/`.
- Automatic user-command registration remains in `plugin/qfstore.lua`.
- Startup-command and filesystem integration coverage remains under `tests/`.
- Vim help lives in `doc/qfstore.txt`; keep `doc/tags` synchronized.
- Isolate XDG state, logs, fixtures, and working directories under ignored
  `.test-home/` and `.test-work/`.

## Development commands

- `make check` is the canonical non-mutating lint, test, and help check.
- `make test NVIM_VERSION=v0.11.7` verifies minimum compatibility.
- `make test NVIM_VERSION=v0.12.5` verifies current stable compatibility.
- `make test NVIM_VERSION=nightly` is the non-blocking CI probe.
- `make format` formats Lua sources.

Do not commit, push, tag, or publish unless the user explicitly asks.
