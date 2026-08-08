--[[
    Log-Engine Config Tests

    Tests for engines/Log-Engine/config.lua
]]

local assert = require("tests.assert")
local Config = require("engines.0-Mod-Engine.log.config")

local M = {}

-- --- Test Default Values ---

function M.testDefaultRingSize()
    assert.assert_equal(Config.RING_SIZE, 1024, "Default ring size should be 1024")
end

function M.testDefaultMaxFileSize()
    assert.assert_equal(Config.MAX_FILE_SIZE, 2 * 1024 * 1024, "Default max file size should be 2MB")
end

function M.testDefaultMaxFiles()
    assert.assert_equal(Config.MAX_FILES, 5, "Default max files should be 5")
end

function M.testDefaultMinLevel()
    assert.assert_equal(Config.DEFAULT_MIN_LEVEL, "debug", "Default min level should be debug")
end

function M.testLogLevelConstants()
    assert.assert_equal(Config.LEVEL_DEBUG, 1, "LEVEL_DEBUG should be 1")
    assert.assert_equal(Config.LEVEL_INFO, 2, "LEVEL_INFO should be 2")
    assert.assert_equal(Config.LEVEL_WARN, 3, "LEVEL_WARN should be 3")
    assert.assert_equal(Config.LEVEL_ERROR, 4, "LEVEL_ERROR should be 4")
    assert.assert_equal(Config.LEVEL_PRINT, 5, "LEVEL_PRINT should be 5")
end

function M.testLevelNames()
    assert.assert_equal(Config.LEVEL_NAMES[1], "DEBUG", "Level 1 should be DEBUG")
    assert.assert_equal(Config.LEVEL_NAMES[2], "INFO", "Level 2 should be INFO")
    assert.assert_equal(Config.LEVEL_NAMES[3], "WARN", "Level 3 should be WARN")
    assert.assert_equal(Config.LEVEL_NAMES[4], "ERROR", "Level 4 should be ERROR")
    assert.assert_equal(Config.LEVEL_NAMES[5], "PRINT", "Level 5 should be PRINT")
end

function M.testLogDir()
    assert.assert_equal(Config.LOG_DIR, "logs", "Default log dir should be 'logs'")
end

function M.testLogFileSuffix()
    assert.assert_equal(Config.LOG_FILE_SUFFIX, ".log", "Default log file suffix should be '.log'")
end

function M.testMaxDebugPerFrame()
    assert.assert_equal(Config.MAX_DEBUG_PER_FRAME, 1, "Default max debug per frame should be 1")
end

-- --- Test New Config Values ---

function M.testDedupEnabled()
    assert.assert_true(Config.DEDUP_ENABLED, "Default dedup should be enabled")
end

function M.testDedupMaxEntries()
    assert.assert_equal(Config.DEDUP_MAX_ENTRIES, 256, "Default dedup max entries should be 256")
end

function M.testSessionIdLength()
    assert.assert_equal(Config.SESSION_ID_LENGTH, 8, "Default session ID length should be 8")
end