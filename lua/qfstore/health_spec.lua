local config = require "qfstore.config"
local health = require "qfstore.health"

local function capture_health()
    local reports = {}
    local captured = {}
    for _, level in ipairs { "start", "ok", "warn", "error", "info" } do
        captured[level] = function(message, advice)
            reports[#reports + 1] = {
                level = level,
                message = tostring(message),
                advice = advice,
            }
        end
    end
    return captured, reports
end

local function has_report(reports, level, text)
    for _, report in ipairs(reports) do
        if report.level == level and report.message:find(text, 1, true) then
            return true
        end
    end
    return false
end

describe("qfstore.health", function()
    local original_health

    before_each(function()
        original_health = vim.health
        config.setup {
            store_dir = vim.fs.joinpath(
                vim.fn.getcwd(),
                ".test-work",
                "health-store"
            ),
        }
    end)

    after_each(function()
        vim.health = original_health
        config.setup()
    end)

    it("reports commands, storage, and optional Oil support", function()
        local captured, reports = capture_health()
        vim.health = captured
        health.check()

        assert.is_true(has_report(reports, "start", "qfstore.nvim"))
        assert.is_true(has_report(reports, "ok", ":QfStore is registered"))
        assert.is_true(has_report(reports, "info", "created on first write"))
        assert.is_true(
            has_report(reports, "info", "browse commands will use :edit")
                or has_report(reports, "ok", "oil.nvim is available")
        )
    end)
end)
