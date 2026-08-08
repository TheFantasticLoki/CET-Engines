--[[
    Layout Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/layout.lua
]]

local assert = require("tests.assert")
local layout = require("engines.0-Mod-Engine.ui.components.layout")

local M = {}

-- --- Test RowLabel ---

function M.testRowLabel()
    layout.RowLabel("Label", "Value")
    assert.assert_true(true, "RowLabel should not throw")
end

function M.testRowLabelWithOptions()
    layout.RowLabel("Label", "Value", { labelWidth = 150 })
    assert.assert_true(true, "RowLabel with options should not throw")
end

function M.testRowLabelEmpty()
    layout.RowLabel("", "")
    assert.assert_true(true, "RowLabel with empty strings should not throw")
end

-- --- Test Separator ---

function M.testSeparator()
    layout.Separator()
    assert.assert_true(true, "Separator should not throw")
end

function M.testSeparatorLabeled()
    layout.Separator("Section")
    assert.assert_true(true, "Separator with label should not throw")
end

-- --- Test Spacing ---

function M.testSpacing()
    layout.Spacing()
    assert.assert_true(true, "Spacing should not throw")
end

function M.testSpacingCustom()
    layout.Spacing(16)
    assert.assert_true(true, "Spacing with custom size should not throw")
end

-- --- Test Indent ---

function M.testIndent()
    layout.Indent()
    assert.assert_true(true, "Indent should not throw")
end

function M.testIndentCustom()
    layout.Indent(32)
    assert.assert_true(true, "Indent with custom depth should not throw")
end

-- --- Test Unindent ---

function M.testUnindent()
    layout.Unindent()
    assert.assert_true(true, "Unindent should not throw")
end

-- --- Test Columns ---

function M.testColumns()
    layout.Columns(2, nil, function()
        ImGui.Text("Col 1")
        ImGui.NextColumn()
        ImGui.Text("Col 2")
    end)
    assert.assert_true(true, "Columns should not throw")
end

function M.testColumnsWithOptions()
    layout.Columns(3, { 100, 200, 300 }, function()
        ImGui.Text("A")
        ImGui.NextColumn()
        ImGui.Text("B")
        ImGui.NextColumn()
        ImGui.Text("C")
    end)
    assert.assert_true(true, "Columns with widths should not throw")
end

-- --- Test ScrollableRegion ---

function M.testScrollableRegion()
    layout.ScrollableRegion(150, function()
        ImGui.Text("Content 1")
        ImGui.Text("Content 2")
    end)
    assert.assert_true(true, "ScrollableRegion should not throw")
end

function M.testScrollableRegionEmpty()
    layout.ScrollableRegion(100, nil)
    assert.assert_true(true, "ScrollableRegion with nil buildFn should not throw")
end

return M
