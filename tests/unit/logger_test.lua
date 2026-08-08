--[[
    Logger Module Tests — UI-Engine

    Tests for engines/UI-Engine/modules/logger.lua
]]

local assert = require("tests.assert")
local Logger = require("engines.0-Mod-Engine.modules.logger")

local M = {}

-- --- Test Ring Buffer ---

function M.testRingBuffer()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()

    -- Fill the ring buffer beyond capacity
    for i = 1, 600 do
        Logger.Log("test", "message " .. i, "info")
    end

    -- Should have at most 512 entries
    local entries = Logger.GetEntries(1000)
    assert.assert_true(#entries <= 512, "Ring buffer should not exceed 512 entries")
end

-- --- Test Log Levels ---

function M.testLogLevels()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()
    Logger.SetLevel("debug")

    -- Log at each level
    Logger.Log("test", "debug msg", "debug")
    Logger.Log("test", "info msg", "info")
    Logger.Log("test", "warn msg", "warn")
    Logger.Log("test", "error msg", "error")

    local entries = Logger.GetEntries(100)
    assert.assert_true(#entries >= 4, "Should have at least 4 entries")

    -- Verify levels
    local levels = {}
    for _, e in ipairs(entries) do
        levels[e.levelName] = true
    end
    assert.assert_true(levels["DEBUG"], "Should have DEBUG entries")
    assert.assert_true(levels["INFO"], "Should have INFO entries")
    assert.assert_true(levels["WARN"], "Should have WARN entries")
    assert.assert_true(levels["ERROR"], "Should have ERROR entries")
end

-- --- Test Rate Limiting ---

function M.testRateLimiting()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()
    Logger.SetLevel("debug")
    Logger.SetFrame(1)

    -- Log multiple debug messages in the same frame
    Logger.Log("test", "debug 1", "debug")
    Logger.Log("test", "debug 2", "debug")
    Logger.Log("test", "debug 3", "debug")

    -- Only 1 debug message should be recorded per frame
    local entries = Logger.GetEntries(100, "test", "debug")
    assert.assert_equal(#entries, 1, "Only 1 debug message per frame")
end

-- --- Test GetEntries ---

function M.testGetEntries()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()
    Logger.SetLevel("debug")

    -- Log some entries
    Logger.Log("mod-a", "message 1", "info")
    Logger.Log("mod-b", "message 2", "warn")
    Logger.Log("mod-a", "message 3", "error")

    -- Get all entries
    local all = Logger.GetEntries(100)
    assert.assert_true(#all >= 3, "Should have at least 3 entries")

    -- Filter by mod
    local modA = Logger.GetEntries(100, "mod-a")
    assert.assert_true(#modA >= 2, "Should have at least 2 entries for mod-a")

    -- Filter by level
    local warns = Logger.GetEntries(100, nil, "warn")
    assert.assert_true(#warns >= 2, "Should have at least 2 warn/error entries")
end

-- --- Test Clear ---

function M.testClear()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()
    Logger.SetLevel("debug")

    Logger.Log("test", "message", "info")
    Logger.Clear()

    local entries = Logger.GetEntries(100)
    assert.assert_equal(#entries, 0, "Should have no entries after clear")
end

-- --- Test SetFrame ---

function M.testSetFrame()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()
    Logger.SetLevel("debug")

    Logger.SetFrame(100)
    Logger.Log("test", "message", "info")

    local entries = Logger.GetEntries(100)
    assert.assert_true(#entries >= 1, "Should have at least 1 entry")
    assert.assert_equal(entries[1].frame, 100, "Frame should be 100")
end

-- --- Test SetLevel ---

function M.testSetLevel()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()

    -- Set to warn level
    Logger.SetLevel("warn")
    assert.assert_equal(Logger.GetLevel(), 3, "Level should be 3 (warn)")

    -- Log at different levels
    Logger.Log("test", "debug msg", "debug")
    Logger.Log("test", "info msg", "info")
    Logger.Log("test", "warn msg", "warn")
    Logger.Log("test", "error msg", "error")

    -- Only warn and error should be recorded
    local entries = Logger.GetEntries(100)
    assert.assert_true(#entries >= 2, "Should have at least 2 entries (warn + error)")
    for _, e in ipairs(entries) do
        assert.assert_true(e.level >= 3, "All entries should be warn or above")
    end
end

-- --- Test Overlay Toggle ---

function M.testOverlayToggle()
    Logger.Clear()
    Logger.SetFrame(0)
    Logger.init()

    assert.assert_false(Logger.IsOverlayEnabled(), "Overlay should be disabled by default")

    Logger.SetOverlay(true)
    assert.assert_true(Logger.IsOverlayEnabled(), "Overlay should be enabled")

    Logger.SetOverlay(false)
    assert.assert_false(Logger.IsOverlayEnabled(), "Overlay should be disabled")
end

return M