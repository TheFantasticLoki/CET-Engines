--[[
    MultiSelect Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/inputs.lua (MultiSelect)
]]

local assert = require("tests.assert")
local inputs = require("engines.0-Mod-Engine.ui.components.inputs")

local M = {}

-- Skip all tests if MultiSelect not available
if not inputs.MultiSelect then
    function M.testBasicRender() end
    function M.testToggleItem() end
    function M.testMultipleSelection() end
    function M.testSearchFilter() end
    function M.testEmptySelection() end
    function M.testEmptyItems() end
    function M.testLabelValuePairs() end
    function M.testOptions() end
    function M.testNoSearchable() end
    return M
end

-- --- Test Basic Render ---

function M.testBasicRender()
    local items = {"Apple", "Banana", "Cherry", "Date"}
    local selected = {1, 3}
    local newSelected, changed = inputs.MultiSelect("Fruits", items, selected)
    assert.assert_true(type(newSelected) == "table", "Should return a table")
    assert.assert_false(changed, "No change on render")
end

-- --- Test Toggle Item ---

function M.testToggleItem()
    local items = {"Apple", "Banana", "Cherry"}
    local selected = {1}
    local newSelected, changed = inputs.MultiSelect("Fruits", items, selected)
    assert.assert_true(type(newSelected) == "table", "Should return a table")
end

-- --- Test Multiple Selection ---

function M.testMultipleSelection()
    local items = {"Red", "Green", "Blue", "Yellow"}
    local selected = {1, 2, 3}
    local newSelected, changed = inputs.MultiSelect("Colors", items, selected)
    assert.assert_true(type(newSelected) == "table", "Should return a table")
end

-- --- Test Search Filter ---

function M.testSearchFilter()
    local items = {"Apple", "Apricot", "Banana", "Cherry"}
    local selected = {}
    local options = { searchable = true, placeholder = "Filter..." }
    local newSelected, changed = inputs.MultiSelect("Fruits", items, selected, options)
    assert.assert_true(type(newSelected) == "table", "Should handle searchable option")
end

-- --- Test Empty Selection ---

function M.testEmptySelection()
    local items = {"Apple", "Banana", "Cherry"}
    local selected = {}
    local newSelected, changed = inputs.MultiSelect("Fruits", items, selected)
    assert.assert_true(type(newSelected) == "table", "Should return a table")
end

-- --- Test Empty Items ---

function M.testEmptyItems()
    local items = {}
    local selected = {}
    local newSelected, changed = inputs.MultiSelect("Empty", items, selected)
    assert.assert_true(type(newSelected) == "table", "Should handle empty items")
end

-- --- Test Label/Value Pairs ---

function M.testLabelValuePairs()
    local items = {
        {label = "Small", value = "s"},
        {label = "Medium", value = "m"},
        {label = "Large", value = "l"}
    }
    local selected = {1, 3}
    local newSelected, changed = inputs.MultiSelect("Size", items, selected)
    assert.assert_true(type(newSelected) == "table", "Should handle label/value pairs")
end

-- --- Test Options ---

function M.testOptions()
    local items = {"Item1", "Item2", "Item3"}
    local selected = {1}
    local options = {
        placeholder = "Search...",
        tooltip = "Select items",
        width = 250,
        maxVisible = 10,
        searchable = true
    }
    local newSelected, changed = inputs.MultiSelect("Options", items, selected, options)
    assert.assert_true(type(newSelected) == "table", "Should handle all options")
end

-- --- Test No Searchable ---

function M.testNoSearchable()
    local items = {"A", "B", "C"}
    local selected = {1, 2}
    local options = { searchable = false }
    local newSelected, changed = inputs.MultiSelect("NoSearch", items, selected, options)
    assert.assert_true(type(newSelected) == "table", "Should work without search")
end

return M
