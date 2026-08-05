--[[
    Events Module Tests — UI-Engine

    Tests for engines/UI-Engine/api/events.lua
]]

local assert = require("tests.assert")
local Events = require("engines.UI-Engine.api.events")

local M = {}

-- --- Test Subscribe/Emit ---

function M.testSubscribeEmit()
    local received = {}

    Events.on("test:event", function(a, b)
        table.insert(received, { a = a, b = b })
    end, "test")

    Events.emit("test:event", "hello", 42)

    assert.assert_equal(#received, 1, "Should receive 1 event")
    assert.assert_equal(received[1].a, "hello", "First arg should be hello")
    assert.assert_equal(received[1].b, 42, "Second arg should be 42")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Unsubscribe ---

function M.testUnsubscribe()
    local count = 0

    local handler = function()
        count = count + 1
    end

    Events.on("test:event", handler, "test")
    Events.emit("test:event")
    assert.assert_equal(count, 1, "Should be called once")

    Events.off("test:event", handler)
    Events.emit("test:event")
    assert.assert_equal(count, 1, "Should still be 1 after unsubscribe")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Once ---

function M.testOnce()
    local count = 0

    Events.once("test:event", function()
        count = count + 1
    end, "test")

    Events.emit("test:event")
    assert.assert_equal(count, 1, "Should be called once")

    Events.emit("test:event")
    assert.assert_equal(count, 1, "Should still be 1 after once")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Pcall Guard ---

function M.testPcallGuard()
    local errorLogged = false

    -- Set up a logger that tracks errors
    local mockLogger = {
        Log = function(modName, message, level)
            if level == "error" then
                errorLogged = true
            end
        end,
    }

    -- Reset events module state to allow re-initialization
    Events._reset()
    Events.init(mockLogger, nil)

    -- Subscribe a handler that throws
    Events.on("test:event", function()
        error("handler error")
    end, "test")

    -- Emit should not crash
    Events.emit("test:event")
    assert.assert_true(errorLogged, "Error should be logged")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Source Labels ---

function M.testSourceLabels()
    local sources = {}

    Events.on("test:event", function()
        table.insert(sources, "handler1")
    end, "source-a")

    Events.on("test:event", function()
        table.insert(sources, "handler2")
    end, "source-b")

    Events.emit("test:event")

    assert.assert_equal(#sources, 2, "Both handlers should be called")

    -- Clean up
    Events.cleanup("source-a")
    Events.cleanup("source-b")
end

-- --- Test Mod-Scoped Cleanup ---

function M.testModScopedCleanup()
    local count = 0

    Events.on("test:event", function()
        count = count + 1
    end, "mod-a")

    Events.on("test:event", function()
        count = count + 1
    end, "mod-b")

    Events.emit("test:event")
    assert.assert_equal(count, 2, "Both handlers should be called")

    -- Clean up only mod-a
    Events.cleanup("mod-a")
    Events.emit("test:event")
    assert.assert_equal(count, 3, "Only mod-b handler should be called")

    -- Clean up mod-b
    Events.cleanup("mod-b")
    Events.emit("test:event")
    assert.assert_equal(count, 3, "No handlers should be called")
end

-- --- Test Argument Passing ---

function M.testArgumentPassing()
    local received = {}

    Events.on("test:event", function(a, b, c)
        table.insert(received, { a = a, b = b, c = c })
    end, "test")

    Events.emit("test:event", 1, "two", true)

    assert.assert_equal(#received, 1, "Should receive 1 event")
    assert.assert_equal(received[1].a, 1, "First arg should be 1")
    assert.assert_equal(received[1].b, "two", "Second arg should be two")
    assert.assert_equal(received[1].c, true, "Third arg should be true")

    -- Clean up
    Events.cleanup("test")
end

-- --- Test Listener Count ---

function M.testListenerCount()
    local handler1 = function() end
    local handler2 = function() end

    Events.on("test:event", handler1, "test")
    Events.on("test:event", handler2, "test")

    assert.assert_equal(Events.getListenerCount("test:event"), 2, "Should have 2 listeners")

    Events.off("test:event", handler1)
    assert.assert_equal(Events.getListenerCount("test:event"), 1, "Should have 1 listener")

    Events.off("test:event", handler2)
    assert.assert_equal(Events.getListenerCount("test:event"), 0, "Should have 0 listeners")

    -- Clean up
    Events.cleanup("test")
end

return M