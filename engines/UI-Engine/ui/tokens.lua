--[[
    Design Tokens — UI-Engine

    Design tokens for spacing, sizing, borders, text, and theme-aware colors.
    Static tokens are constant values. Dynamic tokens resolve from the current theme.

    Depends on: core.lua (for theme state)
    No other dependencies.
]]

local M = {}

-- --- Static Tokens ---

-- Spacing scale
M.SPACING = {
    xs = 2,
    sm = 4,
    md = 8,
    lg = 12,
    xl = 16,
    xxl = 24,
}

-- Sizing constants
M.SIZING = {
    button = { width = 80, height = 28 },
    slider = { width = 200, height = 20 },
    input = { width = 200, height = 24 },
    badge = { minWidth = 40, height = 20 },
    toggle = { width = 54, height = 28 },
}

-- Border radii
M.BORDER_RADIUS = {
    sm = 4,
    md = 6,
    lg = 8,
    xl = 10,
}

-- Text sizes
M.TEXT_SIZE = {
    xs = 10,
    sm = 12,
    md = 14,
    lg = 16,
    xl = 18,
}

-- --- Dynamic Tokens (Theme-Aware) ---

-- Color cache (invalidated on theme change)
local _colorCache = {}
local _cacheKey = nil

-- Dependencies (set during init)
local _core = nil
local _colorEngine = nil
local _themes = nil
local _initialized = false

--- Initialize tokens module
-- @param core Core module reference
-- @param colorEngine ColorEngine module reference
-- @param themes Theme definitions module reference
function M.init(core, colorEngine, themes)
    if _initialized then
        return
    end
    _initialized = true

    _core = core
    _colorEngine = colorEngine
    _themes = themes
end

--- Generate cache key from current theme state
-- @return string Cache key
local function getCacheKey()
    if not _core then
        return "default"
    end

    local themeName = _core.getCurrentTheme() or "Dark"
    local accent = _core.getAccentColor() or { r = 0.4, g = 0.6, b = 1.0 }
    local contrast = _core.getContrastLevel() or 1

    return themeName .. ":" .. tostring(accent.r) .. ":" .. tostring(accent.g) .. ":" .. tostring(accent.b) .. ":" .. tostring(contrast)
end

--- Get resolved color for a semantic role
-- @param role Role key (e.g., "primary", "background")
-- @return table Color {r, g, b, a}
function M.color4n(role)
    local key = getCacheKey()

    -- Check cache
    if _colorCache[key] and _colorCache[key][role] then
        return _colorCache[key][role]
    end

    -- Resolve color
    local color = nil

    if _themes and _core then
        local themeName = _core.getCurrentTheme() or "Dark"
        local themeDef = _themes.getTheme(themeName)

        if themeDef and themeDef.roles[role] then
            color = themeDef.roles[role]
        end
    end

    -- Fallback to default
    if not color then
        color = { r = 1, g = 1, b = 1 }
    end

    -- Apply contrast adjustment
    if _core then
        local contrastLevel = _core.getContrastLevel() or 1
        if contrastLevel > 1 and _colorEngine then
            -- Adjust contrast for high contrast modes
            local h, s, l = _colorEngine.RGBToHSL(color.r, color.g, color.b)
            if l > 0.5 then
                -- Light colors: darken for contrast
                l = math.max(0, l - (contrastLevel - 1) * 0.1)
            else
                -- Dark colors: lighten for contrast
                l = math.min(1, l + (contrastLevel - 1) * 0.1)
            end
            color = { r = _colorEngine.HSLToRGB(h, s, l) }
            color = { r = color[1], g = color[2], b = color[3] }
        end
    end

    -- Cache the result
    if not _colorCache[key] then
        _colorCache[key] = {}
    end
    _colorCache[key][role] = { r = color.r, g = color.g, b = color.b, a = 1.0 }

    return _colorCache[key][role]
end

--- Get resolved color for a semantic role (no alpha)
-- @param role Role key (e.g., "primary", "background")
-- @return table Color {r, g, b}
function M.color4(role)
    local c = M.color4n(role)
    return { r = c.r, g = c.g, b = c.b }
end

--- Invalidate color cache (called on theme change)
function M.invalidateCache()
    _colorCache = {}
    _cacheKey = nil
end

--- Get style var value
-- @param name Style var name (e.g., "WindowRounding")
-- @return number Style var value
function M.styleVar(name)
    if _themes then
        local baseVars = _themes.getBaseStyleVars()
        if baseVars and baseVars[name] then
            return baseVars[name]
        end
    end
    return 0
end

--- Get style var as Vec2
-- @param name Style var name (e.g., "WindowPadding")
-- @return number, number x, y
function M.styleVarVec2(name)
    if _themes then
        local baseVars = _themes.getBaseStyleVars()
        if baseVars and baseVars[name] then
            local v = baseVars[name]
            if type(v) == "table" then
                return v.x or 0, v.y or 0
            end
            return v, v
        end
    end
    return 0, 0
end

-- --- Reset (for testing) ---

--- Reset tokens module state (for testing)
function M.reset()
    _colorCache = {}
    _cacheKey = nil
    _core = nil
    _colorEngine = nil
    _themes = nil
    _initialized = false
end

return M
