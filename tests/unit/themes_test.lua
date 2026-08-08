--[[
    Theme Definitions Tests — UI-Engine

    Tests for engines/UI-Engine/config/themes.lua
]]

local assert = require("tests.assert")
local Themes = require("engines.0-Mod-Engine.config.themes")

local M = {}

-- --- Test Theme Definitions ---

function M.testThemeCount()
    local count = 0
    for _ in pairs(Themes.THEMES) do
        count = count + 1
    end
    assert.assert_equal(count, 16, "Should have 16 themes")
end

function M.testThemeOrder()
    assert.assert_equal(#Themes.THEME_ORDER, 16, "Theme order should have 16 entries")
    assert.assert_equal(Themes.THEME_ORDER[1], "Dark", "First theme should be Dark")
end

function M.testThemeCategories()
    assert.assert_not_nil(Themes.THEME_CATEGORIES, "Theme categories should exist")
    assert.assert_true(#Themes.THEME_CATEGORIES >= 3, "Should have at least 3 categories")
end

function M.testThemeAccentColors()
    for name, theme in pairs(Themes.THEMES) do
        assert.assert_not_nil(theme.accent, "Theme " .. name .. " should have accent")
        assert.assert_true(type(theme.accent.r) == "number", "Theme " .. name .. " accent.r should be number")
        assert.assert_true(type(theme.accent.g) == "number", "Theme " .. name .. " accent.g should be number")
        assert.assert_true(type(theme.accent.b) == "number", "Theme " .. name .. " accent.b should be number")
        assert.assert_true(theme.accent.r >= 0 and theme.accent.r <= 1, "Theme " .. name .. " accent.r should be 0-1")
        assert.assert_true(theme.accent.g >= 0 and theme.accent.g <= 1, "Theme " .. name .. " accent.g should be 0-1")
        assert.assert_true(theme.accent.b >= 0 and theme.accent.b <= 1, "Theme " .. name .. " accent.b should be 0-1")
    end
end

function M.testThemeRoles()
    for name, theme in pairs(Themes.THEMES) do
        assert.assert_not_nil(theme.roles, "Theme " .. name .. " should have roles")
        assert.assert_not_nil(theme.roles.background, "Theme " .. name .. " should have background role")
        assert.assert_not_nil(theme.roles.panel, "Theme " .. name .. " should have panel role")
        assert.assert_not_nil(theme.roles.primary, "Theme " .. name .. " should have primary role")
        assert.assert_not_nil(theme.roles.text, "Theme " .. name .. " should have text role")
        assert.assert_not_nil(theme.roles.muted, "Theme " .. name .. " should have muted role")
    end
end

-- --- Test Helper Functions ---

function M.testGetTheme()
    local theme = Themes.getTheme("Dark")
    assert.assert_not_nil(theme, "getTheme should return theme")
    assert.assert_equal(theme.accent.r, 0.4, "Dark accent.r should be 0.4")
end

function M.testGetThemeNames()
    local names = Themes.getThemeNames()
    assert.assert_not_nil(names, "getThemeNames should return table")
    assert.assert_equal(#names, 16, "Should have 16 theme names")
end

function M.testGetThemeCategories()
    local categories = Themes.getThemeCategories()
    assert.assert_not_nil(categories, "getThemeCategories should return table")
    assert.assert_true(#categories >= 3, "Should have at least 3 categories")
end

function M.testGetRole()
    local role = Themes.getRole("Dark", "primary")
    assert.assert_not_nil(role, "getRole should return role")
    assert.assert_equal(role.r, 0.4, "Dark primary.r should be 0.4")
end

function M.testGetAccent()
    local accent = Themes.getAccent("Dark")
    assert.assert_not_nil(accent, "getAccent should return accent")
    assert.assert_equal(accent.r, 0.4, "Dark accent.r should be 0.4")
end

function M.testGetBaseStyleVars()
    local vars = Themes.getBaseStyleVars()
    assert.assert_not_nil(vars, "getBaseStyleVars should return table")
    assert.assert_equal(vars.WindowRounding, 10.0, "WindowRounding should be 10.0")
    assert.assert_equal(vars.ChildRounding, 8.0, "ChildRounding should be 8.0")
end

function M.testGetRoles()
    local roles = Themes.getRoles()
    assert.assert_not_nil(roles, "getRoles should return table")
    assert.assert_true(#roles >= 10, "Should have at least 10 roles")
end

-- --- Test Invalid Theme ---

function M.testInvalidTheme()
    local theme = Themes.getTheme("NonExistent")
    assert.assert_nil(theme, "getTheme should return nil for invalid theme")
end

return M