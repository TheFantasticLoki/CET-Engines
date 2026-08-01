--[[
    Theme Engine Tests — UI-Engine

    Tests for engines/UI-Engine/ui/theme.lua
]]

local assert = require("tests.assert")
local Theme = require("engines.UI-Engine.ui.theme")
local Themes = require("engines.UI-Engine.config.themes")

local M = {}

-- --- Test Initialization ---

function M.testInit()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
        setCurrentTheme = function() end,
        setContrastLevel = function() end,
    }

    Theme.init(mockCore, nil, nil, nil, nil)
    assert.assert_true(true, "Init should not throw")
end

-- --- Test Theme Management ---

function M.testGetTheme()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local theme = Theme.GetTheme()
    assert.assert_equal(theme, "Dark", "GetTheme should return Dark")
end

function M.testGetThemeList()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local list = Theme.GetThemeList()
    assert.assert_not_nil(list, "GetThemeList should return table")
    assert.assert_true(#list >= 16, "Should have at least 16 themes")
end

function M.testGetThemeCategories()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local categories = Theme.GetThemeCategories()
    assert.assert_not_nil(categories, "GetThemeCategories should return table")
    assert.assert_true(#categories >= 3, "Should have at least 3 categories")
end

function M.testSetTheme()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
        setCurrentTheme = function(name) end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local ok, err = Theme.SetTheme("Red")
    assert.assert_true(ok, "SetTheme should succeed for valid theme")
end

function M.testSetThemeInvalid()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
        setCurrentTheme = function(name) end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local ok, err = Theme.SetTheme("NonExistent")
    assert.assert_false(ok, "SetTheme should fail for invalid theme")
end

-- --- Test Validation ---

function M.testValidateTheme()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    assert.assert_true(Theme.ValidateTheme("Dark"), "Dark should be valid")
    assert.assert_true(Theme.ValidateTheme("Red"), "Red should be valid")
    assert.assert_false(Theme.ValidateTheme("NonExistent"), "NonExistent should be invalid")
end

function M.testValidateAccentColor()
    assert.assert_true(Theme.ValidateAccentColor({ r = 0.5, g = 0.5, b = 0.5 }), "Valid accent should pass")
    assert.assert_false(Theme.ValidateAccentColor({ r = 2, g = 0.5, b = 0.5 }), "Out of range should fail")
    assert.assert_false(Theme.ValidateAccentColor(nil), "Nil should fail")
    assert.assert_false(Theme.ValidateAccentColor("string"), "String should fail")
end

-- --- Test Push/Pop Balance ---

function M.testPushPopBalance()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    assert.assert_true(Theme.IsBalanced(), "Should start balanced")
    assert.assert_equal(Theme.GetPushCount(), 0, "Push count should start at 0")
end

-- --- Test Theme Overrides ---

function M.testSetThemeOverride()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    Theme.SetThemeOverride("primary", { r = 1, g = 0, b = 0 })
    -- Should not throw
    assert.assert_true(true, "SetThemeOverride should not throw")
end

function M.testClearThemeOverrides()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    Theme.SetThemeOverride("primary", { r = 1, g = 0, b = 0 })
    Theme.ClearThemeOverrides()
    -- Should not throw
    assert.assert_true(true, "ClearThemeOverrides should not throw")
end

-- --- Test Theme Import/Export ---

function M.testExportTheme()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local exported = Theme.ExportTheme("Dark")
    assert.assert_not_nil(exported, "ExportTheme should return data")
    assert.assert_equal(exported.name, "Dark", "Exported name should be Dark")
    assert.assert_not_nil(exported.accent, "Exported should have accent")
end

function M.testExportThemeInvalid()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    local exported = Theme.ExportTheme("NonExistent")
    assert.assert_nil(exported, "ExportTheme should return nil for invalid theme")
end

-- --- Test High Contrast ---

function M.testSetHighContrast()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
        setContrastLevel = function(level) end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    Theme.SetHighContrast(2)
    -- Should not throw
    assert.assert_true(true, "SetHighContrast should not throw")
end

function M.testSetHighContrastClamp()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
        setContrastLevel = function(level) end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    Theme.SetHighContrast(10) -- Should be clamped to 3
    Theme.SetHighContrast(-5) -- Should be clamped to 1
    -- Should not throw
    assert.assert_true(true, "SetHighContrast clamping should not throw")
end

-- --- Test Cache ---

function M.testInvalidateCache()
    Theme.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }

    Theme.init(mockCore, nil, nil, Themes, nil)

    Theme.InvalidateCache()
    -- Should not throw
    assert.assert_true(true, "InvalidateCache should not throw")
end

return M