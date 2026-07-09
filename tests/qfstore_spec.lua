local qfstore = require "qfstore"

local tests = {}
local case_number = 0

local function it(name, run)
    tests[#tests + 1] = { name = name, run = run }
end

local function fail(message)
    error(message, 2)
end

local function equal(expected, actual, message)
    if expected ~= actual then
        fail(
            message
                or ("expected %s, got %s"):format(
                    vim.inspect(expected),
                    vim.inspect(actual)
                )
        )
    end
end

local function truthy(value, message)
    if not value then
        fail(message or ("expected truthy value, got " .. vim.inspect(value)))
    end
end

local function contains(haystack, needle)
    truthy(
        tostring(haystack):find(needle, 1, true),
        ("expected %s to contain %s"):format(
            vim.inspect(haystack),
            vim.inspect(needle)
        )
    )
end

local function repo_root(path)
    local source = debug.getinfo(1, "S").source:sub(2)
    local root = vim.fn.fnamemodify(source, ":p:h:h")
    if not path then
        return root
    end
    return vim.fs.joinpath(root, path)
end

local function store_path(name)
    return vim.fs.joinpath(vim.fn.getcwd(), ".vim", "lists", name .. ".json")
end

local function read_payload(name)
    local lines = vim.fn.readfile(store_path(name))
    return vim.json.decode(table.concat(lines, "\n"))
end

local function set_qflist(title, items)
    vim.fn.setqflist({}, " ", { title = title, items = items })
end

local function with_project(run)
    case_number = case_number + 1
    local project = repo_root(".test-work/case-" .. case_number)
    local original_cwd = vim.fn.getcwd()
    local original_win = vim.api.nvim_get_current_win()
    local original_notify = vim.notify
    local original_select = vim.ui.select
    local original_date = os.date
    local original_oil = package.loaded.oil
    local original_preload_oil = package.preload.oil

    vim.fn.delete(project, "rf")
    vim.fn.mkdir(project, "p")
    vim.cmd.cd(project)
    vim.fn.setqflist({}, "f")
    pcall(vim.fn.setloclist, 0, {}, "f")
    vim.notify = function() end
    qfstore.setup()

    local ok, err = xpcall(function()
        run(project)
    end, debug.traceback)

    pcall(vim.cmd, "silent! cclose")
    pcall(vim.cmd, "silent! lclose")
    if vim.api.nvim_win_is_valid(original_win) then
        vim.api.nvim_set_current_win(original_win)
    end
    vim.fn.setqflist({}, "f")
    pcall(vim.fn.setloclist, 0, {}, "f")
    vim.notify = original_notify
    vim.ui.select = original_select
    os.date = original_date
    package.loaded.oil = original_oil
    package.preload.oil = original_preload_oil
    qfstore.setup()
    vim.cmd.cd(original_cwd)
    vim.fn.delete(project, "rf")

    if not ok then
        error(err, 0)
    end
end

it("registers every public command", function()
    for _, command in ipairs {
        "QfStore",
        "QfLoad",
        "QfRemove",
        "QfBrowseStore",
        "LlStore",
        "LlLoad",
        "LlRemove",
        "LlBrowseStore",
    } do
        equal(2, vim.fn.exists(":" .. command), command .. " is missing")
    end
end)

it("configures relative, absolute, and callback store directories", function()
    with_project(function(project)
        local function store_in(dir, name)
            set_qflist(name, {
                { filename = name .. ".lua", lnum = 1, text = name },
            })
            truthy(qfstore.store { name = name })
            truthy(
                vim.fn.filereadable(vim.fs.joinpath(dir, name .. ".json")) == 1
            )
        end

        local relative_dir = vim.fs.joinpath(project, ".qfstore")
        qfstore.setup { store_dir = ".qfstore" }
        store_in(relative_dir, "relative")
        equal(relative_dir, qfstore.list()[1].path:match "^(.*)/relative.json$")
        truthy(qfstore.exists "relative")

        vim.fn.setqflist({}, "r", { items = {} })
        truthy(qfstore.load { name = "relative" })
        equal("relative", vim.fn.getqflist()[1].text)
        vim.cmd "silent! cclose"

        local oil_path
        package.loaded.oil = {
            open = function(path)
                oil_path = path
            end,
        }
        qfstore.open_store()
        equal(relative_dir, oil_path)
        truthy(qfstore.remove "relative")
        equal(false, qfstore.exists "relative")

        local absolute_dir = vim.fs.joinpath(project, "absolute-store")
        qfstore.setup { store_dir = absolute_dir }
        store_in(absolute_dir, "absolute")

        local callback_cwd
        local callback_dir = vim.fs.joinpath(project, "callback-store")
        qfstore.setup {
            store_dir = function(cwd)
                callback_cwd = cwd
                return "callback-store"
            end,
        }
        store_in(callback_dir, "callback")
        equal(project, callback_cwd)
    end)
end)

it("uses configured default names in the Lua API and commands", function()
    with_project(function()
        set_qflist("lua", {
            { filename = "lua.lua", lnum = 1, text = "lua" },
        })
        qfstore.setup {
            default_name = function()
                return "lua-default"
            end,
        }
        truthy(qfstore.store())
        truthy(qfstore.exists "lua-default")

        set_qflist("command", {
            { filename = "command.lua", lnum = 1, text = "command" },
        })
        qfstore.setup {
            default_name = function()
                return "command-default"
            end,
        }
        vim.cmd "QfStore"
        truthy(qfstore.exists "command-default")
    end)
end)

it("can leave the quickfix window closed after loading", function()
    with_project(function()
        set_qflist("closed", {
            { filename = "closed.lua", lnum = 1, text = "closed" },
        })
        truthy(qfstore.store { name = "closed" })
        vim.fn.setqflist({}, "r", { items = {} })

        qfstore.setup { open_quickfix = false }
        truthy(qfstore.load { name = "closed" })
        equal(0, vim.fn.getqflist({ winid = 1 }).winid)
        equal("closed", vim.fn.getqflist()[1].text)
    end)
end)

it("resets omitted setup options to their defaults", function()
    with_project(function(project)
        qfstore.setup { store_dir = ".custom-store", open_quickfix = false }
        qfstore.setup()
        set_qflist("reset", {
            { filename = "reset.lua", lnum = 1, text = "reset" },
        })
        truthy(qfstore.store { name = "reset" })
        truthy(
            vim.fn.filereadable(
                vim.fs.joinpath(project, ".vim", "lists", "reset.json")
            ) == 1
        )

        vim.fn.setqflist({}, "r", { items = {} })
        truthy(qfstore.load { name = "reset" })
        truthy(vim.fn.getqflist({ winid = 1 }).winid ~= 0)
    end)
end)

it("rejects invalid setup options and callback results", function()
    with_project(function()
        local function rejects(opts, message)
            local ok, err = pcall(qfstore.setup, opts)
            equal(false, ok)
            contains(err, message)
        end

        rejects("invalid", "setup options must be a table")
        rejects(false, "setup options must be a table")
        rejects({ unknown = true }, "unknown setup option 'unknown'")
        rejects({ store_dir = 1 }, "invalid value for setup option 'store_dir'")
        rejects(
            { default_name = "name" },
            "invalid value for setup option 'default_name'"
        )
        rejects(
            { open_quickfix = "yes" },
            "invalid value for setup option 'open_quickfix'"
        )

        qfstore.setup {
            store_dir = function()
                return nil
            end,
        }
        local ok, err = pcall(qfstore.list)
        equal(false, ok)
        contains(err, "store_dir must resolve to a non-empty string")

        qfstore.setup {
            default_name = function()
                return ""
            end,
        }
        set_qflist("invalid name", {
            { filename = "invalid.lua", lnum = 1, text = "invalid" },
        })
        ok, err = pcall(qfstore.store)
        equal(false, ok)
        contains(err, "default_name must return a non-empty string")

        qfstore.setup {
            store_dir = function()
                error("callback problem", 0)
            end,
        }
        ok, err = pcall(qfstore.list)
        equal(false, ok)
        contains(err, "store_dir callback failed: callback problem")
    end)
end)

it("stores and restores a quickfix list with stable filenames", function()
    with_project(function(project)
        local filename = vim.fs.joinpath(project, "example.lua")
        vim.fn.writefile({ "one", "two" }, filename)
        local bufnr = vim.fn.bufadd(filename)
        vim.fn.bufload(bufnr)
        set_qflist("compiler", {
            {
                bufnr = bufnr,
                lnum = 2,
                col = 3,
                end_lnum = 2,
                end_col = 6,
                text = "boom",
                type = "E",
                valid = 1,
            },
        })

        local ok, count = qfstore.store { name = "build" }
        truthy(ok)
        equal(1, count)

        local payload = read_payload "build"
        equal("compiler", payload.title)
        equal(false, payload.loclist)
        equal(project, payload.cwd)
        equal(filename, payload.items[1].filename)
        equal(6, payload.items[1].end_col)

        local last_before = vim.fn.getqflist({ nr = "$" }).nr
        vim.fn.setqflist({}, "r", { items = {} })
        local load_ok, load_err = qfstore.load { name = "build" }
        truthy(load_ok, load_err)
        equal(last_before + 1, vim.fn.getqflist({ nr = "$" }).nr)
        equal("compiler", vim.fn.getqflist({ title = 1 }).title)
        local items = vim.fn.getqflist()
        equal("boom", items[1].text)
        equal(2, items[1].lnum)
        truthy(
            vim.fn.getwininfo(vim.fn.getqflist({ winid = 1 }).winid)[1].quickfix
        )
    end)
end)

it("stores and restores a location list", function()
    with_project(function(project)
        local winid = vim.api.nvim_get_current_win()
        local filename = vim.fs.joinpath(project, "location.lua")
        vim.fn.writefile({ "location" }, filename)
        vim.fn.setloclist(winid, {}, " ", {
            title = "locations",
            items = {
                {
                    filename = filename,
                    lnum = 1,
                    col = 1,
                    text = "location item",
                    valid = 1,
                },
            },
        })

        local ok, count = qfstore.store {
            name = "locations",
            loclist = true,
            winid = winid,
        }
        truthy(ok)
        equal(1, count)
        vim.fn.setloclist(winid, {}, "r", { items = {} })

        local load_ok, load_err = qfstore.load {
            name = "locations",
            winid = winid,
        }
        truthy(load_ok, load_err)
        equal("locations", vim.fn.getloclist(winid, { title = 1 }).title)
        equal("location item", vim.fn.getloclist(winid)[1].text)
        equal(0, vim.fn.getqflist({ winid = 1 }).winid)
    end)
end)

it("uses the timestamp default name", function()
    with_project(function()
        set_qflist("default", {
            { filename = "default.lua", lnum = 1, text = "default" },
        })
        os.date = function(format)
            if format == "%Y%m%d-%H%M%S" then
                return "20260709-123456"
            end
            return "2026-07-09 12:34:56"
        end

        local ok = qfstore.store()
        truthy(ok)
        truthy(qfstore.exists "20260709-123456")
        equal("2026-07-09 12:34:56", read_payload("20260709-123456").saved_at)
    end)
end)

it("lists entries newest first with metadata", function()
    with_project(function()
        set_qflist("older title", {
            { filename = "one.lua", lnum = 1, text = "one" },
        })
        truthy(qfstore.store { name = "older" })
        set_qflist("newer title", {
            { filename = "two.lua", lnum = 2, text = "two" },
            { filename = "three.lua", lnum = 3, text = "three" },
        })
        truthy(qfstore.store { name = "newer" })
        truthy(vim.uv.fs_utime(store_path "older", 100, 100))
        truthy(vim.uv.fs_utime(store_path "newer", 200, 200))

        local entries = qfstore.list()
        equal(2, #entries)
        equal("newer", entries[1].name)
        equal("newer title", entries[1].title)
        equal(2, entries[1].item_count)
        equal(false, entries[1].loclist)
        equal("older", entries[2].name)
    end)
end)

it("loads the existing dotfiles JSON format without migration", function()
    with_project(function()
        local dir = vim.fs.dirname(store_path "existing")
        vim.fn.mkdir(dir, "p")
        vim.fn.writefile(
            vim.fn.readfile(repo_root "tests/fixtures/existing-format.json"),
            store_path "existing"
        )

        local ok, err = qfstore.load { name = "existing" }
        truthy(ok, err)
        equal("legacy compiler", vim.fn.getqflist({ title = 1 }).title)
        local items = vim.fn.getqflist()
        equal("legacy error", items[1].text)
        equal(12, items[1].lnum)
    end)
end)

it("reports empty, missing, and malformed entries", function()
    with_project(function()
        local ok, err = qfstore.store { name = "empty" }
        equal(false, ok)
        equal("list is empty", err)

        ok, err = qfstore.load { name = "" }
        equal(false, ok)
        equal("name is required", err)

        ok, err = qfstore.load { name = "missing" }
        equal(false, ok)
        equal("no stored entry named 'missing'", err)

        local dir = vim.fs.dirname(store_path "bad")
        vim.fn.mkdir(dir, "p")
        vim.fn.writefile({ "{bad json" }, store_path "bad")
        ok, err = qfstore.load { name = "bad" }
        equal(false, ok)
        contains(err, "failed to parse")

        local entries = qfstore.list()
        equal(1, #entries)
        equal("bad", entries[1].name)
        equal(0, entries[1].item_count)
    end)
end)

it("removes stored entries and rejects missing entries", function()
    with_project(function()
        set_qflist("remove", {
            { filename = "remove.lua", lnum = 1, text = "remove" },
        })
        truthy(qfstore.store { name = "remove" })
        truthy(qfstore.exists "remove")
        truthy(qfstore.remove "remove")
        equal(false, qfstore.exists "remove")
        local ok, err = qfstore.remove "remove"
        equal(false, ok)
        equal("no stored entry named 'remove'", err)
    end)
end)

it("notifies and returns nil when the picker is empty", function()
    with_project(function()
        local notification
        local level
        local choice = "unset"
        vim.notify = function(message, message_level)
            notification = message
            level = message_level
        end

        qfstore.pick_entry(function(entry)
            choice = entry
        end)

        equal(nil, choice)
        equal("qfstore: no stored entries", notification)
        equal(vim.log.levels.WARN, level)
    end)
end)

it("uses oil when available and falls back to edit", function()
    with_project(function()
        local oil_path
        package.loaded.oil = {
            open = function(path)
                oil_path = path
            end,
        }
        qfstore.open_store()
        equal(vim.fs.joinpath(vim.fn.getcwd(), ".vim", "lists"), oil_path)

        package.loaded.oil = nil
        package.preload.oil = function()
            error "oil unavailable"
        end
        local original_cmd = vim.cmd
        local command
        vim.cmd = function(value)
            command = value
        end
        qfstore.open_store()
        vim.cmd = original_cmd
        contains(command, "edit ")
        contains(command, ".vim/lists")
    end)
end)

it("preserves command overwrite and cancellation behavior", function()
    with_project(function()
        local notifications = {}
        vim.notify = function(message)
            notifications[#notifications + 1] = message
        end
        set_qflist("old", {
            { filename = "old.lua", lnum = 1, text = "old" },
        })
        vim.cmd "QfStore collision"

        set_qflist("new", {
            { filename = "new.lua", lnum = 2, text = "new" },
        })
        vim.ui.select = function(items, _, on_choice)
            on_choice(items[2])
        end
        vim.cmd "QfStore collision"
        equal("old", read_payload("collision").title)
        equal("qfstore: store cancelled", notifications[#notifications])

        vim.ui.select = function(items, _, on_choice)
            on_choice(items[1])
        end
        vim.cmd "QfStore collision"
        equal("new", read_payload("collision").title)
    end)
end)

it("loads and removes entries through command pickers", function()
    with_project(function()
        set_qflist("picked", {
            { filename = "picked.lua", lnum = 7, text = "picked item" },
        })
        truthy(qfstore.store { name = "picked" })
        vim.fn.setqflist({}, "r", { items = {} })

        local prompts = {}
        vim.ui.select = function(items, opts, on_choice)
            prompts[#prompts + 1] = opts.prompt
            on_choice(items[1])
        end
        vim.cmd "QfLoad"
        equal("picked item", vim.fn.getqflist()[1].text)
        equal("Load quickfix entry:", prompts[1])
        vim.cmd "silent! cclose"

        vim.cmd "QfRemove"
        equal("Remove quickfix entry:", prompts[2])
        equal(false, qfstore.exists "picked")
    end)
end)

return tests
