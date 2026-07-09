std = "luajit"
codes = true

ignore = {
    "122", -- Tests temporarily replace Neovim globals and environment values.
}

read_globals = {
    "vim",
}
