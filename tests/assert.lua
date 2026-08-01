--[[
    Assertion Library for UI-Engine Tests

    Provides assertion functions for unit testing.
    Usage:
        local assert = require("tests.assert")
        assert.assert_equal(actual, expected, "message")
        assert.assert_true(value, "message")
        assert.assert_false(value, "message")
        assert.assert_error(fn, "message")
        assert.assert_not_nil(value, "message")
]]

local M = {}

-- Internal: format error message
local function formatMessage(message, details)
    if details then
        return message .. " (" .. tostring(details) .. ")"
    end
    return message
end

-- Internal: format values for comparison display
local function formatValue(val)
    if val == nil then
        return "nil"
    elseif type(val) == "string" then
        return '"' .. val .. '"'
    elseif type(val) == "table" then
        -- Simple table representation
        local parts = {}
        for k, v in pairs(val) do
            table.insert(parts, tostring(k) .. "=" .. tostring(v))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return tostring(val)
    end
end

--- Assert that two values are equal
-- @param actual The actual value
-- @param expected The expected value
-- @param message Optional error message
function M.assert_equal(actual, expected, message)
    if actual ~= expected then
        error(formatMessage(
            (message or "assert_equal failed") ..
            "\n  Expected: " .. formatValue(expected) ..
            "\n  Actual:   " .. formatValue(actual)
        ))
    end
end

--- Assert that a value is true
-- @param value The value to check
-- @param message Optional error message
function M.assert_true(value, message)
    if not value then
        error(formatMessage(
            (message or "assert_true failed") ..
            "\n  Expected: true" ..
            "\n  Actual:   " .. formatValue(value)
        ))
    end
end

--- Assert that a value is false
-- @param value The value to check
-- @param message Optional error message
function M.assert_false(value, message)
    if value then
        error(formatMessage(
            (message or "assert_false failed") ..
            "\n  Expected: false" ..
            "\n  Actual:   " .. formatValue(value)
        ))
    end
end

--- Assert that a value is not nil
-- @param value The value to check
-- @param message Optional error message
function M.assert_not_nil(value, message)
    if value == nil then
        error(formatMessage(
            (message or "assert_not_nil failed") ..
            "\n  Expected: not nil" ..
            "\n  Actual:   nil"
        ))
    end
end

--- Assert that a value is nil
-- @param value The value to check
-- @param message Optional error message
function M.assert_nil(value, message)
    if value ~= nil then
        error(formatMessage(
            (message or "assert_nil failed") ..
            "\n  Expected: nil" ..
            "\n  Actual:   " .. formatValue(value)
        ))
    end
end

--- Assert that a function throws an error
-- @param fn The function that should error
-- @param message Optional error message
function M.assert_error(fn, message)
    local ok, err = pcall(fn)
    if ok then
        error(formatMessage(
            (message or "assert_error failed") ..
            "\n  Expected: function to throw an error" ..
            "\n  Actual:   function completed without error"
        ))
    end
end

--- Assert that a function does NOT throw an error
-- @param fn The function that should not error
-- @param message Optional error message
function M.assert_no_error(fn, message)
    local ok, err = pcall(fn)
    if not ok then
        error(formatMessage(
            (message or "assert_no_error failed") ..
            "\n  Expected: function to complete without error" ..
            "\n  Actual:   " .. tostring(err)
        ))
    end
end

--- Assert that actual contains expected (for strings)
-- @param actual The actual string
-- @param expected The expected substring
-- @param message Optional error message
function M.assert_contains(actual, expected, message)
    if type(actual) ~= "string" or type(expected) ~= "string" then
        error(formatMessage(
            (message or "assert_contains requires string arguments") ..
            "\n  Actual type: " .. type(actual) ..
            "\n  Expected type: string"
        ))
    end
    if not string.find(actual, expected, 1, true) then
        error(formatMessage(
            (message or "assert_contains failed") ..
            "\n  Expected to contain: " .. formatValue(expected) ..
            "\n  Actual: " .. formatValue(actual)
        ))
    end
end

--- Assert that a table has a specific key
-- @param tbl The table to check
-- @param key The expected key
-- @param message Optional error message
function M.assert_has_key(tbl, key, message)
    if type(tbl) ~= "table" then
        error(formatMessage(
            (message or "assert_has_key requires a table") ..
            "\n  Actual type: " .. type(tbl)
        ))
    end
    if tbl[key] == nil then
        error(formatMessage(
            (message or "assert_has_key failed") ..
            "\n  Expected key: " .. formatValue(key) ..
            "\n  Table keys: " .. formatValue(tbl)
        ))
    end
end

--- Assert that two tables are equal (shallow comparison)
-- @param actual The actual table
-- @param expected The expected table
-- @param message Optional error message
function M.assert_table_equal(actual, expected, message)
    if type(actual) ~= "table" or type(expected) ~= "table" then
        M.assert_equal(actual, expected, message)
        return
    end

    -- Check same keys
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error(formatMessage(
                (message or "assert_table_equal failed") ..
                "\n  Key: " .. formatValue(k) ..
                "\n  Expected: " .. formatValue(v) ..
                "\n  Actual:   " .. formatValue(actual[k])
            ))
        end
    end

    -- Check for extra keys
    for k, v in pairs(actual) do
        if expected[k] == nil then
            error(formatMessage(
                (message or "assert_table_equal failed") ..
                "\n  Unexpected key: " .. formatValue(k) ..
                "\n  Actual value: " .. formatValue(v)
            ))
        end
    end
end

--- Assert that a value is of a specific type
-- @param value The value to check
-- @param expectedType The expected type string
-- @param message Optional error message
function M.assert_type(value, expectedType, message)
    if type(value) ~= expectedType then
        error(formatMessage(
            (message or "assert_type failed") ..
            "\n  Expected type: " .. expectedType ..
            "\n  Actual type: " .. type(value)
        ))
    end
end

return M