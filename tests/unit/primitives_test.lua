--[[
    Primitives Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/primitives.lua
]]

local assert = require("tests.assert")
local primitives = require("engines.UI-Engine.ui.components.primitives")

local M = {}

-- --- Test ClipboardCopy ---

function M.testClipboardCopy()
    -- Should not throw
    primitives.ClipboardCopy("test text")
    assert.assert_true(true, "ClipboardCopy should not throw")
end

function M.testClipboardCopyNil()
    -- Should handle nil gracefully
    primitives.ClipboardCopy(nil)
    assert.assert_true(true, "ClipboardCopy with nil should not throw")
end

-- --- Test SafeSelectable ---

function M.testSafeSelectable()
    local clicked, selected = primitives.SafeSelectable("Test", false)
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_false(selected, "Selected should be false")
end

function M.testSafeSelectableSelected()
    local clicked, selected = primitives.SafeSelectable("Test", true)
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_true(selected, "Selected should be true")
end

function M.testSafeSelectableEmptyLabel()
    local clicked, selected = primitives.SafeSelectable("", false)
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_false(selected, "Selected should be false")
end

-- --- Test ContextMenu ---

function M.testContextMenu()
    -- Should not throw
    primitives.ContextMenu("test_menu", function()
        ImGui.MenuItem("Test")
    end)
    assert.assert_true(true, "ContextMenu should not throw")
end

function M.testContextMenuNoBuildFn()
    -- Should handle nil buildFn
    primitives.ContextMenu("test_menu", nil)
    assert.assert_true(true, "ContextMenu with nil buildFn should not throw")
end

-- --- Test SelectableEntry ---

function M.testSelectableEntry()
    local clicked, selected = primitives.SelectableEntry("Test", false, nil)
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_false(selected, "Selected should be false")
end

function M.testSelectableEntryWithTooltip()
    local clicked, selected = primitives.SelectableEntry("Test", false, "This is a tooltip")
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_false(selected, "Selected should be false")
end

return M
