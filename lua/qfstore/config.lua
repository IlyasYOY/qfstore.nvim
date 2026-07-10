local M = {}

local defaults = {
    store_dir = function(cwd)
        return vim.fs.joinpath(cwd, ".vim", "lists")
    end,
    default_name = function()
        return os.date "%Y%m%d-%H%M%S"
    end,
    open_quickfix = true,
    json = {
        indent = false,
        indent_size = 2,
        escape_slash = false,
    },
}

local config = {}

local validators = {
    store_dir = function(value)
        return type(value) == "string" or type(value) == "function"
    end,
    default_name = function(value)
        return type(value) == "function"
    end,
    open_quickfix = function(value)
        return type(value) == "boolean"
    end,
    json = function(value)
        if type(value) ~= "table" then
            return false
        end
        for name, option in pairs(value) do
            if name == "indent" or name == "escape_slash" then
                if type(option) ~= "boolean" then
                    return false
                end
            elseif name == "indent_size" then
                if
                    type(option) ~= "number"
                    or option < 1
                    or option % 1 ~= 0
                then
                    return false
                end
            else
                return false
            end
        end
        return true
    end,
}

local function callback_value(name, callback, ...)
    local ok, value = pcall(callback, ...)
    if not ok then
        error(
            string.format(
                "qfstore: %s callback failed: %s",
                name,
                tostring(value)
            ),
            0
        )
    end
    return value
end

---@param opts? qfstore.Config
function M.setup(opts)
    if opts == nil then
        opts = {}
    end
    if type(opts) ~= "table" then
        error("qfstore: setup options must be a table", 0)
    end

    for name, value in pairs(opts) do
        local validate = validators[name]
        if not validate then
            error("qfstore: unknown setup option '" .. name .. "'", 0)
        end
        if not validate(value) then
            error(
                string.format(
                    "qfstore: invalid value for setup option '%s'",
                    name
                ),
                0
            )
        end
    end

    config = vim.tbl_deep_extend("force", {}, defaults, opts)
end

---@return string
function M.store_dir()
    local cwd = vim.fn.getcwd()
    local dir = config.store_dir
    if type(dir) == "function" then
        dir = callback_value("store_dir", dir, cwd)
    end
    if type(dir) ~= "string" or dir == "" then
        error("qfstore: store_dir must resolve to a non-empty string", 0)
    end
    return vim.fs.abspath(dir)
end

---@return string
function M.default_name()
    local name = callback_value("default_name", config.default_name)
    if type(name) ~= "string" or name == "" then
        error("qfstore: default_name must return a non-empty string", 0)
    end
    return name
end

---@return boolean
function M.open_quickfix()
    return config.open_quickfix
end

---@return { indent: boolean, indent_size: integer, escape_slash: boolean }
function M.json()
    return config.json
end

M.setup()

return M
