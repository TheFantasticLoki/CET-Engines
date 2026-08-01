--[[
    Color Engine Tests — UI-Engine

    Tests for engines/UI-Engine/ui/color_engine.lua
]]

local assert = require("tests.assert")
local ColorEngine = require("engines.UI-Engine.ui.color_engine")

local M = {}

-- --- Test RGB ↔ HSL Conversion ---

function M.testRGBToHSLRed()
    local h, s, l = ColorEngine.RGBToHSL(1, 0, 0)
    assert.assert_equal(math.floor(h), 0, "Red hue should be 0")
    assert.assert_equal(s, 1, "Red saturation should be 1")
    assert.assert_equal(l, 0.5, "Red lightness should be 0.5")
end

function M.testRGBToHSLGreen()
    local h, s, l = ColorEngine.RGBToHSL(0, 1, 0)
    assert.assert_equal(math.floor(h), 120, "Green hue should be 120")
    assert.assert_equal(s, 1, "Green saturation should be 1")
    assert.assert_equal(l, 0.5, "Green lightness should be 0.5")
end

function M.testRGBToHSLBlue()
    local h, s, l = ColorEngine.RGBToHSL(0, 0, 1)
    assert.assert_equal(math.floor(h), 240, "Blue hue should be 240")
    assert.assert_equal(s, 1, "Blue saturation should be 1")
    assert.assert_equal(l, 0.5, "Blue lightness should be 0.5")
end

function M.testRGBToHSLWhite()
    local h, s, l = ColorEngine.RGBToHSL(1, 1, 1)
    assert.assert_equal(s, 0, "White saturation should be 0")
    assert.assert_equal(l, 1, "White lightness should be 1")
end

function M.testRGBToHSLBlack()
    local h, s, l = ColorEngine.RGBToHSL(0, 0, 0)
    assert.assert_equal(s, 0, "Black saturation should be 0")
    assert.assert_equal(l, 0, "Black lightness should be 0")
end

function M.testHSLToRGBRed()
    local r, g, b = ColorEngine.HSLToRGB(0, 1, 0.5)
    assert.assert_true(math.abs(r - 1) < 0.01, "Red should be ~1")
    assert.assert_true(math.abs(g) < 0.01, "Green should be ~0")
    assert.assert_true(math.abs(b) < 0.01, "Blue should be ~0")
end

function M.testHSLToRGBGreen()
    local r, g, b = ColorEngine.HSLToRGB(120, 1, 0.5)
    assert.assert_true(math.abs(r) < 0.01, "Red should be ~0")
    assert.assert_true(math.abs(g - 1) < 0.01, "Green should be ~1")
    assert.assert_true(math.abs(b) < 0.01, "Blue should be ~0")
end

function M.testHSLToRGBBlue()
    local r, g, b = ColorEngine.HSLToRGB(240, 1, 0.5)
    assert.assert_true(math.abs(r) < 0.01, "Red should be ~0")
    assert.assert_true(math.abs(g) < 0.01, "Green should be ~0")
    assert.assert_true(math.abs(b - 1) < 0.01, "Blue should be ~1")
end

function M.testRGBHSLRoundTrip()
    local testColors = {
        { r = 0.5, g = 0.3, b = 0.8 },
        { r = 0.9, g = 0.1, b = 0.2 },
        { r = 0.1, g = 0.8, b = 0.3 },
        { r = 0.4, g = 0.6, b = 1.0 },
    }

    for _, color in ipairs(testColors) do
        local h, s, l = ColorEngine.RGBToHSL(color.r, color.g, color.b)
        local r2, g2, b2 = ColorEngine.HSLToRGB(h, s, l)
        assert.assert_true(math.abs(r2 - color.r) < 0.01, "Round-trip r should match")
        assert.assert_true(math.abs(g2 - color.g) < 0.01, "Round-trip g should match")
        assert.assert_true(math.abs(b2 - color.b) < 0.01, "Round-trip b should match")
    end
end

-- --- Test WCAG Contrast ---

function M.testLuminanceWhite()
    local lum = ColorEngine.Luminance(1, 1, 1)
    assert.assert_true(math.abs(lum - 1.0) < 0.01, "White luminance should be ~1.0")
end

function M.testLuminanceBlack()
    local lum = ColorEngine.Luminance(0, 0, 0)
    assert.assert_true(math.abs(lum) < 0.01, "Black luminance should be ~0.0")
end

function M.testContrastRatioWhiteBlack()
    local ratio = ColorEngine.ContrastRatio(
        { r = 1, g = 1, b = 1 },
        { r = 0, g = 0, b = 0 }
    )
    assert.assert_true(math.abs(ratio - 21.0) < 0.1, "White/Black contrast should be ~21:1")
end

function M.testContrastRatioSameColor()
    local ratio = ColorEngine.ContrastRatio(
        { r = 0.5, g = 0.5, b = 0.5 },
        { r = 0.5, g = 0.5, b = 0.5 }
    )
    assert.assert_equal(ratio, 1.0, "Same color contrast should be 1:1")
end

function M.testIsWCAGCompliantAA()
    assert.assert_true(
        ColorEngine.IsWCAGCompliant(
            { r = 1, g = 1, b = 1 },
            { r = 0, g = 0, b = 0 },
            "AA"
        ),
        "White/Black should be AA compliant"
    )
end

function M.testIsWCAGCompliantAAA()
    assert.assert_true(
        ColorEngine.IsWCAGCompliant(
            { r = 1, g = 1, b = 1 },
            { r = 0, g = 0, b = 0 },
            "AAA"
        ),
        "White/Black should be AAA compliant"
    )
end

-- --- Test Palette Generation ---

function M.testGeneratePalette()
    local palette = ColorEngine.GeneratePalette({ r = 0.4, g = 0.6, b = 1.0 })
    assert.assert_not_nil(palette, "Palette should not be nil")
    assert.assert_not_nil(palette.primary, "Palette should have primary")
    assert.assert_not_nil(palette.secondary, "Palette should have secondary")
    assert.assert_not_nil(palette.success, "Palette should have success")
    assert.assert_not_nil(palette.text, "Palette should have text")
    assert.assert_not_nil(palette.muted, "Palette should have muted")
    assert.assert_not_nil(palette.background, "Palette should have background")
    assert.assert_not_nil(palette.panel, "Palette should have panel")
    assert.assert_not_nil(palette.panelSelected, "Palette should have panelSelected")
end

function M.testGeneratePalettePrimary()
    local palette = ColorEngine.GeneratePalette({ r = 0.4, g = 0.6, b = 1.0 })
    assert.assert_true(math.abs(palette.primary.r - 0.4) < 0.01, "Primary should match accent")
    assert.assert_true(math.abs(palette.primary.g - 0.6) < 0.01, "Primary should match accent")
    assert.assert_true(math.abs(palette.primary.b - 1.0) < 0.01, "Primary should match accent")
end

-- --- Test Color Manipulation ---

function M.testAdjustBrightness()
    local r, g, b = ColorEngine.AdjustBrightness(0.5, 0.5, 0.5, 2.0)
    assert.assert_equal(r, 1.0, "Brightness 2x should be 1.0")
    assert.assert_equal(g, 1.0, "Brightness 2x should be 1.0")
    assert.assert_equal(b, 1.0, "Brightness 2x should be 1.0")
end

function M.testAdjustBrightnessClamp()
    local r, g, b = ColorEngine.AdjustBrightness(0.8, 0.8, 0.8, 2.0)
    assert.assert_equal(r, 1.0, "Brightness should be clamped to 1.0")
end

function M.testAdjustSaturation()
    local r, g, b = ColorEngine.AdjustSaturation(0.5, 0.5, 0.5, 0.0)
    assert.assert_true(math.abs(r - g) < 0.01, "Desaturated should be gray")
    assert.assert_true(math.abs(g - b) < 0.01, "Desaturated should be gray")
end

function M.testBlend()
    local color1 = { r = 1, g = 0, b = 0 }
    local color2 = { r = 0, g = 0, b = 1 }
    local blended = ColorEngine.Blend(color1, color2, 0.5)
    assert.assert_true(math.abs(blended.r - 0.5) < 0.01, "Blended r should be 0.5")
    assert.assert_true(math.abs(blended.g) < 0.01, "Blended g should be 0")
    assert.assert_true(math.abs(blended.b - 0.5) < 0.01, "Blended b should be 0.5")
end

function M.testWithAlpha()
    local color = ColorEngine.WithAlpha(1, 0, 0, 0.5)
    assert.assert_equal(color.r, 1, "WithAlpha r should be 1")
    assert.assert_equal(color.a, 0.5, "WithAlpha a should be 0.5")
end

-- --- Test Color Validation ---

function M.testIsValidColor()
    assert.assert_true(ColorEngine.IsValidColor({ r = 0.5, g = 0.5, b = 0.5 }), "Valid color should pass")
    assert.assert_false(ColorEngine.IsValidColor({ r = 2, g = 0.5, b = 0.5 }), "Out of range should fail")
    assert.assert_false(ColorEngine.IsValidColor({ r = "a", g = 0.5, b = 0.5 }), "String should fail")
    assert.assert_false(ColorEngine.IsValidColor(nil), "Nil should fail")
    assert.assert_false(ColorEngine.IsValidColor("string"), "String should fail")
end

function M.testClampColor()
    local clamped = ColorEngine.ClampColor({ r = 2, g = -1, b = 0.5, a = 1.5 })
    assert.assert_equal(clamped.r, 1, "Clamped r should be 1")
    assert.assert_equal(clamped.g, 0, "Clamped g should be 0")
    assert.assert_equal(clamped.b, 0.5, "Clamped b should be 0.5")
    assert.assert_equal(clamped.a, 1, "Clamped a should be 1")
end

function M.testClampColorNil()
    local clamped = ColorEngine.ClampColor(nil)
    assert.assert_equal(clamped.r, 1, "Nil clamp r should be 1")
    assert.assert_equal(clamped.g, 1, "Nil clamp g should be 1")
    assert.assert_equal(clamped.b, 1, "Nil clamp b should be 1")
    assert.assert_equal(clamped.a, 1, "Nil clamp a should be 1")
end

return M