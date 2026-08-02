--[[
    Log-Engine Stats Tests

    Tests for engines/Log-Engine/stats.lua
]]

local assert = require("tests.assert")
local Stats = require("engines.Log-Engine.stats")
local LoggerModule = require("engines.Log-Engine.logger")

local M = {}

-- Shared frame counter
local frameRef = { value = 0 }

-- Helper to create a mock logger with some entries
local function makeLogger(name, entries)
    frameRef.value = 0
    local log = LoggerModule.create(name, { ringSize = 100 }, frameRef)
    for _, entry in ipairs(entries) do
        log.log(entry[1], entry[2])
    end
    return log
end

-- --- Test Init ---

function M.testInit()
    local loggers = {}
    Stats.init(loggers)
    Stats.init(loggers)  -- Idempotent
    assert.assert_true(true, "Init should be idempotent")
end

-- --- Test GetModStats ---

function M.testGetModStats()
    local loggers = {}
    local log = makeLogger("mod-a", {
        { "info", "msg1" },
        { "info", "msg2" },
        { "error", "err1" },
    })
    loggers["mod-a"] = log
    Stats.init(loggers)

    local stats = Stats.getModStats("mod-a")
    assert.assert_not_nil(stats, "Should return stats for known mod")
    assert.assert_equal(stats.totalLogged, 3, "Total should be 3")
    assert.assert_equal(stats.byLevel.info, 2, "Should have 2 info entries")
    assert.assert_equal(stats.byLevel.error, 1, "Should have 1 error entry")
end

function M.testGetModStatsUnknown()
    Stats.init({})
    local stats = Stats.getModStats("nonexistent")
    assert.assert_nil(stats, "Should return nil for unknown mod")
end

-- --- Test GetAggregateStats ---

function M.testGetAggregateStats()
    local loggers = {}
    loggers["mod-a"] = makeLogger("mod-a", {
        { "info", "msg1" },
        { "error", "err1" },
    })
    loggers["mod-b"] = makeLogger("mod-b", {
        { "warn", "warn1" },
    })
    Stats.init(loggers)

    local stats = Stats.getAggregateStats()
    assert.assert_equal(stats.totalMods, 2, "Should have 2 mods")
    assert.assert_equal(stats.totalLogged, 3, "Total logged should be 3")
    assert.assert_equal(stats.byLevel.info, 1, "Should have 1 info total")
    assert.assert_equal(stats.byLevel.error, 1, "Should have 1 error total")
    assert.assert_equal(stats.byLevel.warn, 1, "Should have 1 warn total")
end

function M.testGetAggregateStatsEmpty()
    Stats.init({})
    local stats = Stats.getAggregateStats()
    assert.assert_equal(stats.totalMods, 0, "Should have 0 mods")
    assert.assert_equal(stats.totalLogged, 0, "Total logged should be 0")
end

-- --- Test GetRecentErrors ---

function M.testGetRecentErrors()
    local loggers = {}
    loggers["mod-a"] = makeLogger("mod-a", {
        { "info", "msg1" },
        { "error", "err1" },
        { "error", "err2" },
    })
    loggers["mod-b"] = makeLogger("mod-b", {
        { "error", "err3" },
    })
    Stats.init(loggers)

    local errors = Stats.getRecentErrors(10)
    assert.assert_equal(#errors, 3, "Should have 3 errors total")
end

function M.testGetRecentErrorsCount()
    local loggers = {}
    loggers["mod-a"] = makeLogger("mod-a", {
        { "error", "e1" },
        { "error", "e2" },
        { "error", "e3" },
        { "error", "e4" },
        { "error", "e5" },
    })
    Stats.init(loggers)

    local errors = Stats.getRecentErrors(3)
    assert.assert_equal(#errors, 3, "Should respect count limit")
end

-- --- Test GetModSummary ---

function M.testGetModSummary()
    local loggers = {}
    loggers["alpha"] = makeLogger("alpha", {
        { "info", "msg1" },
        { "error", "err1" },
    })
    loggers["beta"] = makeLogger("beta", {
        { "info", "msg2" },
    })
    Stats.init(loggers)

    local summary = Stats.getModSummary()
    assert.assert_equal(#summary, 2, "Should have 2 entries")

    -- Should be sorted alphabetically
    assert.assert_equal(summary[1].modName, "alpha", "First should be alpha")
    assert.assert_equal(summary[2].modName, "beta", "Second should be beta")

    assert.assert_equal(summary[1].errorCount, 1, "Alpha should have 1 error")
    assert.assert_equal(summary[2].errorCount, 0, "Beta should have 0 errors")
end

function M.testGetModSummaryEmpty()
    Stats.init({})
    local summary = Stats.getModSummary()
    assert.assert_equal(#summary, 0, "Should have 0 entries for empty loggers")
end
