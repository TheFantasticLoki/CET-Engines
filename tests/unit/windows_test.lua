--[[
    Windows Module Tests — UI-Engine

    Tests for engines/UI-Engine/api/windows.lua
]]

local assert = require("tests.assert")
local Core = require("engines.0-Mod-Engine.core")
local Events = require("engines.0-Mod-Engine.api.events")
local Windows = require("engines.0-Mod-Engine.api.windows")

local M = {}

-- --- Test Setup ---

local function setup()
    Core.reset()
    Core.init()
    Events.init(nil, Core)
    Windows.init({ Core = Core, Events = Events, Logger = nil })
end

-- --- Test Register Window ---

function M.testRegisterWindow()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test Window",
        width = 400,
        height = 300,
        draw_fn = function() end,
    })

    assert.assert_true(success, "Should register successfully")
    assert.assert_nil(err, "Error should be nil")
end

-- --- Test Register Window in GetWindowIds ---

function M.testRegisterWindowInGetWindowIds()
    setup()

    Windows.register("win1", {
        title = "Test Window",
        draw_fn = function() end,
    })

    local ids = Windows.getWindowIds()
    assert.assert_equal(#ids, 1, "Should have 1 window")
    assert.assert_equal(ids[1], "win1", "Should contain win1")
end

-- --- Test Register with Missing Title ---

function M.testRegisterMissingTitle()
    setup()

    local success, err = Windows.register("win1", {
        draw_fn = function() end,
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Empty Title ---

function M.testRegisterEmptyTitle()
    setup()

    local success, err = Windows.register("win1", {
        title = "",
        draw_fn = function() end,
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid ID ---

function M.testRegisterInvalidId()
    setup()

    local success, err = Windows.register("", {
        title = "Test",
        draw_fn = function() end,
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid DrawFn ---

function M.testRegisterInvalidDrawFn()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        draw_fn = "not a function",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Width ---

function M.testRegisterInvalidWidth()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        width = "not a number",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Height ---

function M.testRegisterInvalidHeight()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        height = "not a number",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Flags ---

function M.testRegisterInvalidFlags()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        flags = "not a number",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid Resizable ---

function M.testRegisterInvalidResizable()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        resizable = "not a boolean",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid MinWidth ---

function M.testRegisterInvalidMinWidth()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        min_width = "not a number",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Register with Invalid MinHeight ---

function M.testRegisterInvalidMinHeight()
    setup()

    local success, err = Windows.register("win1", {
        title = "Test",
        min_height = "not a number",
    })

    assert.assert_false(success, "Should fail registration")
    assert.assert_not_nil(err, "Error should be set")
end

-- --- Test Unregister Window ---

function M.testUnregisterWindow()
    setup()

    Windows.register("win1", {
        title = "Test Window",
        draw_fn = function() end,
    })

    local success = Windows.unregister("win1")
    assert.assert_true(success, "Should unregister successfully")

    local ids = Windows.getWindowIds()
    assert.assert_equal(#ids, 0, "Should have 0 windows")
end

-- --- Test Unregister Non-Existent ---

function M.testUnregisterNonExistent()
    setup()

    local success = Windows.unregister("nonexistent")
    assert.assert_false(success, "Should return false for non-existent window")
end

-- --- Test Events Emitted on Register ---

function M.testEventsEmittedOnRegister()
    setup()

    local receivedEvents = {}

    Events.on("windows:registered", function(id, spec)
        table.insert(receivedEvents, { id = id, spec = spec })
    end, "test")

    Windows.register("win1", {
        title = "Test Window",
        draw_fn = function() end,
    })

    assert.assert_equal(#receivedEvents, 1, "Should receive 1 event")
    assert.assert_equal(receivedEvents[1].id, "win1", "Event id should match")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Events Emitted on Unregister ---

function M.testEventsEmittedOnUnregister()
    setup()

    local receivedEvents = {}

    Events.on("windows:unregistered", function(id)
        table.insert(receivedEvents, { id = id })
    end, "test")

    Windows.register("win1", {
        title = "Test Window",
        draw_fn = function() end,
    })

    Windows.unregister("win1")

    assert.assert_equal(#receivedEvents, 1, "Should receive 1 event")
    assert.assert_equal(receivedEvents[1].id, "win1", "Event id should match")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Duplicate Registration Updates ---

function M.testDuplicateRegistrationUpdates()
    setup()

    Windows.register("win1", {
        title = "Window v1",
        draw_fn = function() end,
    })

    Windows.register("win1", {
        title = "Window v2",
        draw_fn = function() end,
    })

    local ids = Windows.getWindowIds()
    assert.assert_equal(#ids, 1, "Should still have 1 window")

    -- The spec should be updated (stored via Core.setWindow which overwrites)
    local spec = Core.getWindow("win1")
    assert.assert_equal(spec.title, "Window v2", "Title should be updated")
end

return M
