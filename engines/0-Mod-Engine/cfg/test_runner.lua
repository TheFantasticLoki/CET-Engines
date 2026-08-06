-- Test Runner — Config Engine
-- Runs mod-registered tests with isolation and error handling.
--
-- Test granularity:
--   startup  — auto-run on first draw frame (quick, non-destructive)
--   full     — on-demand (may be slow or have side effects)
--   debug    — on-demand (diagnostic, potentially destructive)
--
-- All test functions are pcall-wrapped. Errors never propagate across mods.

---@class TestRunner
local M = {}

-- Dependencies
local Core = nil
local TestResults = nil
local _log = nil

-- State
local _startupRun = false
local _running = false

--- Initialize the test runner.
---@param deps table { core: CfgCore, testResults: TestResults, logger: Logger|nil }
---@return nil
function M.init(deps)
    Core = deps.core
    TestResults = deps.testResults
    _log = deps.logger
end

--- Run tests for a single mod.
---@param modId string The mod identifier
---@param mode string Test mode ("startup", "full", "debug")
---@return table Result { status, passed, failed, warnings, error, timestamp }
function M.runModTests(modId, mode)
    if not Core or not TestResults then
        return { status = "error", passed = 0, failed = 1, error = "Test runner not initialized" }
    end

    local mod = Core.getMod(modId)
    if not mod or not mod.tests or not mod.tests[mode] then
        return { status = "no_tests", passed = 0, failed = 0 }
    end

    local testFn = mod.tests[mode]
    if type(testFn) ~= "function" then
        return { status = "error", passed = 0, failed = 1, error = "Test function is not a function" }
    end

    -- Time the test
    local startTime = os.clock()

    -- pcall-wrap the entire test function
    local ok, result = pcall(testFn)

    local elapsed = os.clock() - startTime

    -- Timeout warning
    local timeout = (mode == "startup") and 1.0 or 5.0
    if elapsed > timeout then
        if _log then
            _log.warn("TestRunner", string.format(
                "%s.%s took %.1fs (limit: %.1fs)", modId, mode, elapsed, timeout))
        end
    end

    if not ok then
        -- Function threw an error
        local entry = {
            status = "error",
            passed = 0,
            failed = 1,
            error = tostring(result),
            timestamp = os.time(),
        }
        TestResults.set(modId, mode, entry)
        return entry
    end

    -- Validate return shape
    if type(result) ~= "table" then
        local entry = {
            status = "error",
            passed = 0,
            failed = 1,
            error = "Test function returned " .. type(result) .. ", expected table",
            timestamp = os.time(),
        }
        TestResults.set(modId, mode, entry)
        return entry
    end

    -- Normalize result
    local entry = {
        status = (result.failed == nil or result.failed == 0) and "pass" or "fail",
        passed = result.passed or 0,
        failed = result.failed or 0,
        warnings = result.warnings or 0,
        details = result.details,
        timestamp = os.time(),
    }

    TestResults.set(modId, mode, entry)
    return entry
end

--- Run startup tests for all registered mods.
-- Safe to call multiple times — only runs once.
---@return nil
function M.runStartupTests()
    if _startupRun then return end
    _startupRun = true

    if not Core then return end

    local mods = Core.getAllMods()
    for modId, _ in pairs(mods) do
        M.runModTests(modId, "startup")
    end
end

--- Run tests for all mods in a given mode.
---@param mode string Test mode
---@return table { [modId] = result }
function M.runAllTests(mode)
    if _running then return {} end
    _running = true

    local allResults = {}
    if Core then
        local mods = Core.getAllMods()
        for modId, _ in pairs(mods) do
            allResults[modId] = M.runModTests(modId, mode)
        end
    end

    _running = false
    return allResults
end

--- Check if startup tests have been run.
---@return boolean
function M.startupComplete()
    return _startupRun
end

--- Reset startup flag (for testing or re-run).
---@return nil
function M.resetStartup()
    _startupRun = false
end

return M
