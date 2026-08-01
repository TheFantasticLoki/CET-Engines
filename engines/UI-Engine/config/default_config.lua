--[[
    Default Configuration — UI-Engine

    Single source of default values for all modules.
    Used by Core, Theme, and Settings modules.

    No dependencies (leaf module).
]]

local M = {}

-- --- Default Theme ---

M.DEFAULT_THEME = "Dark"

-- --- Default Accent Color ---

M.DEFAULT_ACCENT = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 }

-- --- Default Contrast Level ---

M.DEFAULT_CONTRAST = 1

-- --- Default Settings ---

M.DEFAULT_SETTINGS = {
    autoSave = true,
    autoSaveDelay = 0.5,
    settingsVersion = 1,
}

-- --- Default UI State ---

M.DEFAULT_UI = {
    selectedMod = nil,
    sidebarOpen = true,
    settingsOpen = false,
}

-- --- Default Sidebar State ---

M.DEFAULT_SIDEBAR = {
    searchQuery = "",
    favorites = {},
}

-- --- Default Features State ---

M.DEFAULT_FEATURES = {
    sectionStates = {},
    favorites = {},
}

-- --- Default Theme Settings ---

M.DEFAULT_THEME_SETTINGS = {
    currentTheme = "Dark",
    accentColor = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 },
    contrastLevel = 1,
}

-- --- Helper Functions ---

--- Get all default values
-- @return table All defaults
function M.getDefaults()
    return {
        theme = M.DEFAULT_THEME_SETTINGS,
        settings = M.DEFAULT_SETTINGS,
        ui = M.DEFAULT_UI,
        sidebar = M.DEFAULT_SIDEBAR,
        features = M.DEFAULT_FEATURES,
    }
end

--- Get theme defaults
-- @return table Theme defaults
function M.getThemeDefaults()
    return M.DEFAULT_THEME_SETTINGS
end

--- Get settings defaults
-- @return table Settings defaults
function M.getSettingsDefaults()
    return M.DEFAULT_SETTINGS
end

return M