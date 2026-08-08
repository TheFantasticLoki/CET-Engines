--[[
    Console Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/console.lua
]]

local assert = require("tests.assert")
local console = require("engines.0-Mod-Engine.ui.components.console")

local M = {}

-- --- Test ConsoleOutput ---

function M.testConsoleOutput()
    local entries = {
        { timestamp = "2026-01-01T00:00:00", level = "info", modName = "Test", message = "Hello" },
        { timestamp = "2026-01-01T00:00:01", level = "error", modName = "Test", message = "Error" },
    }
    console.ConsoleOutput(entries, 200)
    assert.assert_true(true, "ConsoleOutput should not throw")
end

function M.testConsoleOutputEmpty()
    console.ConsoleOutput({}, 200)
    assert.assert_true(true, "ConsoleOutput with empty entries should not throw")
end

function M.testConsoleOutputWithFilter()
    local entries = {
        { timestamp = "2026-01-01T00:00:00", level = "info", modName = "Test", message = "Hello world" },
    }
    console.ConsoleOutput(entries, 200, { filter = "world" })
    assert.assert_true(true, "ConsoleOutput with filter should not throw")
end

function M.testConsoleOutputAllLevels()
    local entries = {
        { timestamp = "2026-01-01T00:00:00", level = "debug", modName = "Test", message = "Debug" },
        { timestamp = "2026-01-01T00:00:00", level = "info", modName = "Test", message = "Info" },
        { timestamp = "2026-01-01T00:00:00", level = "warn", modName = "Test", message = "Warn" },
        { timestamp = "2026-01-01T00:00:00", level = "error", modName = "Test", message = "Error" },
    }
    console.ConsoleOutput(entries, 300)
    assert.assert_true(true, "ConsoleOutput with all levels should not throw")
end

-- --- Test RichInput ---

function M.testRichInput()
    local text, submitted = console.RichInput("> ", function(t) end)
    assert.assert_equal(text, "", "Text should be empty")
    assert.assert_false(submitted, "Submitted should be false")
end

function M.testRichInputWithOptions()
    local text, submitted = console.RichInput("$ ", nil, {
        history = { "cmd1", "cmd2" },
        placeholder = "Type a command...",
    })
    assert.assert_false(submitted, "Submitted should be false")
end

-- --- Test ConsoleToolbar ---

function M.testConsoleToolbar()
    local clicked = false
    console.ConsoleToolbar({
        { label = "Clear", icon = "🗑", onClick = function() clicked = true end, tooltip = "Clear logs" },
        { label = "Export", icon = "📋", onClick = function() end },
    })
    assert.assert_true(true, "ConsoleToolbar should not throw")
end

function M.testConsoleToolbarEmpty()
    console.ConsoleToolbar({})
    assert.assert_true(true, "ConsoleToolbar with empty actions should not throw")
end

return M
