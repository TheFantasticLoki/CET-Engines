-- Test Results — Config Engine
-- Stores test results per mod with optional persistence.
-- Results are in-memory by default; lightweight summary can be persisted.

---@class TestResults
local M = {}

-- In-memory results: { [modId] = { mode, passed, failed, warnings, error, details, timestamp } }
local results = {}

-- Result history (ring buffer of 5 per mod)
---@type table<string, table[]>
local history = {}  -- { [modId] = { result1, result2, ... } }
local MAX_HISTORY = 5

--- Store test results for a mod.
---@param modId string The mod identifier
---@param mode string The test mode ("startup", "full", "debug")
---@param result table { passed, failed, warnings, error, details }
---@return nil
function M.set(modId, mode, result)
    if not modId or not result then return end

    local entry = {
        mode = mode or "unknown",
        passed = result.passed or 0,
        failed = result.failed or 0,
        warnings = result.warnings or 0,
        error = result.error,
        details = result.details,
        timestamp = os.time(),
        status = result.error and "error"
            or (result.failed > 0 and "fail" or "pass"),
    }

    results[modId] = entry

    -- Append to history ring buffer
    if not history[modId] then history[modId] = {} end
    table.insert(history[modId], 1, entry)
    if #history[modId] > MAX_HISTORY then
        table.remove(history[modId])
    end
end

--- Get the latest test results for a mod.
---@param modId string The mod identifier
---@return table|nil Result entry or nil if no tests have run
function M.get(modId)
    return results[modId]
end

--- Get test history for a mod.
---@param modId string The mod identifier
---@return table Array of result entries (most recent first)
function M.getHistory(modId)
    return history[modId] or {}
end

--- Get aggregate stats across all mods.
---@return table { total: number, passing: number, failing: number, errors: number, noTests: number }
function M.getAggregateStats()
    local stats = { total = 0, passing = 0, failing = 0, errors = 0, noTests = 0 }
    for _, r in pairs(results) do
        stats.total = stats.total + 1
        if r.status == "pass" then
            stats.passing = stats.passing + 1
        elseif r.status == "fail" then
            stats.failing = stats.failing + 1
        elseif r.status == "error" then
            stats.errors = stats.errors + 1
        end
    end
    return stats
end

--- Get the status icon for a mod's tests.
---@param modId string The mod identifier
---@return string icon, string color ("pass", "fail", "error", "none")
function M.getStatusIcon(modId)
    local r = results[modId]
    if not r then return "○", "none" end
    if r.status == "pass" then return "✓", "pass" end
    if r.status == "fail" then return "⚠", "fail" end
    if r.status == "error" then return "✗", "error" end
    return "○", "none"
end

--- Clear results for a mod.
---@param modId string The mod identifier
---@return nil
function M.clear(modId)
    results[modId] = nil
    history[modId] = nil
end

--- Clear all results.
---@return nil
function M.clearAll()
    results = {}
    history = {}
end

return M
