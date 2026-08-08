--[[
    Context Module Tests — UI-Engine

    Tests for engines/UI-Engine/api/context.lua
]]

local assert = require("tests.assert")
local Core = require("engines.0-Mod-Engine.core")
local Events = require("engines.0-Mod-Engine.api.events")
local Context = require("engines.0-Mod-Engine.api.context")

local M = {}

-- --- Test Setup ---

local function setup()
    Core.reset()
    Core.init()
    Events.init(nil, Core)
    Context.init({
        Core = Core,
        Events = Events,
        Components = nil,  -- No components for basic tests
        Tokens = nil,
        Utils = nil,
    })
end

-- --- Test Create Context ---

function M.testCreateContext()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    assert.assert_not_nil(ctx, "Context should be created")
    assert.assert_equal(ctx.modId, "mod1", "modId should be set")
    assert.assert_equal(ctx.spec.name, "Mod 1", "spec.name should be set")
end

-- --- Test Context Has GetState/SetState ---

function M.testContextHasGetSetState()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    assert.assert_true(type(ctx.getState) == "function", "getState should be a function")
    assert.assert_true(type(ctx.setState) == "function", "setState should be a function")
end

-- --- Test SetState and GetState ---

function M.testSetStateAndGetState()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    ctx.setState("key", "value")
    local val = ctx.getState("key")
    assert.assert_equal(val, "value", "Should return set value")
end

-- --- Test GetState Default ---

function M.testGetStateDefault()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    local val = ctx.getState("missing", "default")
    assert.assert_equal(val, "default", "Should return default for missing key")
end

-- --- Test GetState Nil Default ---

function M.testGetStateNilDefault()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    local val = ctx.getState("missing")
    assert.assert_nil(val, "Should return nil when no default")
end

-- --- Test State Is Per-Mod ---

function M.testStateIsPerMod()
    setup()

    local ctx1 = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    local ctx2 = Context.create("mod2", {
        name = "Mod 2",
        version = "2.0.0",
    })

    ctx1.setState("key", "value1")
    ctx2.setState("key", "value2")

    assert.assert_equal(ctx1.getState("key"), "value1", "mod1 should have value1")
    assert.assert_equal(ctx2.getState("key"), "value2", "mod2 should have value2")
end

-- --- Test Context Has GetThemeColor ---

function M.testContextHasGetThemeColor()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    assert.assert_true(type(ctx.getThemeColor) == "function", "getThemeColor should be a function")
end

-- --- Test GetThemeColor Fallback ---

function M.testGetThemeColorFallback()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    -- No Tokens module, should return fallback white
    local color = ctx.getThemeColor("primary")
    assert.assert_not_nil(color, "Should return a color")
    assert.assert_equal(color.r, 1, "r should be 1")
    assert.assert_equal(color.g, 1, "g should be 1")
    assert.assert_equal(color.b, 1, "b should be 1")
    assert.assert_equal(color.a, 1, "a should be 1")
end

-- --- Test Context Has GetModId ---

function M.testContextHasGetModId()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    assert.assert_true(type(ctx.getModId) == "function", "getModId should be a function")
    assert.assert_equal(ctx.getModId(), "mod1", "getModId should return mod1")
end

-- --- Test Context Has GetModSpec ---

function M.testContextHasGetModSpec()
    setup()

    local spec = {
        name = "Mod 1",
        version = "1.0.0",
        author = "Test Author",
    }
    local ctx = Context.create("mod1", spec)

    assert.assert_true(type(ctx.getModSpec) == "function", "getModSpec should be a function")
    local retrieved = ctx.getModSpec()
    assert.assert_equal(retrieved.name, "Mod 1", "spec.name should match")
    assert.assert_equal(retrieved.version, "1.0.0", "spec.version should match")
end

-- --- Test ClearState ---

function M.testClearState()
    setup()

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    ctx.setState("key", "value")
    assert.assert_equal(ctx.getState("key"), "value", "Should have value")

    Context.clearState("mod1")
    local val = ctx.getState("key", "default")
    assert.assert_equal(val, "default", "Should have default after clear")
end

-- --- Test External GetState/SetState ---

function M.testExternalGetSetState()
    setup()

    Context.setState("mod1", "key", "value")
    local val = Context.getState("mod1", "key")
    assert.assert_equal(val, "value", "External setState should work")

    local val2 = Context.getState("mod1", "missing", "default")
    assert.assert_equal(val2, "default", "External getState with default should work")
end

-- --- Test State Changed Event ---

function M.testStateChangedEvent()
    setup()

    local receivedEvents = {}

    Events.on("context:stateChanged", function(modId, key, value)
        table.insert(receivedEvents, { modId = modId, key = key, value = value })
    end, "test")

    local ctx = Context.create("mod1", {
        name = "Mod 1",
        version = "1.0.0",
    })

    ctx.setState("key", "value")

    assert.assert_equal(#receivedEvents, 1, "Should receive 1 event")
    assert.assert_equal(receivedEvents[1].modId, "mod1", "modId should match")
    assert.assert_equal(receivedEvents[1].key, "key", "key should match")
    assert.assert_equal(receivedEvents[1].value, "value", "value should match")

    -- Clean up
    Events.cleanup("test")
end

return M
