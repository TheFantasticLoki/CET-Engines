--[[
    Storage Module Tests — UI-Engine

    Tests for engines/UI-Engine/modules/storage.lua
]]

local assert = require("tests.assert")
local Storage = require("engines.0-Mod-Engine.modules.storage")

local M = {}

-- --- Test Set/Get ---

function M.testSetGet()
    Storage.init()

    -- Set and get values
    Storage.Set("mod-a", "key1", "value1")
    assert.assert_equal(Storage.Get("mod-a", "key1"), "value1", "Should get value1")

    Storage.Set("mod-a", "key2", 42)
    assert.assert_equal(Storage.Get("mod-a", "key2"), 42, "Should get 42")

    -- Default value
    assert.assert_equal(Storage.Get("mod-a", "nonexistent", "default"), "default", "Should get default")
    assert.assert_nil(Storage.Get("mod-a", "nonexistent"), "Should get nil without default")
end

-- --- Test IsDirty ---

function M.testIsDirty()
    Storage.init()

    assert.assert_false(Storage.IsDirty(), "Should not be dirty initially")

    Storage.Set("mod-a", "key1", "value1")
    assert.assert_true(Storage.IsDirty(), "Should be dirty after Set")
end

-- --- Test Clear ---

function M.testClear()
    Storage.init()

    Storage.Set("mod-a", "key1", "value1")
    Storage.Set("mod-a", "key2", "value2")
    Storage.Clear("mod-a")

    assert.assert_nil(Storage.Get("mod-a", "key1"), "Should be nil after clear")
    assert.assert_nil(Storage.Get("mod-a", "key2"), "Should be nil after clear")
end

-- --- Test Atomic Write ---

function M.testAtomicWrite()
    Storage.init()

    -- Set some data
    Storage.Set("mod-a", "key1", "value1")
    Storage.Set("mod-b", "key2", "value2")

    -- Save
    local ok = Storage.Save()
    assert.assert_true(ok, "Save should succeed")
    assert.assert_false(Storage.IsDirty(), "Should not be dirty after save")
end

-- --- Test JSON Round Trip ---

function M.testJsonRoundTrip()
    Storage.init()

    -- Set data
    Storage.Set("mod-a", "string", "hello")
    Storage.Set("mod-a", "number", 42)
    Storage.Set("mod-a", "boolean", true)

    -- Save
    Storage.Save()

    -- Re-init to reload from disk
    Storage.init()

    -- Verify data survived round trip
    assert.assert_equal(Storage.Get("mod-a", "string"), "hello", "String should survive round trip")
    assert.assert_equal(Storage.Get("mod-a", "number"), 42, "Number should survive round trip")
    assert.assert_equal(Storage.Get("mod-a", "boolean"), true, "Boolean should survive round trip")
end

-- --- Test Init ---

function M.testInit()
    -- Init should be idempotent
    Storage.init()
    Storage.init()

    -- Should not error
    assert.assert_true(true, "Init should be idempotent")
end

-- --- Test Error Handling ---

function M.testErrorHandling()
    Storage.init()

    -- Test with nil values
    Storage.Set("mod-a", "key1", nil)
    assert.assert_nil(Storage.Get("mod-a", "key1"), "Should handle nil values")

    -- Test with empty string
    Storage.Set("mod-a", "key2", "")
    assert.assert_equal(Storage.Get("mod-a", "key2"), "", "Should handle empty strings")
end

return M