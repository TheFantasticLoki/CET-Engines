--[[
    Inputs Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/inputs.lua
]]

local assert = require("tests.assert")
local inputs = require("engines.UI-Engine.ui.components.inputs")

local M = {}

-- --- Test Checkbox ---

function M.testCheckbox()
    local newValue, changed = inputs.Checkbox("Enable", false)
    assert.assert_false(newValue, "Value should be false")
    assert.assert_false(changed, "Changed should be false")
end

function M.testCheckboxChecked()
    local newValue, changed = inputs.Checkbox("Enable", true)
    assert.assert_true(newValue, "Value should be true")
    assert.assert_false(changed, "Changed should be false")
end

function M.testCheckboxTooltip()
    local newValue, changed = inputs.Checkbox("Enable", false, { tooltip = "Toggle feature" })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test RadioButton ---

function M.testRadioButton()
    local clicked, active = inputs.RadioButton("Option 1", true)
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_true(active, "Active should be true")
end

function M.testRadioButtonInactive()
    local clicked, active = inputs.RadioButton("Option 2", false)
    assert.assert_false(clicked, "Clicked should be false")
    assert.assert_false(active, "Active should be false")
end

-- --- Test InputText ---

function M.testInputText()
    local newValue, changed = inputs.InputText("Name", "default")
    assert.assert_equal(newValue, "default", "Value should be unchanged")
    assert.assert_false(changed, "Changed should be false")
end

function M.testInputTextWithPlaceholder()
    local newValue, changed = inputs.InputText("Name", "", { placeholder = "Enter name..." })
    assert.assert_equal(newValue, "", "Value should be empty")
    assert.assert_false(changed, "Changed should be false")
end

function M.testInputTextWithOptions()
    local newValue, changed = inputs.InputText("Email", "test@test.com", {
        placeholder = "email@example.com",
        tooltip = "Enter your email",
        width = 250,
    })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test InputInt ---

function M.testInputInt()
    local newValue, changed = inputs.InputInt("Count", 5)
    assert.assert_equal(newValue, 5, "Value should be 5")
    assert.assert_false(changed, "Changed should be false")
end

function M.testInputIntWithOptions()
    local newValue, changed = inputs.InputInt("Count", 10, { step = 5, stepFast = 20, width = 150 })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test InputFloat ---

function M.testInputFloat()
    local newValue, changed = inputs.InputFloat("Value", 3.14)
    assert.assert_equal(newValue, 3.14, "Value should be 3.14")
    assert.assert_false(changed, "Changed should be false")
end

function M.testInputFloatWithOptions()
    local newValue, changed = inputs.InputFloat("Value", 1.0, {
        step = 0.5,
        stepFast = 5.0,
        format = "%.1f",
        width = 100,
    })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test KeyBind ---

function M.testKeyBind()
    local newKey, changed = inputs.KeyBind("Hotkey", "F1")
    assert.assert_equal(newKey, "F1", "Key should be F1")
    assert.assert_false(changed, "Changed should be false")
end

function M.testKeyBindNone()
    local newKey, changed = inputs.KeyBind("Hotkey", "None")
    assert.assert_equal(newKey, "None", "Key should be None")
    assert.assert_false(changed, "Changed should be false")
end

return M
