--[[
    Color Engine — UI-Engine

    Pure math module for color conversion, WCAG contrast, and palette generation.
    No dependencies, no state, no side effects.

    Functions:
    - RGB ↔ HSL conversion
    - WCAG 2.0 luminance/contrast ratio calculation
    - Palette generation from accent color
    - Color manipulation (brightness, saturation, blending)
    - Color validation and clamping
]]

local M = {}

-- --- RGB ↔ HSL Conversion ---

--- Convert RGB (0-1) to HSL (0-360, 0-1, 0-1)
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @return number, number, number h, s, l
function M.RGBToHSL(r, g, b)
    r = math.max(0, math.min(1, r))
    g = math.max(0, math.min(1, g))
    b = math.max(0, math.min(1, b))

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, 0

    l = (max + min) / 2

    if max ~= min then
        local d = max - min
        if l > 0.5 then
            s = d / (2 - max - min)
        else
            s = d / (max + min)
        end

        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end

        h = h * 60
    end

    return h, s, l
end

--- Convert HSL (0-360, 0-1, 0-1) to RGB (0-1)
-- @param h Hue (0-360)
-- @param s Saturation (0-1)
-- @param l Lightness (0-1)
-- @return number, number, number r, g, b
function M.HSLToRGB(h, s, l)
    h = ((h % 360) + 360) % 360
    s = math.max(0, math.min(1, s))
    l = math.max(0, math.min(1, l))

    local c = (1 - math.abs(2 * l - 1)) * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = l - c / 2

    local r, g, b = 0, 0, 0

    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return r + m, g + m, b + m
end

-- --- WCAG 2.0 Contrast Ratio ---

--- Calculate relative luminance (WCAG 2.0)
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @return number Luminance (0-1)
function M.Luminance(r, g, b)
    local function linearize(c)
        if c <= 0.03928 then
            return c / 12.92
        else
            return ((c + 0.055) / 1.055) ^ 2.4
        end
    end

    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
end

--- Calculate contrast ratio between two colors
-- @param color1 First color {r, g, b} (0-1)
-- @param color2 Second color {r, g, b} (0-1)
-- @return number Contrast ratio (1-21)
function M.ContrastRatio(color1, color2)
    local l1 = M.Luminance(color1.r, color1.g, color1.b)
    local l2 = M.Luminance(color2.r, color2.g, color2.b)

    local lighter = math.max(l1, l2)
    local darker = math.min(l1, l2)

    return (lighter + 0.05) / (darker + 0.05)
end

--- Check if contrast ratio meets WCAG level
-- @param color1 First color {r, g, b} (0-1)
-- @param color2 Second color {r, g, b} (0-1)
-- @param level WCAG level ("AA" or "AAA")
-- @return boolean True if compliant
function M.IsWCAGCompliant(color1, color2, level)
    local ratio = M.ContrastRatio(color1, color2)
    if level == "AAA" then
        return ratio >= 7.0
    else
        -- Default to AA
        return ratio >= 4.5
    end
end

-- --- Palette Generation ---

--- Generate full palette from single accent color
-- @param accentRGB Accent color {r, g, b} (0-1)
-- @return table Palette with semantic role colors
function M.GeneratePalette(accentRGB)
    local r, g, b = accentRGB.r, accentRGB.g, accentRGB.b
    local h, s, l = M.RGBToHSL(r, g, b)

    -- Generate palette from accent
    local palette = {}

    -- Primary: the accent color itself
    palette.primary = { r = r, g = g, b = b }

    -- Secondary: complementary color (180° hue shift)
    local sr, sg, sb = M.HSLToRGB((h + 180) % 360, s, l)
    palette.secondary = { r = sr, g = sg, b = sb }

    -- Success: green tint
    local successR, successG, successB = M.HSLToRGB(140, 0.7, 0.4)
    palette.success = { r = successR, g = successG, b = successB }

    -- Modified: purple tint
    local modifiedR, modifiedG, modifiedB = M.HSLToRGB(270, 0.6, 0.5)
    palette.modified = { r = modifiedR, g = modifiedG, b = modifiedB }

    -- Favorite: gold tint
    local favoriteR, favoriteG, favoriteB = M.HSLToRGB(40, 0.85, 0.5)
    palette.favorite = { r = favoriteR, g = favoriteG, b = favoriteB }

    -- Text: white or near-white
    palette.text = { r = 1.0, g = 1.0, b = 1.0 }

    -- Muted: desaturated version of accent
    local mutedR, mutedG, mutedB = M.HSLToRGB(h, 0.15, 0.5)
    palette.muted = { r = mutedR, g = mutedG, b = mutedB }

    -- Background: very dark version of accent
    local bgR, bgG, bgB = M.HSLToRGB(h, 0.3, 0.04)
    palette.background = { r = bgR, g = bgG, b = bgB }

    -- Panel: slightly lighter than background
    local panelR, panelG, panelB = M.HSLToRGB(h, 0.3, 0.06)
    palette.panel = { r = panelR, g = panelG, b = panelB }

    -- Panel selected: medium accent
    local selectedR, selectedG, selectedB = M.HSLToRGB(h, 0.5, 0.15)
    palette.panelSelected = { r = selectedR, g = selectedG, b = selectedB }

    return palette
end

-- --- Color Manipulation ---

--- Adjust brightness by factor (0-2)
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @param factor Brightness factor (0-2, 1 = no change)
-- @return number, number, number r, g, b
function M.AdjustBrightness(r, g, b, factor)
    return math.max(0, math.min(1, r * factor)),
           math.max(0, math.min(1, g * factor)),
           math.max(0, math.min(1, b * factor))
end

--- Adjust saturation by factor (0-2)
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @param factor Saturation factor (0-2, 1 = no change)
-- @return number, number, number r, g, b
function M.AdjustSaturation(r, g, b, factor)
    local h, s, l = M.RGBToHSL(r, g, b)
    s = math.max(0, math.min(1, s * factor))
    return M.HSLToRGB(h, s, l)
end

--- Blend two colors by factor (0-1)
-- @param color1 First color {r, g, b}
-- @param color2 Second color {r, g, b}
-- @param factor Blend factor (0 = color1, 1 = color2)
-- @return table Blended color {r, g, b}
function M.Blend(color1, color2, factor)
    factor = math.max(0, math.min(1, factor))
    return {
        r = color1.r + (color2.r - color1.r) * factor,
        g = color1.g + (color2.g - color1.g) * factor,
        b = color1.b + (color2.b - color1.b) * factor,
    }
end

--- Create color with alpha
-- @param r Red (0-1)
-- @param g Green (0-1)
-- @param b Blue (0-1)
-- @param a Alpha (0-1)
-- @return table Color with alpha {r, g, b, a}
function M.WithAlpha(r, g, b, a)
    return { r = r, g = g, b = b, a = a }
end

-- --- Color Validation ---

--- Check if color table has valid r, g, b, a fields
-- @param color Color table
-- @return boolean True if valid
function M.IsValidColor(color)
    if type(color) ~= "table" then
        return false
    end
    if type(color.r) ~= "number" or type(color.g) ~= "number" or type(color.b) ~= "number" then
        return false
    end
    if color.r < 0 or color.r > 1 or color.g < 0 or color.g > 1 or color.b < 0 or color.b > 1 then
        return false
    end
    if color.a ~= nil and (type(color.a) ~= "number" or color.a < 0 or color.a > 1) then
        return false
    end
    return true
end

--- Clamp color values to 0-1 range
-- @param color Color table {r, g, b, a}
-- @return table Clamped color
function M.ClampColor(color)
    if not color then
        return { r = 1, g = 1, b = 1, a = 1 }
    end
    return {
        r = math.max(0, math.min(1, color.r or 1)),
        g = math.max(0, math.min(1, color.g or 1)),
        b = math.max(0, math.min(1, color.b or 1)),
        a = math.max(0, math.min(1, color.a or 1)),
    }
end

return M