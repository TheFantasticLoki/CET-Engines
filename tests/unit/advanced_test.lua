--[[
    Advanced Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/advanced.lua
]]

local assert = require("tests.assert")
local advanced = require("engines.0-Mod-Engine.ui.components.advanced")

local M = {}

-- --- Setup ---

-- Mock Theme
local mockTheme = {
    currentTheme = "Dark",
    SetTheme = function(self, name)
        self.currentTheme = name
    end,
}

-- Mock Logger
local mockLog = {
    info = function(self, msg) end,
    debug = function(self, msg) end,
    warn = function(self, msg) end,
    error = function(self, msg) end,
}

-- --- Test Init ---

function M.testInit()
    advanced.init(mockTheme, mockLog)
    assert.assert_true(true, "Init should not throw")
end

-- --- Test AdvancedSlider ---

function M.testAdvancedSlider()
    advanced.init(mockTheme, mockLog)
    local newValue, changed = advanced.AdvancedSlider({
        label = "Value",
        value = 50,
        min = 0,
        max = 100,
        step = 5,
    })
    assert.assert_equal(newValue, 50, "Value should be 50")
    assert.assert_false(changed, "Changed should be false")
end

function M.testAdvancedSliderClamp()
    advanced.init(mockTheme, mockLog)
    local newValue, changed = advanced.AdvancedSlider({
        label = "Value",
        value = 150,
        min = 0,
        max = 100,
    })
    assert.assert_equal(newValue, 100, "Value should be clamped to 100")
end

function M.testAdvancedSliderCallback()
    advanced.init(mockTheme, mockLog)
    local called = false
    local newValue, changed = advanced.AdvancedSlider({
        label = "Value",
        value = 25,
        min = 0,
        max = 100,
        onChange = function(v) called = true end,
    })
    assert.assert_false(called, "Callback should not be called without change")
end

-- --- Test ThemeDropdown ---

function M.testThemeDropdown()
    advanced.init(mockTheme, mockLog)
    local newTheme, changed = advanced.ThemeDropdown(
        "Theme", "Dark", { "Dark", "Red", "Cyan", "Blue" })
    assert.assert_equal(newTheme, "Dark", "Theme should remain Dark")
    assert.assert_false(changed, "Changed should be false")
end

function M.testThemeDropdownCallback()
    advanced.init(mockTheme, mockLog)
    local callbackTheme = nil
    local newTheme, changed = advanced.ThemeDropdown(
        "Theme", "Dark", { "Dark", "Red" }, function(t)
            callbackTheme = t
        end)
    assert.assert_false(changed, "Changed should be false")
end

-- --- Test ComboBox ---

function M.testComboBox()
    advanced.init(mockTheme, mockLog)
    local newIndex, changed = advanced.ComboBox(
        "Select", { "A", "B", "C" }, 1)
    assert.assert_equal(newIndex, 1, "Index should be 1")
    assert.assert_false(changed, "Changed should be false")
end

function M.testComboBoxCallback()
    advanced.init(mockTheme, mockLog)
    local callbackIndex, callbackLabel = nil, nil
    local newIndex, changed = advanced.ComboBox(
        "Select", { "One", "Two" }, 1, function(i, l)
            callbackIndex, callbackLabel = i, l
        end)
    assert.assert_false(changed, "Changed should be false")
end

return M
