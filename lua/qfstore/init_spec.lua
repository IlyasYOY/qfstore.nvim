local qfstore = require "qfstore"

describe("qfstore storage", function()
    local project
    local original_cwd

    before_each(function()
        original_cwd = vim.fn.getcwd()
        project = vim.fs.joinpath(original_cwd, ".test-work", "storage-spec")
        vim.fn.delete(project, "rf")
        vim.fn.mkdir(project, "p")
        vim.cmd.cd(project)
        vim.fn.setqflist({}, "f")
        qfstore.setup { open_quickfix = false }
    end)

    after_each(function()
        pcall(vim.cmd, "silent! cclose")
        vim.fn.setqflist({}, "f")
        qfstore.setup()
        vim.cmd.cd(original_cwd)
        vim.fn.delete(project, "rf")
    end)

    it(
        "stores stable filenames and loads a new quickfix stack entry",
        function()
            local filename = vim.fs.joinpath(project, "src", "main.lua")
            vim.fn.setqflist({}, " ", {
                title = "before",
                items = {
                    {
                        filename = filename,
                        lnum = 3,
                        col = 2,
                        text = "failure",
                    },
                },
            })
            local previous_id = vim.fn.getqflist({ id = 0 }).id

            local ok, count = qfstore.store { name = "build" }
            assert.is_true(ok)
            assert.equal(1, count)

            local path = vim.fs.joinpath(project, ".vim", "lists", "build.json")
            local payload =
                vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
            assert.equal(filename, payload.items[1].filename)
            assert.is_nil(payload.items[1].bufnr)

            ok = qfstore.load { name = "build" }
            assert.is_true(ok)
            local restored = vim.fn.getqflist { id = 0, title = 1, items = 1 }
            assert.not_equal(previous_id, restored.id)
            assert.equal("before", restored.title)
            assert.equal(
                filename,
                vim.api.nvim_buf_get_name(restored.items[1].bufnr)
            )
        end
    )

    it("loads the existing persisted format without migration", function()
        local store = vim.fs.joinpath(project, ".vim", "lists")
        vim.fn.mkdir(store, "p")
        vim.fn.writefile(
            vim.fn.readfile(
                vim.fs.joinpath(
                    original_cwd,
                    "tests",
                    "fixtures",
                    "existing-format.json"
                )
            ),
            vim.fs.joinpath(store, "existing-format.json")
        )

        local ok, err = qfstore.load { name = "existing-format" }
        assert.is_true(ok, err)
        local restored = vim.fn.getqflist { title = 1, items = 1 }
        assert.equal("legacy compiler", restored.title)
        assert.equal(1, #restored.items)
        assert.equal(
            "/legacy/project/example.lua",
            vim.api.nvim_buf_get_name(restored.items[1].bufnr)
        )
    end)
end)
