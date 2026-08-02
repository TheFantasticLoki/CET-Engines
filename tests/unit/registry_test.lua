--[[
    Registry Module Tests — UI-Engine

    Tests for engines/UI-Engine/api/registry.lua
]]

local assert = require("tests.assert")
local Core = require("engines.UI-Engine.core")
local Events = require("engines.UI-Engine.api.events")
local Registry = require("engines.UI-Engine.api.registry")

local M = {}

-- --- Test Setup ---

local function setup()
    Core.reset()
    Core.init()
    Events.init(nil, Core)
    Registry.init({ Core = Core, Events = Events, Logger = nil })
end

-- --- Test Register Valid Mod ---

function M.testRegisterValidMod()
    setup()

    local success, err = Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
        author = "Test Author",
    })

    assert.assert_true(success, "Should register successfully")
    assert.assert_nil(err, "Error should be nil")
end

-- --- Test Register with Missing Name ---

function M.testRegisterMissingName()
    setup()

    local success, err = Registry.register("mod2", {
        version = "1.0.0",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid ID ---

function M.testRegisterInvalidId()
    setup()

    local success, err = Registry.register("", {
        name = "Mod",
        version = "1.0.0",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Nil Spec ---

function M.testRegisterNilSpec()
    setup()

    local success, err = Registry.register("mod3", nil)

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Spec Type ---

function M.testRegisterInvalidSpecType()
    setup()

    local success, err = Registry.register("mod4", "not a table")

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Version ---

function M.testRegisterInvalidVersion()
    setup()

    local success, err = Registry.register("mod5", {
        name = "Mod 5",
        version = 123,  -- should be string
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Draw ---

function M.testRegisterInvalidDraw()
    setup()

    local success, err = Registry.register("mod6", {
        name = "Mod 6",
        version = "1.0.0",
        draw = "not a function",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Unregister Mod ---

function M.testUnregisterMod()
    setup()

    -- Register first
    Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    -- Verify registered
    local ids = Registry.getModIds()
    assert.assert_equal(#ids, 1, "Should have 1 mod")

    -- Unregister
    local success = Registry.unregister("mod1")
    assert.assert_true(success, "Should unregister successfully")

    -- Verify removed
    ids = Registry.getModIds()
    assert.assert_equal(#ids, 0, "Should have 0 mods")
end

-- --- Test Unregister Non-Existent ---

function M.testUnregisterNonExistent()
    setup()

    local success = Registry.unregister("nonexistent")
    assert.assert_false(success, "Should return false for non-existent mod")
end

-- --- Test GetMod Returns Spec ---

function M.testGetModReturnsSpec()
    setup()

    local spec = {
        name = "Mod 1",
        version = "1.0.0",
        author = "Test Author",
    }
    Registry.register("mod1", spec)

    local retrieved = Registry.getMod("mod1")
    assert.assert_not_nil(retrieved, "Should return spec")
    assert.assert_equal(retrieved.name, "Mod 1", "Name should match")
    assert.assert_equal(retrieved.version, "1.0.0", "Version should match")
end

-- --- Test GetMod Non-Existent ---

function M.testGetModNonExistent()
    setup()

    local retrieved = Registry.getMod("nonexistent")
    assert.assert_nil(retrieved, "Should return nil for non-existent mod")
end

-- --- Test GetModIds Returns All IDs ---

function M.testGetModIdsReturnsAllIDs()
    setup()

    Registry.register("mod1", { name = "Mod 1", version = "1.0.0" })
    Registry.register("mod2", { name = "Mod 2", version = "2.0.0" })
    Registry.register("mod3", { name = "Mod 3", version = "3.0.0" })

    local ids = Registry.getModIds()
    assert.assert_equal(#ids, 3, "Should have 3 mod IDs")

    -- Check that all IDs are present
    local idSet = {}
    for _, id in ipairs(ids) do
        idSet[id] = true
    end
    assert.assert_true(idSet["mod1"], "Should contain mod1")
    assert.assert_true(idSet["mod2"], "Should contain mod2")
    assert.assert_true(idSet["mod3"], "Should contain mod3")
end

-- --- Test GetModCount ---

function M.testGetModCount()
    setup()

    assert.assert_equal(Registry.getModCount(), 0, "Should start with 0")

    Registry.register("mod1", { name = "Mod 1", version = "1.0.0" })
    assert.assert_equal(Registry.getModCount(), 1, "Should have 1 mod")

    Registry.register("mod2", { name = "Mod 2", version = "2.0.0" })
    assert.assert_equal(Registry.getModCount(), 2, "Should have 2 mods")

    Registry.unregister("mod1")
    assert.assert_equal(Registry.getModCount(), 1, "Should have 1 mod after unregister")
end

-- --- Test Duplicate Registration Updates ---

function M.testDuplicateRegistrationUpdates()
    setup()

    -- Register v1.0
    Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    local spec1 = Registry.getMod("mod1")
    assert.assert_equal(spec1.version, "1.0.0", "Version should be 1.0.0")

    -- Register again with v2.0
    Registry.register("mod1", {
        name = "Mod 1",
        version = "2.0.0",
    })

    local spec2 = Registry.getMod("mod1")
    assert.assert_equal(spec2.version, "2.0.0", "Version should be updated to 2.0.0")

    -- Should still have only 1 mod
    assert.assert_equal(Registry.getModCount(), 1, "Should still have 1 mod")
end

-- --- Test Events Emitted on Register ---

function M.testEventsEmittedOnRegister()
    setup()

    local receivedEvents = {}

    Events.on("uiengine:registered", function(id, spec)
        table.insert(receivedEvents, { id = id, spec = spec })
    end, "test")

    Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    assert.assert_equal(#receivedEvents, 1, "Should receive 1 event")
    assert.assert_equal(receivedEvents[1].id, "mod1", "Event id should match")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Events Emitted on Unregister ---

function M.testEventsEmittedOnUnregister()
    setup()

    local receivedEvents = {}

    Events.on("uiengine:unregistered", function(id)
        table.insert(receivedEvents, { id = id })
    end, "test")

    Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    Registry.unregister("mod1")

    assert.assert_equal(#receivedEvents, 1, "Should receive 1 event")
    assert.assert_equal(receivedEvents[1].id, "mod1", "Event id should match")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Dependencies Check ---

function M.testDependenciesCheck()
    setup()

    -- Register a dependency first
    Registry.register("dep1", {
        name = "Dependency 1",
        version = "1.0.0",
    })

    -- Register mod with dependency
    local success, err = Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
        dependencies = { "dep1" },
    })

    assert.assert_true(success, "Should register with satisfied dependency")
end

-- --- Test Missing Dependency ---

function M.testMissingDependency()
    setup()

    local success, err = Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
        dependencies = { "nonexistent" },
    })

    assert.assert_false(success, "Should fail with missing dependency")
    assert.assert_not_nil(err, "Error should mention missing dependency")
end

-- --- Test onDisable Called on Unregister ---

function M.testOnDisableCalledOnUnregister()
    setup()

    local disableCalled = false

    Registry.register("mod1", {
        name = "Mod 1",
        version = "1.0.0",
        onDisable = function()
            disableCalled = true
        end,
    })

    Registry.unregister("mod1")

    assert.assert_true(disableCalled, "onDisable should be called")
end

return M
