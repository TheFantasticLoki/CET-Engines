--[[
    Theme Engine — UI-Engine

    Theme push/pop engine with caching, validation, and high contrast support.
    Manages ImGui style colors and style vars for the current theme.

    Depends on: core.lua, color_engine.lua, tokens.lua, config/themes.lua

    Features:
    - PushTheme() / PopTheme() — always balanced
    - Composite cache keys (theme + accent + contrast level)
    - High contrast levels (1-3)
    - Theme overrides (per-role color overrides)
    - Theme import/export
    - Theme validation
]]

local M = {}

-- --- Internal State ---

local _core = nil
local _colorEngine = nil
local _tokens = nil
local _themes = nil
local _logger = nil

local _initialized = false
local _pushCount = 0
local _cache = {}
local _overrides = {}

-- Track ACTUAL successful pushes (not just attempts)
-- This prevents PopTheme from popping more than were actually pushed
local _actualColorsPushed = 0
local _actualVarsPushed = 0

-- Style color count (number of PushStyleColor calls per PushTheme)
local STYLE_COLOR_COUNT = 27
-- Style var count (number of PushStyleVar calls per PushTheme)
local STYLE_VAR_COUNT = 9

-- --- Initialization ---

--- Initialize theme engine (idempotent)
-- @param core Core module reference
-- @param colorEngine ColorEngine module reference
-- @param tokens Tokens module reference
-- @param themes Theme definitions module reference
-- @param logger Logger module reference (optional)
function M.init(core, colorEngine, tokens, themes, logger)
    if _initialized then
        return
    end
    _initialized = true

    _core = core
    _colorEngine = colorEngine
    _tokens = tokens
    _themes = themes
    _logger = logger

    -- Resolve Log-Engine as fallback
    if not _logger then
        local ok, le = pcall(GetMod, "0-Engine-Log")
        if ok and le then
            local ok2, lgr = pcall(le.CreateLogger, "UI-Engine-Theme", { minLevel = "warn" })
            if ok2 and lgr then _logger = lgr end
        end
    end

    -- Initialize tokens module
    if _tokens and _tokens.init then
        _tokens.init(core, colorEngine, themes)
    end

    -- Listen for theme change events
    if _core and _core.setEventEmitter then
        -- We'll use the event system if available
    end
end

-- --- Cache Management ---

--- Generate composite cache key
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

--- Invalidate color cache
function M.InvalidateCache()
    _cache = {}
    if _tokens and _tokens.invalidateCache then
        _tokens.invalidateCache()
    end
end

--- Get cached style colors for current theme
-- @return table Array of {ImGuiCol, r, g, b, a} entries
local function getCachedStyleColors()
    local key = getCacheKey()
    if _cache[key] then
        return _cache[key]
    end

    -- Resolve colors from theme
    local colors = resolveThemeColors()
    _cache[key] = colors
    return colors
end

--- Resolve theme colors to ImGui style color entries
-- @return table Array of {ImGuiCol, r, g, b, a} entries
function resolveThemeColors()
    local colors = {}

    if not _core or not _themes then
        return colors
    end

    local themeName = _core.getCurrentTheme() or "Dark"
    local themeDef = _themes.getTheme(themeName)
    if not themeDef then
        return colors
    end

    local accent = themeDef.accent
    local roles = themeDef.roles

    -- Apply overrides
    local effectiveRoles = {}
    for k, v in pairs(roles) do
        effectiveRoles[k] = v
    end
    for k, v in pairs(_overrides) do
        effectiveRoles[k] = v
    end

    -- Get contrast level
    local contrastLevel = _core.getContrastLevel() or 1

    -- Generate style colors from roles
    -- WindowBg: background
    local bg = effectiveRoles.background or { r = 0.035, g = 0.030, b = 0.040 }
    table.insert(colors, { ImGuiCol.WindowBg, bg.r, bg.g, bg.b, 0.95 })

    -- Border: primary accent
    local primary = effectiveRoles.primary or accent
    table.insert(colors, { ImGuiCol.Border, primary.r, primary.g, primary.b, 0.90 })

    -- ChildBg: panel
    local panel = effectiveRoles.panel or { r = 0.055, g = 0.050, b = 0.065 }
    table.insert(colors, { ImGuiCol.ChildBg, panel.r, panel.g, panel.b, 0.95 })

    -- TitleBg: dark background
    table.insert(colors, { ImGuiCol.TitleBg, bg.r * 0.5, bg.g * 0.5, bg.b * 0.5, 1.0 })

    -- TitleBgActive: primary tint
    table.insert(colors, { ImGuiCol.TitleBgActive, primary.r * 0.28, primary.g * 0.28, primary.b * 0.28, 1.0 })

    -- TitleBgCollapsed: dark background
    table.insert(colors, { ImGuiCol.TitleBgCollapsed, bg.r * 0.5, bg.g * 0.5, bg.b * 0.5, 1.0 })

    -- Header: primary tint
    table.insert(colors, { ImGuiCol.Header, primary.r * 0.55, primary.g * 0.55, primary.b * 0.55, 0.90 })
    table.insert(colors, { ImGuiCol.HeaderHovered, primary.r * 0.82, primary.g * 0.82, primary.b * 0.82, 0.96 })
    table.insert(colors, { ImGuiCol.HeaderActive, primary.r, primary.g, primary.b, 1.0 })

    -- Tab: primary tint
    table.insert(colors, { ImGuiCol.Tab, primary.r * 0.22, primary.g * 0.22, primary.b * 0.22, 1.0 })
    table.insert(colors, { ImGuiCol.TabHovered, primary.r * 0.78, primary.g * 0.78, primary.b * 0.78, 1.0 })
    table.insert(colors, { ImGuiCol.TabActive, primary.r * 0.55, primary.g * 0.55, primary.b * 0.55, 1.0 })

    -- Button: primary tint
    table.insert(colors, { ImGuiCol.Button, primary.r * 0.38, primary.g * 0.38, primary.b * 0.38, 0.96 })
    table.insert(colors, { ImGuiCol.ButtonHovered, primary.r * 0.82, primary.g * 0.82, primary.b * 0.82, 1.0 })
    table.insert(colors, { ImGuiCol.ButtonActive, primary.r, primary.g, primary.b, 1.0 })

    -- FrameBg: panel
    table.insert(colors, { ImGuiCol.FrameBg, panel.r * 1.5, panel.g * 1.5, panel.b * 1.5, 1.0 })
    table.insert(colors, { ImGuiCol.FrameBgHovered, primary.r * 0.34, primary.g * 0.34, primary.b * 0.34, 1.0 })
    table.insert(colors, { ImGuiCol.FrameBgActive, primary.r * 0.48, primary.g * 0.48, primary.b * 0.48, 1.0 })

    -- SliderGrab: primary
    table.insert(colors, { ImGuiCol.SliderGrab, primary.r, primary.g, primary.b, 1.0 })
    table.insert(colors, { ImGuiCol.SliderGrabActive, math.min(primary.r + 0.18, 1.0), math.min(primary.g + 0.18, 1.0), math.min(primary.b + 0.18, 1.0), 1.0 })

    -- CheckMark: primary
    table.insert(colors, { ImGuiCol.CheckMark, primary.r, primary.g, primary.b, 1.0 })

    -- ScrollbarGrab: primary tint
    table.insert(colors, { ImGuiCol.ScrollbarGrab, primary.r * 0.45, primary.g * 0.45, primary.b * 0.45, 1.0 })
    table.insert(colors, { ImGuiCol.ScrollbarGrabHovered, primary.r * 0.75, primary.g * 0.75, primary.b * 0.75, 1.0 })
    table.insert(colors, { ImGuiCol.ScrollbarGrabActive, primary.r, primary.g, primary.b, 1.0 })

    -- ResizeGrip: primary tint
    table.insert(colors, { ImGuiCol.ResizeGrip, primary.r * 0.45, primary.g * 0.45, primary.b * 0.45, 0.80 })
    table.insert(colors, { ImGuiCol.ResizeGripHovered, primary.r * 0.75, primary.g * 0.75, primary.b * 0.75, 0.90 })
    table.insert(colors, { ImGuiCol.ResizeGripActive, primary.r, primary.g, primary.b, 1.0 })

    return colors
end

--- Get cached style vars for current theme
-- @return table Array of {ImGuiStyleVar, value} or {ImGuiStyleVar, x, y} entries
local function getCachedStyleVars()
    local key = getCacheKey() .. ":vars"
    if _cache[key] then
        return _cache[key]
    end

    local vars = {}
    if _themes then
        local baseVars = _themes.getBaseStyleVars()
        if baseVars then
            table.insert(vars, { "WindowRounding", baseVars.WindowRounding or 10.0 })
            table.insert(vars, { "ChildRounding", baseVars.ChildRounding or 8.0 })
            table.insert(vars, { "FrameRounding", baseVars.FrameRounding or 6.0 })
            table.insert(vars, { "GrabRounding", baseVars.GrabRounding or 6.0 })
            table.insert(vars, { "TabRounding", baseVars.TabRounding or 6.0 })
            table.insert(vars, { "WindowBorderSize", baseVars.WindowBorderSize or 1.5 })
            table.insert(vars, { "ChildBorderSize", baseVars.ChildBorderSize or 1.2 })
            table.insert(vars, { "WindowPadding", baseVars.WindowPadding and baseVars.WindowPadding.x or 12.0, baseVars.WindowPadding and baseVars.WindowPadding.y or 8.0 })
            table.insert(vars, { "ItemSpacing", baseVars.ItemSpacing and baseVars.ItemSpacing.x or 6.0, baseVars.ItemSpacing and baseVars.ItemSpacing.y or 6.0 })
        end
    end

    _cache[key] = vars
    return vars
end

-- --- Push/Pop Theme ---

--- Push theme (apply current theme's style vars)
function M.PushTheme()
    if not _initialized then
        return
    end

    -- Get cached style colors
    local colors = getCachedStyleColors()

    -- Push style colors directly — no pcall (CET FFI breaks with pcall)
    for _, entry in ipairs(colors) do
        ImGui.PushStyleColor(entry[1], entry[2], entry[3], entry[4], entry[5])
    end

    -- Get cached style vars
    local vars = getCachedStyleVars()

    -- Push style vars directly — no pcall (CET FFI breaks with pcall)
    for _, entry in ipairs(vars) do
        if #entry == 3 then
            ImGui.PushStyleVar(entry[1], entry[2], entry[3])
        else
            ImGui.PushStyleVar(entry[1], entry[2])
        end
    end

    _pushCount = _pushCount + 1
    _actualColorsPushed = _actualColorsPushed + #colors
    _actualVarsPushed = _actualVarsPushed + #vars
end

--- Pop theme (restore previous theme state)
function M.PopTheme()
    if not _initialized then
        return
    end

    if _pushCount <= 0 then
        if _logger then
            _logger.Log("Theme", "PopTheme called without matching PushTheme!", "warn")
        end
        return
    end

    -- Pop style vars directly — no pcall (CET FFI breaks with pcall)
    if _actualVarsPushed > 0 then
        ImGui.PopStyleVar(_actualVarsPushed)
    end

    -- Pop style colors directly — no pcall (CET FFI breaks with pcall)
    if _actualColorsPushed > 0 then
        ImGui.PopStyleColor(_actualColorsPushed)
    end

    -- Reset actual push counts for this cycle
    _actualColorsPushed = 0
    _actualVarsPushed = 0
    _pushCount = _pushCount - 1
end

-- --- Theme Management ---

--- Set current theme
-- @param themeName Theme name
-- @return boolean, string|nil success, error message
function M.SetTheme(themeName)
    if not _initialized then
        return false, "Theme engine not initialized"
    end

    if not themeName or type(themeName) ~= "string" then
        return false, "Invalid theme name"
    end

    -- Validate theme name
    if not M.ValidateTheme(themeName) then
        return false, "Unknown theme: " .. tostring(themeName)
    end

    -- Update Core state
    if _core then
        _core.setCurrentTheme(themeName)
    end

    -- Invalidate cache
    M.InvalidateCache()

    return true, nil
end

--- Get current theme name
-- @return string Theme name
function M.GetTheme()
    if not _core then
        return "Dark"
    end
    return _core.getCurrentTheme() or "Dark"
end

--- Get list of available theme names
-- @return table Array of theme name strings
function M.GetThemeList()
    if _themes then
        return _themes.getThemeNames()
    end
    return { "Dark" }
end

--- Get theme categories for UI grouping
-- @return table Array of category tables
function M.GetThemeCategories()
    if _themes then
        return _themes.getThemeCategories()
    end
    return {}
end

-- --- High Contrast Support ---

--- Set contrast level (1-3)
-- @param level Contrast level (1=normal, 2=high, 3=very high)
function M.SetHighContrast(level)
    if not _initialized then
        return
    end

    level = math.max(1, math.min(3, math.floor(tonumber(level) or 1)))

    if _core then
        _core.setContrastLevel(level)
    end

    -- Invalidate cache
    M.InvalidateCache()
end

--- Get contrast report for current theme
-- @return table Contrast report
function M.GetContrastReport()
    if not _core or not _colorEngine or not _themes then
        return {}
    end

    local themeName = _core.getCurrentTheme() or "Dark"
    local themeDef = _themes.getTheme(themeName)
    if not themeDef then
        return {}
    end

    local report = {}
    local roles = themeDef.roles

    for roleKey, color in pairs(roles) do
        local textContrast = _colorEngine.ContrastRatio(color, { r = 1, g = 1, b = 1 })
        local bgContrast = _colorEngine.ContrastRatio(color, roles.background or { r = 0.035, g = 0.030, b = 0.040 })

        report[roleKey] = {
            textContrast = textContrast,
            bgContrast = bgContrast,
            wcagAA = textContrast >= 4.5,
            wcagAAA = textContrast >= 7.0,
        }
    end

    return report
end

-- --- Theme Overrides ---

--- Set theme override for a role
-- @param role Role key (e.g., "primary", "background")
-- @param color Color table {r, g, b}
function M.SetThemeOverride(role, color)
    if not role or type(role) ~= "string" then
        return
    end

    if not color or type(color) ~= "table" then
        return
    end

    _overrides[role] = { r = color.r, g = color.g, b = color.b }

    -- Invalidate cache
    M.InvalidateCache()
end

--- Clear all theme overrides
function M.ClearThemeOverrides()
    _overrides = {}
    M.InvalidateCache()
end

-- --- Theme Import/Export ---

--- Export theme as table
-- @param themeName Theme name
-- @return table|nil Theme data or nil
function M.ExportTheme(themeName)
    if not _themes then
        return nil
    end

    local themeDef = _themes.getTheme(themeName)
    if not themeDef then
        return nil
    end

    return {
        name = themeName,
        accent = { r = themeDef.accent.r, g = themeDef.accent.g, b = themeDef.accent.b },
        roles = {},
    }
end

--- Import theme from table
-- @param themeName Theme name
-- @param themeData Theme data table
-- @return boolean, string|nil success, error message
function M.ImportTheme(themeName, themeData)
    if not themeName or type(themeName) ~= "string" then
        return false, "Invalid theme name"
    end

    if not themeData or type(themeData) ~= "table" then
        return false, "Invalid theme data"
    end

    -- Validate accent color
    if themeData.accent then
        if not M.ValidateAccentColor(themeData.accent) then
            return false, "Invalid accent color"
        end
    end

    -- Store in themes module
    if _themes and _themes.THEMES then
        _themes.THEMES[themeName] = {
            accent = themeData.accent or { r = 0.4, g = 0.6, b = 1.0 },
            roles = themeData.roles or {},
        }

        -- Add to theme order if not already there
        local found = false
        for _, name in ipairs(_themes.THEME_ORDER) do
            if name == themeName then
                found = true
                break
            end
        end
        if not found then
            table.insert(_themes.THEME_ORDER, themeName)
        end
    end

    -- Invalidate cache
    M.InvalidateCache()

    return true, nil
end

-- --- Theme Validation ---

--- Validate theme name exists
-- @param themeName Theme name
-- @return boolean True if valid
function M.ValidateTheme(themeName)
    if not _themes then
        return false
    end
    return _themes.getTheme(themeName) ~= nil
end

--- Validate accent color
-- @param accent Accent color {r, g, b}
-- @return boolean True if valid
function M.ValidateAccentColor(accent)
    if not accent or type(accent) ~= "table" then
        return false
    end
    if type(accent.r) ~= "number" or type(accent.g) ~= "number" or type(accent.b) ~= "number" then
        return false
    end
    if accent.r < 0 or accent.r > 1 or accent.g < 0 or accent.g > 1 or accent.b < 0 or accent.b > 1 then
        return false
    end
    return true
end

-- --- Push/Pop Balance Check ---

--- Get current push count (for testing)
-- @return number Push count
function M.GetPushCount()
    return _pushCount
end

--- Check if push/pop is balanced
-- @return boolean True if balanced
function M.IsBalanced()
    return _pushCount == 0
end

-- --- Reset (for testing) ---

--- Reset theme engine state (for testing)
function M.reset()
    _core = nil
    _colorEngine = nil
    _tokens = nil
    _themes = nil
    _logger = nil
    _initialized = false
    _pushCount = 0
    _cache = {}
    _overrides = {}
end

return M
