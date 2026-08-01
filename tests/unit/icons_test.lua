--[[
    Icons Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/icons.lua
]]

local assert = require("tests.assert")
local icons = require("engines.UI-Engine.ui.components.icons")

local M = {}

-- --- Test GetIcon ---

function M.testGetIcon()
    local icon = icons.GetIcon("check")
    assert.assert_equal(icon, "✓", "Check icon should be ✓")
end

function M.testGetIconNotFound()
    local icon = icons.GetIcon("nonexistent")
    assert.assert_equal(icon, "", "Unknown icon should be empty string")
end

function M.testGetIconNil()
    local icon = icons.GetIcon(nil)
    assert.assert_equal(icon, "", "Nil icon name should return empty string")
end

function M.testGetIconAll()
    -- Test all built-in icons exist
    local iconNames = icons.GetIconNames()
    assert.assert_true(#iconNames > 0, "Should have icons")
end

-- --- Test RegisterIcon ---

function M.testRegisterIcon()
    icons.RegisterIcon("custom_icon", "★")
    local icon = icons.GetIcon("custom_icon")
    assert.assert_equal(icon, "★", "Custom icon should be ★")
end

-- --- Test GetIconNames ---

function M.testGetIconNames()
    local names = icons.GetIconNames()
    assert.assert_not_nil(names, "Icon names should not be nil")
    assert.assert_true(type(names) == "table", "Icon names should be a table")
    assert.assert_true(#names > 0, "Should have at least one icon")
end

-- --- Test DrawCenteredText ---

function M.testDrawCenteredText()
    icons.DrawCenteredText("Centered", nil, nil)
    assert.assert_true(true, "DrawCenteredText should not throw")
end

function M.testDrawCenteredTextWithOptions()
    icons.DrawCenteredText("Centered", 16, { r = 1, g = 0, b = 0 })
    assert.assert_true(true, "DrawCenteredText with options should not throw")
end

function M.testDrawCenteredTextEmpty()
    icons.DrawCenteredText("", nil, nil)
    assert.assert_true(true, "DrawCenteredText with empty text should not throw")
end

return M
