# qfstore.nvim Agent Guidelines

## Project shape

- Runtime storage and picker APIs live in \`lua/qfstore/init.lua\`.
- Automatic user-command registration lives in \`plugin/qfstore.lua\`.
- Tests run in isolated project and XDG directories under ignored
  \`.test-work/\` and \`.test-home/\`.
- The plugin has no required runtime dependencies. Oil support must remain
  optional.

## Compatibility

- Support Neovim 0.11 and newer.
- Preserve the commands and Lua API documented in \`README.md\`.
- Preserve the project-local \`.vim/lists/*.json\` format so existing entries
  remain loadable without migration.
- Keep quickfix loads as new stack entries and continue opening the quickfix
  window. Location-list loads must remain window-local.

## Commands

- \`make check\` runs the canonical formatting, lint, and test suite.
- \`make test\` runs tests with the current \`nvim\`.
- \`make test NVIM_VERSION=v0.11.7\` runs tests with a downloaded release.
- \`make format\` formats Lua sources.

Do not commit or push changes unless the user explicitly asks.
