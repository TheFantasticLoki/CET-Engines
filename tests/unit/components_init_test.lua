--[[
    Components Init Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/init.lua (barrel re-export)
]]

local assert = require("tests.assert")
local Components = require("engines.UI-Engine.ui.components")

local M = {}

-- --- Test All Components Accessible ---

function M.testAllComponentsAccessible()
    -- Primitives
    assert.assert_not_nil(Components.ClipboardCopy, "ClipboardCopy should be accessible")
    assert.assert_not_nil(Components.SafeSelectable, "SafeSelectable should be accessible")
    assert.assert_not_nil(Components.ContextMenu, "ContextMenu should be accessible")
    assert.assert_not_nil(Components.SelectableEntry, "SelectableEntry should be accessible")

    -- Buttons
    assert.assert_not_nil(Components.Button, "Button should be accessible")
    assert.assert_not_nil(Components.ToggleButton, "ToggleButton should be accessible")
    assert.assert_not_nil(Components.IconButton, "IconButton should be accessible")

    -- Display
    assert.assert_not_nil(Components.Text, "Text should be accessible")
    assert.assert_not_nil(Components.TextColored, "TextColored should be accessible")
    assert.assert_not_nil(Components.TextWrapped, "TextWrapped should be accessible")
    assert.assert_not_nil(Components.TextDisabled, "TextDisabled should be accessible")
    assert.assert_not_nil(Components.StatusBadge, "StatusBadge should be accessible")
    assert.assert_not_nil(Components.InfoRow, "InfoRow should be accessible")
    assert.assert_not_nil(Components.Banner, "Banner should be accessible")
    assert.assert_not_nil(Components.ProgressBar, "ProgressBar should be accessible")
    assert.assert_not_nil(Components.Plot, "Plot should be accessible")
    assert.assert_not_nil(Components.Histogram, "Histogram should be accessible")
    assert.assert_not_nil(Components.Notification, "Notification should be accessible")
    assert.assert_not_nil(Components.RenderNotifications, "RenderNotifications should be accessible")

    -- Layout
    assert.assert_not_nil(Components.RowLabel, "RowLabel should be accessible")
    assert.assert_not_nil(Components.Separator, "Separator should be accessible")
    assert.assert_not_nil(Components.Spacing, "Spacing should be accessible")
    assert.assert_not_nil(Components.Indent, "Indent should be accessible")
    assert.assert_not_nil(Components.Columns, "Columns should be accessible")
    assert.assert_not_nil(Components.ScrollableRegion, "ScrollableRegion should be accessible")

    -- Inputs
    assert.assert_not_nil(Components.Checkbox, "Checkbox should be accessible")
    assert.assert_not_nil(Components.RadioButton, "RadioButton should be accessible")
    assert.assert_not_nil(Components.InputText, "InputText should be accessible")
    assert.assert_not_nil(Components.InputInt, "InputInt should be accessible")
    assert.assert_not_nil(Components.InputFloat, "InputFloat should be accessible")
    assert.assert_not_nil(Components.KeyBind, "KeyBind should be accessible")

    -- Sliders
    assert.assert_not_nil(Components.SliderFloat, "SliderFloat should be accessible")
    assert.assert_not_nil(Components.SliderInt, "SliderInt should be accessible")
    assert.assert_not_nil(Components.DragInt, "DragInt should be accessible")
    assert.assert_not_nil(Components.DragFloat, "DragFloat should be accessible")
    assert.assert_not_nil(Components.StepSlider, "StepSlider should be accessible")
    assert.assert_not_nil(Components.ColorPicker, "ColorPicker should be accessible")

    -- Containers
    assert.assert_not_nil(Components.CollapsingSection, "CollapsingSection should be accessible")
    assert.assert_not_nil(Components.TreeNode, "TreeNode should be accessible")
    assert.assert_not_nil(Components.CustomTreeNode, "CustomTreeNode should be accessible")

    -- Advanced
    assert.assert_not_nil(Components.AdvancedSlider, "AdvancedSlider should be accessible")
    assert.assert_not_nil(Components.ThemeDropdown, "ThemeDropdown should be accessible")
    assert.assert_not_nil(Components.ComboBox, "ComboBox should be accessible")

    -- Compose
    assert.assert_not_nil(Components.Row, "Row should be accessible")
    assert.assert_not_nil(Components.Column, "Column should be accessible")
    assert.assert_not_nil(Components.Stack, "Stack should be accessible")
    assert.assert_not_nil(Components.Flex, "Flex should be accessible")
    assert.assert_not_nil(Components.Box, "Box should be accessible")
    assert.assert_not_nil(Components.Padded, "Padded should be accessible")
    assert.assert_not_nil(Components.Centered, "Centered should be accessible")
    assert.assert_not_nil(Components.Spacer, "Spacer should be accessible")
    assert.assert_not_nil(Components.Divider, "Divider should be accessible")
    assert.assert_not_nil(Components.ErrorBoundary, "ErrorBoundary should be accessible")
    assert.assert_not_nil(Components.GetAvailableSpace, "GetAvailableSpace should be accessible")

    -- Console
    assert.assert_not_nil(Components.ConsoleOutput, "ConsoleOutput should be accessible")
    assert.assert_not_nil(Components.RichInput, "RichInput should be accessible")
    assert.assert_not_nil(Components.ConsoleToolbar, "ConsoleToolbar should be accessible")

    -- Tables
    assert.assert_not_nil(Components.BeginTable, "BeginTable should be accessible")
    assert.assert_not_nil(Components.EndTable, "EndTable should be accessible")
    assert.assert_not_nil(Components.TableRow, "TableRow should be accessible")

    -- Icons
    assert.assert_not_nil(Components.GetIcon, "GetIcon should be accessible")
    assert.assert_not_nil(Components.DrawCenteredText, "DrawCenteredText should be accessible")
end

-- --- Test Component Count ---

function M.testComponentCount()
    local count = 0
    for k, v in pairs(Components) do
        if type(v) == "function" then
            count = count + 1
        end
    end
    assert.assert_true(count >= 50, "Should have at least 50 component functions")
end

-- --- Test Init ---

function M.testInit()
    -- Should not throw even with nil dependencies
    Components.init(nil, nil, nil)
    assert.assert_true(true, "Init with nil deps should not throw")
end

return M
