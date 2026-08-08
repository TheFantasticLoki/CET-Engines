--[[
    Buttons Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/buttons.lua
]]

local assert = require("tests.assert")
local buttons = require("engines.0-Mod-Engine.ui.components.buttons")

local M = {}

-- --- Test Button ---

function M.testButton()
    local clicked = buttons.Button("Click me")
    assert.assert_false(clicked, "Clicked should be false")
end

function M.testButtonWithOptions()
    local clicked = buttons.Button("Click me", { width = 100, height = 30, tooltip = "Test tooltip" })
    assert.assert_false(clicked, "Clicked should be false")
end

function M.testButtonNilLabel()
    local clicked = buttons.Button(nil)
    assert.assert_false(clicked, "Clicked should be false with nil label")
end

-- --- Test ToggleButton ---

function M.testToggleButton()
    local newValue, changed = buttons.ToggleButton("Toggle", false)
    assert.assert_false(newValue, "Value should be false")
    assert.assert_false(changed, "Changed should be false")
end

function M.testToggleButtonOn()
    local newValue, changed = buttons.ToggleButton("Toggle", true)
    assert.assert_true(newValue, "Value should be true")
    assert.assert_false(changed, "Changed should be false")
end

function M.testToggleButtonColor()
    -- Should not throw when rendering with theme colors
    buttons.ToggleButton("Toggle", false)
    buttons.ToggleButton("Toggle", true)
    assert.assert_true(true, "ToggleButton should not throw")
end

function M.testToggleButtonTooltip()
    local newValue, changed = buttons.ToggleButton("Toggle", false, { tooltip = "Toggle tooltip" })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test IconButton ---

function M.testIconButton()
    local clicked = buttons.IconButton("+")
    assert.assert_false(clicked, "Clicked should be false")
end

function M.testIconButtonWithOptions()
    local clicked = buttons.IconButton("-", { size = 32, tooltip = "Remove" })
    assert.assert_false(clicked, "Clicked should be false")
end

return M
