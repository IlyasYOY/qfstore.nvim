local function root(path)
    local source = debug.getinfo(1, "S").source:sub(2)
    local repo = vim.fn.fnamemodify(source, ":p:h:h")
    if not path or path == "" then
        return repo
    end
    return vim.fs.joinpath(repo, path)
end

local test_home = vim.env.QFSTORE_TEST_HOME or root ".test-home"

vim.env.XDG_CONFIG_HOME = vim.fs.joinpath(test_home, "config")
vim.env.XDG_DATA_HOME = vim.fs.joinpath(test_home, "data")
vim.env.XDG_CACHE_HOME = vim.fs.joinpath(test_home, "cache")
vim.env.XDG_STATE_HOME = vim.fs.joinpath(test_home, "state")

for _, dir in ipairs {
    vim.env.XDG_CONFIG_HOME,
    vim.env.XDG_DATA_HOME,
    vim.env.XDG_CACHE_HOME,
    vim.env.XDG_STATE_HOME,
} do
    vim.fn.mkdir(dir, "p")
end

vim.opt.runtimepath:prepend(root())
vim.opt.shadafile = "NONE"
vim.opt.swapfile = false

package.path = root "?.lua" .. ";" .. root "?/init.lua" .. ";" .. package.path

vim.cmd.runtime "plugin/qfstore.lua"
