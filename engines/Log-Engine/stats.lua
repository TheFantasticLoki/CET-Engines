--[[
    Stats — Log-Engine

    Aggregate statistics and summaries across all logger instances.
    Provides a global view of logging activity across all mods.
]]

local M = {}

-- --- Internal State ---

local loggers = {}  -- Reference to all logger instances (keyed by modName)
local initialized = false

-- --- Public API ---

--- Initialize the stats module
-- @param loggerTable table Reference to the loggers table { [modName] = loggerInstance }
function M.init(loggerTable)
    loggers = loggerTable or {}
    if initialized then
        return
    end
    initialized = true
end

--- Get statistics for a specific mod
-- @param modName string Mod identifier
-- @return table|nil { totalLogged, byLevel }
function M.getModStats(modName)
    local logger = loggers[modName]
    if not logger or not logger.getStats then
        return nil
    end
    return logger.getStats()
end

--- Get aggregate statistics across all mods
-- @return table { totalMods, totalLogged, byLevel, modList }
function M.getAggregateStats()
    local stats = {
        totalMods = 0,
        totalLogged = 0,
        byLevel = { debug = 0, info = 0, warn = 0, error = 0 },
        modList = {},
    }

    for modName, logger in pairs(loggers) do
        if logger.getStats then
            stats.totalMods = stats.totalMods + 1
            local modStats = logger.getStats()
            stats.totalLogged = stats.totalLogged + modStats.totalLogged
            for level, count in pairs(modStats.byLevel) do
                stats.byLevel[level] = (stats.byLevel[level] or 0) + count
            end
            table.insert(stats.modList, modName)
        end
    end

    table.sort(stats.modList)
    return stats
end

--- Get recent errors across all mods (newest first)
-- @param count number Max errors to return (default: 20)
-- @return table Array of error entries sorted by timestamp descending
function M.getRecentErrors(count)
    count = count or 20
    local allErrors = {}

    for modName, logger in pairs(loggers) do
        if logger.getRecentErrors then
            local errors = logger.getRecentErrors(count)
            for _, entry in ipairs(errors) do
                table.insert(allErrors, entry)
            end
        end
    end

    -- Sort by timestamp descending (newest first)
    table.sort(allErrors, function(a, b)
        return (a.timestamp or "") > (b.timestamp or "")
    end)

    -- Trim to count
    while #allErrors > count do
        table.remove(allErrors)
    end

    return allErrors
end

--- Get a summary of all registered mod loggers
-- @return table Array of { modName, totalLogged, errorCount, lastLog }
function M.getModSummary()
    local summary = {}

    for modName, logger in pairs(loggers) do
        local entry = {
            modName = modName,
            totalLogged = 0,
            errorCount = 0,
            lastLog = nil,
        }

        if logger.getTotalLogged then
            entry.totalLogged = logger.getTotalLogged()
        end

        if logger.getStats then
            local stats = logger.getStats()
            entry.errorCount = stats.byLevel.error or 0
        end

        if logger.getEntries then
            local recent = logger.getEntries(1)
            if #recent > 0 then
                entry.lastLog = recent[#recent]
            end
        end

        table.insert(summary, entry)
    end

    table.sort(summary, function(a, b)
        return a.modName < b.modName
    end)

    return summary
end

return M
