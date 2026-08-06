--[[
    Stats — Log-Engine

    Aggregate statistics across all logger instances.
    Provides per-mod and cross-mod statistics.
]]

---@class Stats
--- Aggregate statistics across all Log-Engine logger instances.
local M = {}

-- --- SafeRequire (inline, no external deps) ---
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then return mod end
    return nil
end

-- Config values inlined with fallbacks
local Config = SafeRequire("config") or {}

-- --- Logger (set by init.lua after bootstrap) ---

---@type Logger? Log-Engine logger instance (set via M.setLogger)
local log = nil

-- --- Internal State ---

local initialized = false
local loggers = {}  -- Reference to the loggers table from init.lua

-- --- Public API ---

--- Initialize stats module (idempotent)
---@param loggersTable table Reference to the loggers table from init.lua
function M.init(loggersTable)
    if initialized then
        return
    end
    initialized = true
    loggers = loggersTable or {}
    if log then log.debug("Stats initialized") end
end

--- Get stats for a specific mod
---@param modName string Mod identifier
---@return table|nil { totalLogged, byLevel = {debug=N, info=N, warn=N, error=N, print=N} }
function M.getModStats(modName)
    local logger = loggers[modName]
    if not logger then
        return nil
    end

    if logger.getStats then
        return logger.getStats()
    end

    return nil
end

--- Get aggregate stats across all loggers
---@return table { totalMods, totalLogged, byLevel = {debug=N, info=N, warn=N, error=N, print=N} }
function M.getAggregateStats()
    local stats = {
        totalMods = 0,
        totalLogged = 0,
        byLevel = { debug = 0, info = 0, warn = 0, error = 0, print = 0 },
    }

    if log then log.debug("getAggregateStats: collecting from loggers") end

    for _, logger in pairs(loggers) do
        if logger.getStats then
            local modStats = logger.getStats()
            stats.totalMods = stats.totalMods + 1
            stats.totalLogged = stats.totalLogged + modStats.totalLogged
            for level, count in pairs(modStats.byLevel) do
                stats.byLevel[level] = (stats.byLevel[level] or 0) + count
            end
        end
    end

    return stats
end

--- Get recent errors across all loggers
---@param count number Max errors (default: 20)
---@return table Array of error entries (newest first)
function M.getRecentErrors(count)
    count = count or 20
    local allErrors = {}

    for _, logger in pairs(loggers) do
        if logger.getRecentErrors then
            local errors = logger.getRecentErrors(count)
            for _, entry in ipairs(errors) do
                table.insert(allErrors, entry)
            end
        end
    end

    -- Sort by timestamp (newest first) — simple bubble sort for small arrays
    table.sort(allErrors, function(a, b)
        return (a.timestamp or "") > (b.timestamp or "")
    end)

    -- Trim to count
    while #allErrors > count do
        table.remove(allErrors)
    end

    return allErrors
end

--- Get mod summary for display
---@return table Array of { modName, totalLogged, errorCount, lastLog }
function M.getModSummary()
    local summary = {}

    for modName, logger in pairs(loggers) do
        if logger.getStats then
            local stats = logger.getStats()
            local errorCount = stats.byLevel.error or 0
            local totalLogged = stats.totalLogged or 0

            -- Get last log entry
            local lastLog = nil
            if logger.getEntries then
                local entries = logger.getEntries(1)
                if #entries > 0 then
                    lastLog = entries[1]
                end
            end

            table.insert(summary, {
                modName = modName,
                totalLogged = totalLogged,
                errorCount = errorCount,
                lastLog = lastLog,
            })
        end
    end

    -- Sort alphabetically by mod name
    table.sort(summary, function(a, b)
        return a.modName < b.modName
    end)

    return summary
end

--- Set the logger instance for Stats internal logging.
---@param logger Logger Logger instance from Log-Engine
function M.setLogger(logger)
    log = logger
end

return M