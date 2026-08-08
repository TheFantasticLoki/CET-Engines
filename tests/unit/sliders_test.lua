--[[
    Sliders Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/sliders.lua
]]

local assert = require("tests.assert")
local sliders = require("engines.0-Mod-Engine.ui.components.sliders")

local M = {}

-- --- Test SliderFloat ---

function M.testSliderFloat()
    local newValue, changed = sliders.SliderFloat("Value", 0.5, { min = 0, max = 1 })
    assert.assert_equal(newValue, 0.5, "Value should be 0.5")
    assert.assert_false(changed, "Changed should be false")
end

function M.testSliderFloatClamp()
    local newValue, changed = sliders.SliderFloat("Value", 1.5, { min = 0, max = 1 })
    assert.assert_equal(newValue, 1, "Value should be clamped to 1")
end

function M.testSliderFloatWithOptions()
    local newValue, changed = sliders.SliderFloat("Value", 0.5, {
        min = 0, max = 100, format = "%.1f", width = 250, tooltip = "Drag me"
    })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test SliderInt ---

function M.testSliderInt()
    local newValue, changed = sliders.SliderInt("Count", 50, { min = 0, max = 100 })
    assert.assert_equal(newValue, 50, "Value should be 50")
    assert.assert_false(changed, "Changed should be false")
end

function M.testSliderIntClamp()
    local newValue, changed = sliders.SliderInt("Count", 150, { min = 0, max = 100 })
    assert.assert_equal(newValue, 100, "Value should be clamped to 100")
end

-- --- Test DragInt ---

function M.testDragInt()
    local newValue, changed = sliders.DragInt("Value", 5, { min = 0, max = 100 })
    assert.assert_equal(newValue, 5, "Value should be 5")
    assert.assert_false(changed, "Changed should be false")
end

function M.testDragIntWithOptions()
    local newValue, changed = sliders.DragInt("Value", 10, {
        min = -50, max = 50, speed = 5, width = 150
    })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test DragFloat ---

function M.testDragFloat()
    local newValue, changed = sliders.DragFloat("Value", 1.5, { min = 0, max = 10 })
    assert.assert_equal(newValue, 1.5, "Value should be 1.5")
    assert.assert_false(changed, "Changed should be false")
end

function M.testDragFloatWithOptions()
    local newValue, changed = sliders.DragFloat("Value", 0.5, {
        min = -1, max = 1, speed = 0.1, format = "%.2f", width = 200
    })
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test StepSlider ---

function M.testStepSlider()
    local newValue, changed = sliders.StepSlider("Level", 5, { min = 0, max = 10, step = 1 })
    assert.assert_equal(newValue, 5, "Value should be 5")
    assert.assert_false(changed, "Changed should be false")
end

function M.testStepSliderClamp()
    local newValue, changed = sliders.StepSlider("Level", 15, { min = 0, max = 10, step = 1 })
    assert.assert_equal(newValue, 10, "Value should be clamped to 10")
end

-- --- Test ColorPicker ---

function M.testColorPicker()
    local newColor, changed = sliders.ColorPicker("Color", { r = 1, g = 0, b = 0, a = 1 })
    assert.assert_equal(newColor.r, 1, "Red should be 1")
    assert.assert_equal(newColor.g, 0, "Green should be 0")
    assert.assert_equal(newColor.b, 0, "Blue should be 0")
    assert.assert_false(changed, "Changed should be false")
end

function M.testColorPickerNil()
    local newColor, changed = sliders.ColorPicker("Color", nil)
    assert.assert_not_nil(newColor, "Color should not be nil")
    assert.assert_false(changed, "Changed should be false")
end

function M.testColorPickerWithOptions()
    local newColor, changed = sliders.ColorPicker("Color", { r = 0, g = 0, b = 1, a = 1 }, {
        tooltip = "Pick a color", width = 200
    })
    assert.assert_false(changed, "Changed should be false")
end

return M
