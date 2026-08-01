--[[
    Design Tokens Tests — UI-Engine

    Tests for engines/UI-Engine/ui/tokens.lua
]]

local assert = require("tests.assert")
local Tokens = require("engines.UI-Engine.ui.tokens")

local M = {}

-- --- Test Static Tokens ---

function M.testSpacingScale()
    assert.assert_equal(Tokens.SPACING.xs, 2, "xs spacing should be 2")
    assert.assert_equal(Tokens.SPACING.sm, 4, "sm spacing should be 4")
    assert.assert_equal(Tokens.SPACING.md, 8, "md spacing should be 8")
    assert.assert_equal(Tokens.SPACING.lg, 12, "lg spacing should be 12")
    assert.assert_equal(Tokens.SPACING.xl, 16, "xl spacing should be 16")
    assert.assert_equal(Tokens.SPACING.xxl, 24, "xxl spacing should be 24")
end

function M.testSizingConstants()
    assert.assert_not_nil(Tokens.SIZING.button, "Button sizing should exist")
    assert.assert_equal(Tokens.SIZING.button.width, 80, "Button width should be 80")
    assert.assert_equal(Tokens.SIZING.button.height, 28, "Button height should be 28")

    assert.assert_not_nil(Tokens.SIZING.slider, "Slider sizing should exist")
    assert.assert_not_nil(Tokens.SIZING.input, "Input sizing should exist")
    assert.assert_not_nil(Tokens.SIZING.badge, "Badge sizing should exist")
    assert.assert_not_nil(Tokens.SIZING.toggle, "Toggle sizing should exist")
end

function M.testBorderRadii()
    assert.assert_equal(Tokens.BORDER_RADIUS.sm, 4, "sm border radius should be 4")
    assert.assert_equal(Tokens.BORDER_RADIUS.md, 6, "md border radius should be 6")
    assert.assert_equal(Tokens.BORDER_RADIUS.lg, 8, "lg border radius should be 8")
    assert.assert_equal(Tokens.BORDER_RADIUS.xl, 10, "xl border radius should be 10")
end

function M.testTextSizes()
    assert.assert_equal(Tokens.TEXT_SIZE.xs, 10, "xs text size should be 10")
    assert.assert_equal(Tokens.TEXT_SIZE.sm, 12, "sm text size should be 12")
    assert.assert_equal(Tokens.TEXT_SIZE.md, 14, "md text size should be 14")
    assert.assert_equal(Tokens.TEXT_SIZE.lg, 16, "lg text size should be 16")
    assert.assert_equal(Tokens.TEXT_SIZE.xl, 18, "xl text size should be 18")
end

-- --- Test Dynamic Tokens ---

function M.testColor4n()
    Tokens.reset()
    -- Set up mock dependencies
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }
    local mockThemes = {
        getTheme = function(name)
            return {
                accent = { r = 0.4, g = 0.6, b = 1.0 },
                roles = {
                    primary = { r = 0.4, g = 0.6, b = 1.0 },
                    text = { r = 1.0, g = 1.0, b = 1.0 },
                },
            }
        end,
        getBaseStyleVars = function() return {} end,
    }

    Tokens.init(mockCore, nil, mockThemes)

    local primary = Tokens.color4n("primary")
    assert.assert_not_nil(primary, "color4n should return color")
    assert.assert_true(math.abs(primary.r - 0.4) < 0.01, "Primary r should be ~0.4")
    assert.assert_true(math.abs(primary.g - 0.6) < 0.01, "Primary g should be ~0.6")
    assert.assert_true(math.abs(primary.b - 1.0) < 0.01, "Primary b should be ~1.0")
end

function M.testColor4()
    Tokens.reset()
    local mockCore = {
        getCurrentTheme = function() return "Dark" end,
        getAccentColor = function() return { r = 0.4, g = 0.6, b = 1.0 } end,
        getContrastLevel = function() return 1 end,
    }
    local mockThemes = {
        getTheme = function(name)
            return {
                accent = { r = 0.4, g = 0.6, b = 1.0 },
                roles = {
                    primary = { r = 0.4, g = 0.6, b = 1.0 },
                },
            }
        end,
        getBaseStyleVars = function() return {} end,
    }

    Tokens.init(mockCore, nil, mockThemes)

    local primary = Tokens.color4("primary")
    assert.assert_not_nil(primary, "color4 should return color")
    assert.assert_nil(primary.a, "color4 should not have alpha")
end

function M.testInvalidateCache()
    Tokens.invalidateCache()
    -- Should not throw
    assert.assert_true(true, "invalidateCache should not throw")
end

function M.testStyleVar()
    Tokens.reset()
    local mockThemes = {
        getBaseStyleVars = function()
            return { WindowRounding = 10.0, ChildRounding = 8.0 }
        end,
    }

    Tokens.init(nil, nil, mockThemes)

    local var = Tokens.styleVar("WindowRounding")
    assert.assert_equal(var, 10.0, "WindowRounding should be 10.0")
end

function M.testStyleVarVec2()
    Tokens.reset()
    local mockThemes = {
        getBaseStyleVars = function()
            return { WindowPadding = { x = 12.0, y = 8.0 } }
        end,
    }

    Tokens.init(nil, nil, mockThemes)

    local x, y = Tokens.styleVarVec2("WindowPadding")
    assert.assert_equal(x, 12.0, "WindowPadding x should be 12.0")
    assert.assert_equal(y, 8.0, "WindowPadding y should be 8.0")
end

return M