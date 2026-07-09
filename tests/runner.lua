local M = {}

local function default_files()
    local files =
        vim.fn.globpath(vim.fn.getcwd(), "tests/*_spec.lua", true, true)
    table.sort(files)
    return files
end

local function load_tests(files)
    local tests = {}
    local failures = {}

    for _, file in ipairs(files) do
        local ok, suite = xpcall(function()
            return dofile(file)
        end, debug.traceback)

        if not ok then
            failures[#failures + 1] = {
                name = "load " .. file,
                err = suite,
            }
        elseif type(suite) ~= "table" then
            failures[#failures + 1] = {
                name = "load " .. file,
                err = "spec must return a table of test cases",
            }
        else
            for _, test in ipairs(suite) do
                tests[#tests + 1] = test
            end
        end
    end

    return tests, failures
end

function M.run(opts)
    opts = opts or {}
    local tests, failures = load_tests(opts.files or default_files())

    for _, failure in ipairs(failures) do
        print("not ok - " .. failure.name)
        print(failure.err)
    end

    for _, test in ipairs(tests) do
        local ok, err = xpcall(test.run, debug.traceback)
        if ok then
            if opts.verbose then
                print("ok - " .. test.name)
            end
        else
            failures[#failures + 1] = {
                name = test.name,
                err = err,
            }
            print("not ok - " .. test.name)
            print(err)
        end
    end

    print(("%d test(s) run"):format(#tests))
    if #failures > 0 then
        print(("%d test(s) failed"):format(#failures))
        vim.cmd "cquit 1"
    end
end

return M
