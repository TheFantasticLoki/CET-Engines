--[[
    Color Engine — 0-Mod-Engine

    Pure math module for color conversion, WCAG contrast, and palette generation.
    No dependencies, no state, no side effects.

    Functions:
    - RGB ↔ HSL conversion
    - WCAG 2.0 luminance/contrast ratio calculation
    - Palette generation from accent color
    - Color manipulation (brightness, saturation, blending)
    - Color validation and clamping
]]

---@class ColorEngine
---@field RGBToHSL fun(r: number, g: number, b: number): number, number, number
---@field HSLToRGB fun(h: number, s: number, l: number): number, number, number
---@field Luminance fun(r: number, g: number, b: number): number
---@field ContrastRatio fun(color1: ColorRGB, color2: ColorRGB): number

---@alias ColorRGB {r: number, g: number, b: number}
---@alias ColorRGBA {r: number, g: number, b: number, a?: number}

local M = {}

-- --- RGB ↔ HSL Conversion ---

--- Convert RGB (0-1) to HSL (0-360, 0-1, 0-1)
---@param r number Red (0-1)
---@param g number Green (0-1)
---@param b number Blue (0-1)
---@return number, number, number h, s, l
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
---@param h number Hue (0-360)
---@param s number Saturation (0-1)
---@param l number Lightness (0-1)
---@return number, number, number r, g, b
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
---@param r number Red (0-1)
---@param g number Green (0-1)
---@param b number Blue (0-1)
---@return number Luminance (0-1)
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
---@param color1 ColorRGB First color {r, g, b} (0-1)
---@param color2 ColorRGB Second color {r, g, b} (0-1)
---@return number Contrast ratio (1-21)
function M.ContrastRatio(color1, color2)
    local l1 = M.Luminance(color1.r, color1.g, color1.b)
    local l2 = M.Luminance(color2.r, color2.g, color2.b)

    local lighter = math.max(l1, l2)
    local darker = math.min(l1, l2)

    return (lighter + 0.05) / (darker + 0.05)
end

return M