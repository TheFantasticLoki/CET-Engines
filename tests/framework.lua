--[[
    Test Framework — Lightweight, CET-Compatible
    
    Minimal test framework that works both in-game and out-of-game.
    No external dependencies — pure Lua 5.1.
    
    Usage:
        local framework = require("tests.framework")
        local assert = framework.assert
        
        -- Run a test
        local ok, err = pcall(function()
            assert.equal(actual, expected)
        end)
]]

local M = {}

-- ============================================================================
-- Assert Library
-- ============================================================================

M.assert = {}

--- Format a value for display
local function fmt(val)
    if val == nil then return "nil" end
    if type(val) == "string" then return '"' .. val .. '"' end
    if type(val) == "table" then
        local parts = {}
        for k, v in pairs(val) do
            table.insert(parts, tostring(k) .. "=" .. tostring(v))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(val)
end

--- Assert two values are equal
function M.assert.equal(actual, expected, msg)
    if actual ~= expected then
        error((msg or "assert.equal") ..
            "\n  Expected: " .. fmt(expected) ..
            "\n  Actual:   " .. fmt(actual), 2)
    end
end

--- Assert value is truthy
function M.assert.true_(val, msg)
    if not val then
        error((msg or "assert.true_") ..
            "\n  Expected: truthy" ..
            "\n  Actual:   " .. fmt(val), 2)
    end
end

--- Assert value is falsy
function M.assert.false_(val, msg)
    if val then
        error((msg or "assert.false_") ..
            "\n  Expected: falsy" ..
            "\n  Actual:   " .. fmt(val), 2)
    end
end

--- Assert value is nil
function M.assert.nil_(val, msg)
    if val ~= nil then
        error((msg or "assert.nil_") ..
            "\n  Expected: nil" ..
            "\n  Actual:   " .. fmt(val), 2)
    end
end

--- Assert value is not nil
function M.assert.not_nil(val, msg)
    if val == nil then
        error((msg or "assert.not_nil") ..
            "\n  Expected: not nil" ..
            "\n  Actual:   nil", 2)
    end
end

--- Assert function throws an error
function M.assert.error(fn, msg)
    local ok, err = pcall(fn)
    if ok then
        error((msg or "assert.error") ..
            "\n  Expected: function to throw" ..
            "\n  Actual:   no error", 2)
    end
end

-- ============================================================================
-- Test Runner
-- ============================================================================

--- Run a table of test functions.
--- @param tests table { testName = function(ctx)... end, ... }
--- @param ctx table Context to pass to each test
--- @return table { passed, failed, errors }
function M.runTests(tests, ctx)
    local passed = 0
    local failed = 0
    local errors = {}

    for name, fn in pairs(tests) do
        if type(fn) == "function" then
            local ok, err = pcall(fn, ctx)
            if ok then
                passed = passed + 1
            else
                failed = failed + 1
                table.insert(errors, name .. ": " .. tostring(err))
            end
        end
    end

    return { passed = passed, failed = failed, errors = errors }
end

--- Run a test module (table with .run function).
--- @param testModule table Must have .run(ctx) function
--- @param ctx table Context to pass
--- @return table { passed, failed, errors }
function M.runModule(testModule, ctx)
    if type(testModule.run) ~= "function" then
        return {
            passed = 0,
            failed = 1,
            errors = { "Module has no .run() function" },
        }
    end

    local ok, result = pcall(testModule.run, ctx)
    if not ok then
        return {
            passed = 0,
            failed = 1,
            errors = { "Module .run() failed: " .. tostring(result) },
        }
    end

    return result
end

-- ============================================================================
-- Reporter (Console)
-- ============================================================================

--- Print results to console (ANSI colors).
--- @param moduleName string Name of the test module
--- @param result table { passed, failed, errors }
function M.report(moduleName, result)
    local GREEN = "\27[0;32m"
    local RED = "\27[0;31m"
    local CYAN = "\27[0;36m"
    local NC = "\27[0m"

    io.write("\n" .. CYAN .. "--- " .. moduleName .. " ---" .. NC .. "\n")

    if result.failed == 0 then
        io.write("  " .. GREEN .. "ALL PASSED" .. NC ..
            " (" .. result.passed .. " tests)\n")
    else
        io.write("  " .. GREEN .. result.passed .. " passed" .. NC .. ", " ..
            RED .. result.failed .. " failed" .. NC .. "\n")
        for _, err in ipairs(result.errors) do
            io.write("    " .. RED .. "FAIL" .. NC .. " " .. err .. "\n")
        end
    end
end

return M
