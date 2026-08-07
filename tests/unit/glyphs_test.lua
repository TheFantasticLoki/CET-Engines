--[[
    Glyphs Tests — UI-Engine

    Tests for engines/0-Mod-Engine/ui/components/glyphs.lua
]]

local assert = require("tests.assert")

-- Mock IconGlyphs global for testing
IconGlyphs = {
    Palette = "🎨",
    Star = "⭐",
    Check = "✓",
}

-- Mock ImGui API
ImGui = {
    GetWindowDrawList = function() return {} end,
    GetItemRectMin = function() return 100, 100 end,
    GetItemRectMax = function() return 130, 130 end,
    ImDrawListAddText = function() end,
    GetColorU32 = function(r, g, b, a) return 0 end,
    GetFontSize = function() return 14 end,
    Button = function() return false end,
    IsItemHovered = function() return false end,
    BeginTooltip = function() end,
    Text = function() end,
    EndTooltip = function() end,
    InvisibleButton = function() return false end,
    SetCursorPosX = function() end,
    GetCursorPosX = function() return 0 end,
    GetCursorScreenPos = function() return 100, 100 end,
}

local Glyphs = require("engines.0-Mod-Engine.ui.components.glyphs")

local M = {}

function M.testGet()
    local glyph = Glyphs.Get("Palette")
    assert.assert_equal(glyph, "🎨", "Get should return glyph")
end

function M.testGetFallback()
    local glyph = Glyphs.Get("Nonexistent", "?")
    assert.assert_equal(glyph, "?", "Get should return fallback")
end

function M.testGetNil()
    local glyph = Glyphs.Get(nil)
    assert.assert_equal(glyph, nil, "Get with nil name should return nil")
end

function M.testAvailable()
    assert.assert_true(Glyphs.Available(), "Should be available")
end

function M.testButton()
    local clicked = Glyphs.Button("test_btn", "Palette", { size = 28 })
    assert.assert_false(clicked, "Button should not be clicked")
end

function M.testInline()
    local drawn = Glyphs.Inline("Star", { spacing = 4 })
    assert.assert_true(drawn, "Inline should draw")
end

function M.testCenteredOnItem()
    Glyphs.CenteredOnItem("Check", { size = 22 })
    assert.assert_true(true, "CenteredOnItem should not throw")
end

return M
