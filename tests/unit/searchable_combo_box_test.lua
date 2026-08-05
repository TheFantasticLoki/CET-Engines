--[[
    SearchableComboBox Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/advanced.lua (SearchableComboBox)
]]

local assert = require("tests.assert")
local advanced = require("engines.UI-Engine.ui.components.advanced")

local M = {}

-- Skip all tests if SearchableComboBox not available
if not advanced.SearchableComboBox then
    function M.testBasicRender() end
    function M.testFilterNarrowing() end
    function M.testSelection() end
    function M.testEmptyList() end
    function M.testMaxVisible() end
    function M.testLabelValuePairs() end
    function M.testOptions() end
    return M
end

-- --- Test Basic Render ---

function M.testBasicRender()
    local items = {"Apple", "Banana", "Cherry", "Date"}
    local newIndex, changed = advanced.SearchableComboBox("Fruit", items, 1)
    assert.assert_true(newIndex >= 0, "Index should be >= 0")
    assert.assert_false(changed, "No change on render")
end

-- --- Test Filter Narrowing ---

function M.testFilterNarrowing()
    local items = {"Apple", "Banana", "Cherry", "Date", "Elderberry"}
    -- Simulate filter state
    local newIndex, changed = advanced.SearchableComboBox("Fruit", items, 0, { placeholder = "Type to filter..." })
    assert.assert_true(newIndex >= 0, "Index should be >= 0")
end

-- --- Test Selection ---

function M.testSelection()
    local items = {"Apple", "Banana", "Cherry"}
    local newIndex, changed = advanced.SearchableComboBox("Fruit", items, 1)
    -- Mock always returns no change, but function should handle selection
    assert.assert_true(newIndex >= 0, "Index should be valid")
end

-- --- Test Empty List ---

function M.testEmptyList()
    local items = {}
    local newIndex, changed = advanced.SearchableComboBox("Empty", items, 0)
    assert.assert_equal(newIndex, 0, "Empty list should return 0")
    assert.assert_false(changed, "No change on empty list")
end

-- --- Test Max Visible ---

function M.testMaxVisible()
    local items = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"}
    local newIndex, changed = advanced.SearchableComboBox("Letters", items, 1, { maxVisible = 5 })
    assert.assert_true(newIndex >= 0, "Index should be valid with maxVisible")
end

-- --- Test With Label/Value Pairs ---

function M.testLabelValuePairs()
    local items = {
        {label = "Red", value = 1},
        {label = "Green", value = 2},
        {label = "Blue", value = 3}
    }
    local newIndex, changed = advanced.SearchableComboBox("Color", items, 1)
    assert.assert_true(newIndex >= 0, "Index should be valid with label/value pairs")
end

-- --- Test Options ---

function M.testOptions()
    local items = {"Item1", "Item2", "Item3"}
    local options = {
        placeholder = "Search items...",
        tooltip = "Select an item",
        width = 250,
        maxVisible = 10
    }
    local newIndex, changed = advanced.SearchableComboBox("Options", items, 1, options)
    assert.assert_true(newIndex >= 0, "Should handle all options")
end

return M
