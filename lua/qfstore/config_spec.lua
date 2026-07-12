local config = require "qfstore.config"

describe("qfstore.config", function()
    before_each(function()
        config.setup()
    end)

    after_each(function()
        config.setup()
    end)

    it("resets omitted options to defaults", function()
        config.setup {
            store_dir = ".custom",
            open_quickfix = false,
        }
        assert.is_false(config.open_quickfix())
        assert.truthy(config.store_dir():find(".custom", 1, true))

        config.setup()
        assert.is_true(config.open_quickfix())
        assert.truthy(config.store_dir():find(".vim/lists", 1, true))
    end)

    it("validates options and callback results", function()
        assert.has_error(function()
            config.setup { unknown = true }
        end, "unknown setup option")
        assert.has_error(function()
            config.setup { open_quickfix = "yes" }
        end, "invalid value")

        config.setup {
            store_dir = function()
                return ""
            end,
        }
        assert.has_error(config.store_dir, "non-empty string")
    end)
end)
