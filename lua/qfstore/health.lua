local M = {}

local COMMANDS = {
    "QfStore",
    "QfLoad",
    "QfRemove",
    "QfBrowseStore",
    "LlStore",
    "LlLoad",
    "LlRemove",
    "LlBrowseStore",
}

function M.check()
    vim.health.start "qfstore.nvim"

    local loaded, qfstore = pcall(require, "qfstore")
    if loaded and type(qfstore) == "table" then
        vim.health.ok "qfstore is available"
    else
        vim.health.error("qfstore is not available", qfstore)
        return
    end

    local commands = vim.api.nvim_get_commands {}
    for _, command in ipairs(COMMANDS) do
        if commands[command] then
            vim.health.ok(":" .. command .. " is registered")
        else
            vim.health.error(":" .. command .. " is not registered")
        end
    end

    local ok, store = pcall(require("qfstore.config").store_dir)
    if not ok then
        vim.health.error("Store directory cannot be resolved", store)
    elseif vim.fn.isdirectory(store) == 1 then
        vim.health.ok("Store directory exists: " .. store)
    else
        vim.health.info(
            "Store directory will be created on first write: " .. store
        )
    end

    if pcall(require, "oil") then
        vim.health.ok "oil.nvim is available for browse commands"
    else
        vim.health.info "oil.nvim is unavailable; browse commands will use :edit"
    end
end

return M
