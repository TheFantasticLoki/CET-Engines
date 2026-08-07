-- Test: ConfigEngine StateSync
-- Stub smoke tests for cfg/state_sync.lua

local M = {}

function M.testModuleLoads()
    local StateSync = require("cfg/state_sync")
    assert(StateSync ~= nil, "StateSync should load")
    assert(type(StateSync.init) == "function", "should have init()")
    assert(type(StateSync.loadAll) == "function", "should have loadAll()")
    assert(type(StateSync.saveAll) == "function", "should have saveAll()")
    assert(type(StateSync.autoSave) == "function", "should have autoSave()")
    assert(type(StateSync.setAutoSaveDelay) == "function", "should have setAutoSaveDelay()")
end

function M.testSetAutoSaveDelayRejectsInvalid()
    local StateSync = require("cfg/state_sync")
    StateSync.setAutoSaveDelay(-1)   -- should be ignored
    StateSync.setAutoSaveDelay("x")  -- should be ignored
    StateSync.setAutoSaveDelay(0)    -- should be ignored
    -- No crash = pass
end

return M
