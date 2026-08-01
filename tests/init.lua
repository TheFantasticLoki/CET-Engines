--[[
    Test Runner for UI-Engine Tests

    Discovers and runs test files from tests/unit/.
    Reports pass/fail counts and errors.

    Usage:
        lua tests/init.lua
        ./scripts/test.sh
]]

-- Set up package path for requires
local scriptDir = arg[0]:match("(.*/)") or "./"
package.path = scriptDir .. "?.lua;" .. scriptDir .. "?/init.lua;" .. package.path

local assert_lib = require("tests.assert")

-- Test state
local totalTests = 0
local passedTests = 0
local failedTests = 0
local errors = {}

-- Colors for output (ANSI)
local RED = "\27[0;31m"
local GREEN = "\27[0;32m"
local YELLOW = "\27[1;33m"
local CYAN = "\27[0;36m"
local NC = "\27[0m" -- No Color

--- Run a single test function
-- @param moduleName Name of the module being tested
-- @param testName Name of the test
-- @param testFn The test function
local function runTest(moduleName, testName, testFn)
    totalTests = totalTests + 1
    local fullName = moduleName .. "." .. testName

    local ok, err = pcall(testFn)
    if ok then
        passedTests = passedTests + 1
        io.write("  " .. GREEN .. "PASS" .. NC .. " " .. fullName .. "\n")
    else
        failedTests = failedTests + 1
        table.insert(errors, { name = fullName, error = err })
        io.write("  " .. RED .. "FAIL" .. NC .. " " .. fullName .. "\n")
        io.write("    " .. RED .. tostring(err) .. NC .. "\n")
    end
end

--- Run all tests from a test module
-- @param modulePath Path to the test module
-- @param moduleName Display name for the module
local function runModule(modulePath, moduleName)
    io.write("\n" .. CYAN .. "--- " .. moduleName .. " ---" .. NC .. "\n")

    local ok, testModule = pcall(require, modulePath)
    if not ok then
        io.write("  " .. YELLOW .. "SKIP" .. NC .. " " .. moduleName .. " (failed to load: " .. tostring(testModule) .. ")\n")
        return
    end

    -- Run all functions named test* in the module
    local testCount = 0
    for testName, testFn in pairs(testModule) do
        if type(testFn) == "function" and testName:match("^test") then
            runTest(moduleName, testName, testFn)
            testCount = testCount + 1
        end
    end

    if testCount == 0 then
        io.write("  " .. YELLOW .. "WARN" .. NC .. " No test functions found in " .. moduleName .. "\n")
    end
end

--- Discover test files in tests/unit/
local function discoverTests()
    local testFiles = {}
    local unitDir = scriptDir .. "unit"

    -- Try to list unit directory
    local ok, files = pcall(function()
        local result = {}
        -- Simple directory listing using ls
        local handle = io.popen('ls "' .. unitDir .. '"/*.lua 2>/dev/null')
        if handle then
            for line in handle:lines() do
                -- Extract filename without path and extension
                local filename = line:match("([^/]+)%.lua$")
                if filename then
                    table.insert(result, filename)
                end
            end
            handle:close()
        end
        return result
    end)

    if ok and files then
        for _, filename in ipairs(files) do
            table.insert(testFiles, {
                path = "tests.unit." .. filename,
                name = filename,
            })
        end
    end

    -- Sort for consistent order
    table.sort(testFiles, function(a, b) return a.name < b.name end)

    return testFiles
end

--- Main test execution
local function main()
    io.write(CYAN .. "=== UI-Engine Test Suite ===" .. NC .. "\n")

    -- Load mocks
    io.write("\n" .. CYAN .. "--- Loading Mocks ---" .. NC .. "\n")

    local mockFiles = {
        { path = "tests.mocks.cet_mock", name = "CET Mock" },
        { path = "tests.mocks.imgui_mock", name = "ImGui Mock" },
        { path = "tests.mocks.gameui_mock", name = "GameUI Mock" },
    }

    for _, mock in ipairs(mockFiles) do
        local ok, err = pcall(require, mock.path)
        if ok then
            io.write("  " .. GREEN .. "OK" .. NC .. " " .. mock.name .. "\n")
        else
            io.write("  " .. YELLOW .. "WARN" .. NC .. " " .. mock.name .. " (not found: " .. tostring(err) .. ")\n")
        end
    end

    -- Discover and run tests
    local testFiles = discoverTests()

    if #testFiles == 0 then
        io.write("\n" .. YELLOW .. "No test files found in tests/unit/" .. NC .. "\n")
        io.write("Create test files following the pattern: tests/unit/<module>_test.lua\n")
    else
        for _, testFile in ipairs(testFiles) do
            runModule(testFile.path, testFile.name)
        end
    end

    -- Summary
    io.write("\n" .. CYAN .. "=== Test Summary ===" .. NC .. "\n")
    io.write("  Total:  " .. totalTests .. "\n")
    io.write("  Passed: " .. GREEN .. passedTests .. NC .. "\n")
    io.write("  Failed: " .. RED .. failedTests .. NC .. "\n")

    if failedTests > 0 then
        io.write("\n" .. RED .. "Failed tests:" .. NC .. "\n")
        for _, err in ipairs(errors) do
            io.write("  " .. RED .. "FAIL" .. NC .. " " .. err.name .. "\n")
            io.write("    " .. tostring(err.error) .. "\n")
        end
        io.write("\n" .. RED .. "Tests failed with " .. failedTests .. " failure(s)." .. NC .. "\n")
        os.exit(1)
    else
        io.write("\n" .. GREEN .. "All tests passed!" .. NC .. "\n")
        os.exit(0)
    end
end

-- Run the test suite
main()