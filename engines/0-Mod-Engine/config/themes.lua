--[[
    Theme Definitions — 0-Mod-Engine

    Pure data definitions for all 16 built-in themes.
    No logic, no dependencies.

    Each theme has:
    - accent: RGB color (0-1 range) for accent-driven palette generation
    - roles: Semantic role overrides (background, panel, primary, etc.)

    Theme categories group themes for UI display.
    Base style variables are shared across all themes.
]]

---@class ThemeDef
---@field accent ColorRGB
---@field roles table<string, ColorRGB>

---@alias ColorRGB {r: number, g: number, b: number}

---@class ThemeDefinitions
---@field THEMES table<string, ThemeDef>
---@field THEME_ORDER string[]
---@field THEME_CATEGORIES table[]
---@field BASE_STYLE_VARS table<string, any>
---@field ROLES table[]
---@field getTheme fun(name: string): ThemeDef|nil
---@field getThemeNames fun(): string[]
---@field getThemeCategories fun(): table[]
---@field getRole fun(themeName: string, roleKey: string): ColorRGB|nil
---@field getAccent fun(themeName: string): ColorRGB|nil
---@field getBaseStyleVars fun(): table
---@field getRoles fun(): table[]

local M = {}

-- --- Theme Definitions ---

M.THEMES = {
    Dark = {
        accent = { r = 0.4, g = 0.6, b = 1.0 },
        roles = {
            background = { r = 0.035, g = 0.030, b = 0.040 },
            panel = { r = 0.055, g = 0.050, b = 0.065 },
            panelSelected = { r = 0.08, g = 0.12, b = 0.20 },
            primary = { r = 0.4, g = 0.6, b = 1.0 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Red = {
        accent = { r = 0.95, g = 0.08, b = 0.12 },
        roles = {
            background = { r = 0.035, g = 0.025, b = 0.030 },
            panel = { r = 0.055, g = 0.035, b = 0.045 },
            panelSelected = { r = 0.18, g = 0.025, b = 0.040 },
            primary = { r = 0.95, g = 0.08, b = 0.12 },
            secondary = { r = 0.08, g = 0.72, b = 0.86 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Cyan = {
        accent = { r = 0.08, g = 0.72, b = 0.86 },
        roles = {
            background = { r = 0.025, g = 0.040, b = 0.050 },
            panel = { r = 0.035, g = 0.060, b = 0.075 },
            panelSelected = { r = 0.030, g = 0.18, b = 0.22 },
            primary = { r = 0.08, g = 0.72, b = 0.86 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Blue = {
        accent = { r = 0.12, g = 0.36, b = 0.95 },
        roles = {
            background = { r = 0.025, g = 0.030, b = 0.050 },
            panel = { r = 0.040, g = 0.050, b = 0.080 },
            panelSelected = { r = 0.06, g = 0.10, b = 0.22 },
            primary = { r = 0.12, g = 0.36, b = 0.95 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Green = {
        accent = { r = 0.12, g = 0.70, b = 0.32 },
        roles = {
            background = { r = 0.025, g = 0.040, b = 0.030 },
            panel = { r = 0.035, g = 0.065, b = 0.045 },
            panelSelected = { r = 0.04, g = 0.18, b = 0.08 },
            primary = { r = 0.12, g = 0.70, b = 0.32 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Amber = {
        accent = { r = 0.95, g = 0.52, b = 0.10 },
        roles = {
            background = { r = 0.040, g = 0.035, b = 0.025 },
            panel = { r = 0.065, g = 0.055, b = 0.035 },
            panelSelected = { r = 0.20, g = 0.12, b = 0.04 },
            primary = { r = 0.95, g = 0.52, b = 0.10 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Purple = {
        accent = { r = 0.58, g = 0.22, b = 0.90 },
        roles = {
            background = { r = 0.035, g = 0.025, b = 0.050 },
            panel = { r = 0.055, g = 0.040, b = 0.075 },
            panelSelected = { r = 0.12, g = 0.06, b = 0.22 },
            primary = { r = 0.58, g = 0.22, b = 0.90 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Rose = {
        accent = { r = 0.90, g = 0.20, b = 0.50 },
        roles = {
            background = { r = 0.040, g = 0.025, b = 0.035 },
            panel = { r = 0.065, g = 0.035, b = 0.055 },
            panelSelected = { r = 0.20, g = 0.04, b = 0.12 },
            primary = { r = 0.90, g = 0.20, b = 0.50 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Teal = {
        accent = { r = 0.10, g = 0.65, b = 0.65 },
        roles = {
            background = { r = 0.025, g = 0.040, b = 0.040 },
            panel = { r = 0.035, g = 0.060, b = 0.060 },
            panelSelected = { r = 0.04, g = 0.16, b = 0.16 },
            primary = { r = 0.10, g = 0.65, b = 0.65 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Midnight = {
        accent = { r = 0.20, g = 0.25, b = 0.50 },
        roles = {
            background = { r = 0.020, g = 0.025, b = 0.040 },
            panel = { r = 0.030, g = 0.035, b = 0.060 },
            panelSelected = { r = 0.05, g = 0.08, b = 0.18 },
            primary = { r = 0.20, g = 0.25, b = 0.50 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Orange = {
        accent = { r = 0.95, g = 0.45, b = 0.10 },
        roles = {
            background = { r = 0.040, g = 0.030, b = 0.025 },
            panel = { r = 0.065, g = 0.050, b = 0.035 },
            panelSelected = { r = 0.20, g = 0.10, b = 0.04 },
            primary = { r = 0.95, g = 0.45, b = 0.10 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Gold = {
        accent = { r = 0.85, g = 0.65, b = 0.15 },
        roles = {
            background = { r = 0.040, g = 0.035, b = 0.025 },
            panel = { r = 0.060, g = 0.055, b = 0.035 },
            panelSelected = { r = 0.18, g = 0.14, b = 0.04 },
            primary = { r = 0.85, g = 0.65, b = 0.15 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Pink = {
        accent = { r = 0.90, g = 0.30, b = 0.60 },
        roles = {
            background = { r = 0.040, g = 0.025, b = 0.035 },
            panel = { r = 0.065, g = 0.040, b = 0.055 },
            panelSelected = { r = 0.20, g = 0.06, b = 0.14 },
            primary = { r = 0.90, g = 0.30, b = 0.60 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    White = {
        accent = { r = 0.85, g = 0.85, b = 0.90 },
        roles = {
            background = { r = 0.92, g = 0.92, b = 0.94 },
            panel = { r = 0.88, g = 0.88, b = 0.90 },
            panelSelected = { r = 0.80, g = 0.82, b = 0.88 },
            primary = { r = 0.85, g = 0.85, b = 0.90 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 0.10, g = 0.10, b = 0.12 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Arasaka = {
        accent = { r = 0.80, g = 0.10, b = 0.10 },
        roles = {
            background = { r = 0.030, g = 0.020, b = 0.020 },
            panel = { r = 0.050, g = 0.030, b = 0.030 },
            panelSelected = { r = 0.16, g = 0.03, b = 0.03 },
            primary = { r = 0.80, g = 0.10, b = 0.10 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 1.0, g = 1.0, b = 1.0 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
    Light = {
        accent = { r = 0.30, g = 0.50, b = 0.80 },
        roles = {
            background = { r = 0.90, g = 0.90, b = 0.92 },
            panel = { r = 0.85, g = 0.85, b = 0.88 },
            panelSelected = { r = 0.75, g = 0.78, b = 0.85 },
            primary = { r = 0.30, g = 0.50, b = 0.80 },
            secondary = { r = 0.95, g = 0.08, b = 0.12 },
            success = { r = 0.12, g = 0.70, b = 0.32 },
            modified = { r = 0.58, g = 0.22, b = 0.90 },
            favorite = { r = 0.95, g = 0.52, b = 0.10 },
            text = { r = 0.10, g = 0.10, b = 0.12 },
            muted = { r = 0.5, g = 0.5, b = 0.6 },
        },
    },
}

-- --- Theme Order ---

M.THEME_ORDER = {
    "Dark", "Red", "Cyan", "Blue", "Green", "Amber", "Purple",
    "Rose", "Teal", "Midnight", "Orange", "Gold", "Pink",
    "White", "Arasaka", "Light",
}

-- --- Theme Categories ---

M.THEME_CATEGORIES = {
    { name = "Dark", themes = { "Dark", "Midnight", "Arasaka" } },
    { name = "Light", themes = { "Light", "White" } },
    { name = "Accent", themes = { "Red", "Cyan", "Blue", "Green", "Amber", "Purple", "Rose", "Teal", "Orange", "Gold", "Pink" } },
}

-- --- Base Style Variables ---

M.BASE_STYLE_VARS = {
    WindowRounding = 10.0,
    ChildRounding = 8.0,
    FrameRounding = 6.0,
    GrabRounding = 6.0,
    TabRounding = 6.0,
    WindowBorderSize = 1.5,
    ChildBorderSize = 1.2,
    WindowPadding = { x = 12.0, y = 8.0 },
    ItemSpacing = { x = 6.0, y = 6.0 },
}

-- --- Semantic Role Definitions ---

M.ROLES = {
    { key = "background", label = "Background" },
    { key = "panel", label = "Panel" },
    { key = "panelSelected", label = "Panel Selected" },
    { key = "primary", label = "Primary" },
    { key = "secondary", label = "Secondary" },
    { key = "success", label = "Success" },
    { key = "modified", label = "Modified" },
    { key = "favorite", label = "Favorite" },
    { key = "text", label = "Text" },
    { key = "muted", label = "Muted" },
}

-- --- Helper Functions ---

--- Get a theme definition by name
---@param name string Theme name
---@return ThemeDef|nil Theme definition or nil
function M.getTheme(name)
    return M.THEMES[name]
end

--- Get list of available theme names
---@return table Array of theme name strings
function M.getThemeNames()
    return M.THEME_ORDER
end

--- Get theme categories for UI grouping
---@return table Array of category tables
function M.getThemeCategories()
    return M.THEME_CATEGORIES
end

--- Get a semantic role color from a theme
---@param themeName string Theme name
---@param roleKey string Role key (e.g., "primary", "background")
---@return ColorRGB|nil Color table {r, g, b} or nil
function M.getRole(themeName, roleKey)
    local theme = M.THEMES[themeName]
    if not theme then return nil end
    return theme.roles[roleKey]
end

--- Get accent color from a theme
---@param themeName string Theme name
---@return ColorRGB|nil Accent color {r, g, b} or nil
function M.getAccent(themeName)
    local theme = M.THEMES[themeName]
    if not theme then return nil end
    return theme.accent
end

--- Get base style variables
---@return table Base style variables
function M.getBaseStyleVars()
    return M.BASE_STYLE_VARS
end

--- Get role definitions
---@return table Array of role definition tables
function M.getRoles()
    return M.ROLES
end

return M