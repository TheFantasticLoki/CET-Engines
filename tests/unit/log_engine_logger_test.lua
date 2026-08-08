--[[
    Log-Engine Logger Tests

    Tests for engines/Log-Engine/logger.lua
]]

local assert = require("tests.assert")
local LoggerModule = require("engines.0-Mod-Engine.log.logger")

local M = {}

-- Shared frame counter (simulates the one init.lua provides)
local frameRef = { value = 0 }

-- Helper to create a fresh logger
local function newLogger(name, config)
    frameRef.value = 0
    return LoggerModule.create(name, config or {}, frameRef)
end

-- --- Test Create Logger ---

function M.testCreateLogger()
    local log = newLogger("test-mod")
    assert.assert_not_nil(log, "Logger should be created")
    assert.assert_equal(log.modName, "test-mod", "Logger should have correct modName")
end

function M.testCreateLoggerEmptyName()
    local ok, err = pcall(function()
        LoggerModule.create("", {}, frameRef)
    end)
    assert.assert_false(ok, "Should error on empty modName")
end

function M.testCreateLoggerNonString()
    local ok, err = pcall(function()
        LoggerModule.create(123, {}, frameRef)
    end)
    assert.assert_false(ok, "Should error on non-string modName")
end

-- --- Test Log Levels ---

function M.testLogAtAllLevels()
    local log = newLogger("level-test")
    log.debug("debug msg")
    log.info("info msg")
    log.warn("warn msg")
    log.error("error msg")
    log.print("print msg")

    local entries = log.getEntries(100)
    assert.assert_true(#entries >= 5, "Should have at least 5 entries")

    local levels = {}
    for _, e in ipairs(entries) do
        levels[e.levelName] = true
    end
    assert.assert_true(levels["DEBUG"], "Should have DEBUG entries")
    assert.assert_true(levels["INFO"], "Should have INFO entries")
    assert.assert_true(levels["WARN"], "Should have WARN entries")
    assert.assert_true(levels["ERROR"], "Should have ERROR entries")
    assert.assert_true(levels["PRINT"], "Should have PRINT entries")
end

function M.testMinLevelFiltering()
    local log = newLogger("filter-test", { minLevel = "warn" })
    log.debug("should be filtered")
    log.info("should be filtered")
    log.warn("should pass")
    log.error("should pass")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 2, "Should only have warn and error entries")

    for _, e in ipairs(entries) do
        assert.assert_true(e.level >= 3, "All entries should be warn or above")
    end
end

function M.testSetLevel()
    local log = newLogger("setlevel-test", { minLevel = "error" })
    log.info("filtered")
    log.error("pass")

    assert.assert_equal(#log.getEntries(100), 1, "Should only have 1 entry at error level")

    log.setLevel("debug")
    log.info("now passes")

    assert.assert_equal(#log.getEntries(100), 2, "Should now have 2 entries")
end

function M.testGetLevel()
    local log = newLogger("getlevel-test", { minLevel = "warn" })
    assert.assert_equal(log.getLevel(), "warn", "Should return current level as string")
    assert.assert_equal(log.getLevelNum(), 3, "Should return current level as number")
end

-- --- Test Rate Limiting ---

function M.testDebugRateLimiting()
    local log = newLogger("ratelimit-test")
    frameRef.value = 1

    log.debug("msg 1")
    log.debug("msg 2")
    log.debug("msg 3")

    -- Only 1 debug message per frame
    local entries = log.getEntries(100, "debug")
    assert.assert_equal(#entries, 1, "Only 1 debug message per frame")
end

function M.testRateLimitResetsPerFrame()
    local log = newLogger("reset-test")

    frameRef.value = 1
    log.debug("frame 1")
    log.debug("frame 1 dup")

    frameRef.value = 2
    log.resetFrameCounter()
    log.debug("frame 2")

    local entries = log.getEntries(100, "debug")
    assert.assert_equal(#entries, 2, "Should have 2 debug messages across 2 frames")
end

-- --- Test Formatted Logging ---

function M.testLogf()
    local log = newLogger("logf-test")
    log.logf("info", "Value is %d, name is %s", 42, "test")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 1, "Should have 1 entry")
    assert.assert_equal(entries[1].message, "Value is 42, name is test", "Message should be formatted")
end

function M.testLogfBadFormat()
    local log = newLogger("logf-bad-test")
    -- Should not crash on bad format
    log.logf("info", "Missing %s arg")

    local entries = log.getEntries(100)
    assert.assert_true(#entries >= 1, "Should have at least 1 entry (error about format)")
end

-- --- Test Ring Buffer ---

function M.testRingBufferOverflow()
    local log = newLogger("ring-test", { ringSize = 10 })

    for i = 1, 20 do
        log.info("message " .. i)
    end

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 10, "Should have at most 10 entries (ring buffer size)")

    -- The oldest entries should be overwritten, newest should remain
    assert.assert_equal(entries[1].message, "message 11", "Oldest should be message 11")
    assert.assert_equal(entries[10].message, "message 20", "Newest should be message 20")
end

function M.testGetEntriesCount()
    local log = newLogger("count-test")

    for i = 1, 50 do
        log.info("msg " .. i)
    end

    local entries = log.getEntries(10)
    assert.assert_equal(#entries, 10, "Should return requested count")
end

function M.testGetEntriesLevelFilter()
    local log = newLogger("levelfilter-test")
    log.debug("d1")
    log.info("i1")
    log.warn("w1")
    log.error("e1")

    local entries = log.getEntries(100, "warn")
    assert.assert_equal(#entries, 2, "Should have warn and error entries")
end

-- --- Test Stats ---

function M.testGetStats()
    local log = newLogger("stats-test")
    log.info("msg 1")
    log.info("msg 2")
    log.error("err 1")

    local stats = log.getStats()
    assert.assert_equal(stats.totalLogged, 3, "Total logged should be 3")
    assert.assert_equal(stats.byLevel.info, 2, "Should have 2 info entries")
    assert.assert_equal(stats.byLevel.error, 1, "Should have 1 error entry")
end

function M.testGetRecentErrors()
    local log = newLogger("errors-test")
    log.info("info 1")
    log.error("err 1")
    log.warn("warn 1")
    log.error("err 2")

    local errors = log.getRecentErrors(10)
    assert.assert_equal(#errors, 2, "Should have 2 error entries")
    -- Newest first
    assert.assert_equal(errors[1].message, "err 2", "First error should be newest")
end

-- --- Test Clear ---

function M.testClear()
    local log = newLogger("clear-test")
    log.info("msg 1")
    log.info("msg 2")

    log.clear()

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 0, "Should have 0 entries after clear")
end

-- --- Test Total Logged ---

function M.testGetTotalLogged()
    local log = newLogger("total-test")
    log.info("a")
    log.info("b")
    log.info("c")

    assert.assert_equal(log.getTotalLogged(), 3, "Total logged should be 3")
end

-- --- Test Capacity ---

function M.testGetCapacity()
    local log = newLogger("capacity-test", { ringSize = 256 })
    assert.assert_equal(log.getCapacity(), 256, "Capacity should match config")
end

-- --- Test Deduplication ---

function M.testDedupSuppressesDuplicates()
    local log = newLogger("dedup-test", { dedupEnabled = true })
    log.error("same error")
    log.error("same error")
    log.error("same error")

    local entries = log.getEntries(100)
    -- Only 1 entry should be written (first occurrence)
    assert.assert_equal(#entries, 1, "Should have 1 entry (dedup suppressed duplicates)")
    assert.assert_equal(entries[1].message, "same error", "Entry should be the original message")
end

function M.testDedupDifferentMessages()
    local log = newLogger("dedup-diff-test", { dedupEnabled = true })
    log.error("error 1")
    log.error("error 2")
    log.error("error 3")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 3, "Should have 3 entries (all different messages)")
end

function M.testDedupDifferentLevels()
    local log = newLogger("dedup-level-test", { dedupEnabled = true })
    log.error("same message")
    log.warn("same message")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 2, "Should have 2 entries (different levels)")
end

function M.testDedupDisabled()
    local log = newLogger("dedup-disabled-test", { dedupEnabled = false })
    log.error("same error")
    log.error("same error")
    log.error("same error")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 3, "Should have 3 entries (dedup disabled)")
end

function M.testDedupStats()
    local log = newLogger("dedup-stats-test", { dedupEnabled = true })
    log.error("error 1")
    log.error("error 1")
    log.error("error 1")
    log.error("error 2")

    local stats = log.getDedupStats()
    assert.assert_true(stats.totalDeduped > 0, "Should have dedup stats")
end

function M.testDedupFlush()
    local log = newLogger("dedup-flush-test", { dedupEnabled = true })
    log.error("error 1")
    log.error("error 1")
    log.error("error 1")

    -- Flush dedup summaries
    log.flushDedup()

    -- After flush, the dedup table should be cleared
    local stats = log.getDedupStats()
    assert.assert_equal(stats.pendingSummaries, 0, "Should have 0 pending summaries after flush")
end

-- --- Test Print Level ---

function M.testPrintLevel()
    local log = newLogger("print-test")
    log.print("console output")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 1, "Should have 1 entry")
    assert.assert_equal(entries[1].levelName, "PRINT", "Should be PRINT level")
    assert.assert_equal(entries[1].message, "console output", "Should have the message")
end

function M.testPrintLevelFiltering()
    local log = newLogger("print-filter-test", { minLevel = "error" })
    log.print("should be filtered")
    log.error("should pass")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 1, "Should only have error entry")
    assert.assert_equal(entries[1].levelName, "ERROR", "Should be ERROR level")
end

-- --- Test Timestamp Format ---

function M.testTimestampFormat()
    local log = newLogger("timestamp-test")
    log.info("test message")

    local entries = log.getEntries(100)
    assert.assert_equal(#entries, 1, "Should have 1 entry")

    -- Timestamp should be in HH:MM:SS.mmm format (time-only)
    local ts = entries[1].timestamp
    assert.assert_true(ts ~= nil, "Timestamp should not be nil")
    assert.assert_true(ts:match("^%d%d:%d%d:%d%d%.%d%d%d$") ~= nil, "Timestamp should be in HH:MM:SS.mmm format, got: " .. ts)
end