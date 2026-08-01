--[[
    Core State Store — UI-Engine

    Centralized state store for UI-Engine. Manages all state groups
    with getters/setters that emit events on change.

    Sub-stores match ARCHITECTURE.md exactly:
    - panels: Registered mod specifications
    - windows: Standalone window registrations
    - ui: UI interaction state
    - theme: Theme configuration
    - sidebar: Sidebar state
    - features: Feature state
    - settings: Settings metadata

    Late-binding event emission: Core holds a function reference
    set by Events during init to break circular dependency.
]]

local M = {}

-- --- Internal State ---

-- Sub-stores
local panels = {}
local windows = {}
local ui = {
    selectedMod = nil,
    sidebarOpen = true,
    settingsOpen = false,
}
local theme = {
    currentTheme = "Dark",
    accentColor = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 },
    contrastLevel = 1,
}
local sidebar = {
    searchQuery = "",
    favorites = {},
}
local features = {
    sectionStates = {},
    favorites = {},
}
local settings = {
    settingsVersion = 1,
    autoSave = true,
}

-- Late-bound event emitter (set by Events during init)
local _emitEvent = nil

-- Initialization guard
local initialized = false

-- --- Event Emission ---

--- Emit an event via late-bound callback
-- @param event Event name
-- @param ... Event arguments
local function emitEvent(event, ...)
    if _emitEvent then
        _emitEvent(event, ...)
    end
end

--- Set the event emitter function (called by Events during init)
-- @param emitterFn The event emitter function
function M.setEventEmitter(emitterFn)
    _emitEvent = emitterFn
end

-- --- UI Sub-store Getters/Setters ---

function M.getSelectedMod()
    return ui.selectedMod
end

function M.setSelectedMod(value)
    local old = ui.selectedMod
    ui.selectedMod = value
    if old ~= value then
        emitEvent("core:selectedModChanged", value, old)
    end
end

function M.getSidebarOpen()
    return ui.sidebarOpen
end

function M.setSidebarOpen(value)
    local old = ui.sidebarOpen
    ui.sidebarOpen = value
    if old ~= value then
        emitEvent("core:sidebarOpenChanged", value, old)
    end
end

function M.getSettingsOpen()
    return ui.settingsOpen
end

function M.setSettingsOpen(value)
    local old = ui.settingsOpen
    ui.settingsOpen = value
    if old ~= value then
        emitEvent("core:settingsOpenChanged", value, old)
    end
end

-- --- Theme Sub-store Getters/Setters ---

function M.getCurrentTheme()
    return theme.currentTheme
end

function M.setCurrentTheme(value)
    local old = theme.currentTheme
    theme.currentTheme = value
    if old ~= value then
        emitEvent("core:themeChanged", value, old)
    end
end

function M.getAccentColor()
    return theme.accentColor
end

function M.setAccentColor(value)
    local old = theme.accentColor
    theme.accentColor = value
    emitEvent("core:accentColorChanged", value, old)
end

function M.getContrastLevel()
    return theme.contrastLevel
end

function M.setContrastLevel(value)
    local old = theme.contrastLevel
    theme.contrastLevel = value
    if old ~= value then
        emitEvent("core:contrastLevelChanged", value, old)
    end
end

-- --- Sidebar Sub-store Getters/Setters ---

function M.getSearchQuery()
    return sidebar.searchQuery
end

function M.setSearchQuery(value)
    local old = sidebar.searchQuery
    sidebar.searchQuery = value
    if old ~= value then
        emitEvent("core:searchQueryChanged", value, old)
    end
end

function M.getFavorites()
    return sidebar.favorites
end

function M.setFavorites(value)
    local old = sidebar.favorites
    sidebar.favorites = value
    emitEvent("core:favoritesChanged", value, old)
end

-- --- Features Sub-store Getters/Setters ---

function M.getSectionState(id)
    return features.sectionStates[id]
end

function M.setSectionState(id, value)
    local old = features.sectionStates[id]
    features.sectionStates[id] = value
    if old ~= value then
        emitEvent("core:sectionStateChanged", id, value, old)
    end
end

-- --- Settings Sub-store Getters/Setters ---

function M.getSettingsVersion()
    return settings.settingsVersion
end

function M.setSettingsVersion(value)
    local old = settings.settingsVersion
    settings.settingsVersion = value
    if old ~= value then
        emitEvent("core:settingsVersionChanged", value, old)
    end
end

function M.getAutoSave()
    return settings.autoSave
end

function M.setAutoSave(value)
    local old = settings.autoSave
    settings.autoSave = value
    if old ~= value then
        emitEvent("core:autoSaveChanged", value, old)
    end
end

-- --- Panel Management ---

function M.getPanel(id)
    return panels[id]
end

function M.setPanel(id, spec)
    panels[id] = spec
    emitEvent("core:panelRegistered", id, spec)
end

function M.removePanel(id)
    local spec = panels[id]
    panels[id] = nil
    if spec then
        emitEvent("core:panelRemoved", id)
    end
end

function M.getPanelIds()
    local ids = {}
    for id, _ in pairs(panels) do
        table.insert(ids, id)
    end
    return ids
end

-- --- Window Management ---

function M.getWindow(id)
    return windows[id]
end

function M.setWindow(id, spec)
    windows[id] = spec
    emitEvent("core:windowRegistered", id, spec)
end

function M.removeWindow(id)
    local spec = windows[id]
    windows[id] = nil
    if spec then
        emitEvent("core:windowRemoved", id)
    end
end

function M.getWindowIds()
    local ids = {}
    for id, _ in pairs(windows) do
        table.insert(ids, id)
    end
    return ids
end

-- --- Bulk Serialization ---

--- Get all serializable settings as a table
-- @return table All settings for serialization
function M.getAllSettings()
    return {
        ui = {
            selectedMod = ui.selectedMod,
            sidebarOpen = ui.sidebarOpen,
            settingsOpen = ui.settingsOpen,
        },
        theme = {
            currentTheme = theme.currentTheme,
            accentColor = theme.accentColor,
            contrastLevel = theme.contrastLevel,
        },
        sidebar = {
            searchQuery = sidebar.searchQuery,
            favorites = sidebar.favorites,
        },
        features = {
            sectionStates = features.sectionStates,
            favorites = features.favorites,
        },
        settings = {
            settingsVersion = settings.settingsVersion,
            autoSave = settings.autoSave,
        },
    }
end

--- Apply a table of settings (bulk update)
-- @param data Table of settings to apply
function M.applySettings(data)
    if not data then return end

    if data.ui then
        if data.ui.selectedMod ~= nil then ui.selectedMod = data.ui.selectedMod end
        if data.ui.sidebarOpen ~= nil then ui.sidebarOpen = data.ui.sidebarOpen end
        if data.ui.settingsOpen ~= nil then ui.settingsOpen = data.ui.settingsOpen end
    end

    if data.theme then
        if data.theme.currentTheme ~= nil then theme.currentTheme = data.theme.currentTheme end
        if data.theme.accentColor ~= nil then theme.accentColor = data.theme.accentColor end
        if data.theme.contrastLevel ~= nil then theme.contrastLevel = data.theme.contrastLevel end
    end

    if data.sidebar then
        if data.sidebar.searchQuery ~= nil then sidebar.searchQuery = data.sidebar.searchQuery end
        if data.sidebar.favorites ~= nil then sidebar.favorites = data.sidebar.favorites end
    end

    if data.features then
        if data.features.sectionStates ~= nil then features.sectionStates = data.features.sectionStates end
        if data.features.favorites ~= nil then features.favorites = data.features.favorites end
    end

    if data.settings then
        if data.settings.settingsVersion ~= nil then settings.settingsVersion = data.settings.settingsVersion end
        if data.settings.autoSave ~= nil then settings.autoSave = data.settings.autoSave end
    end

    emitEvent("core:settingsApplied", data)
end

-- --- Initialization ---

--- Reset all state to defaults (for testing)
function M.reset()
    -- Reset sub-stores to defaults
    panels = {}
    windows = {}
    ui.selectedMod = nil
    ui.sidebarOpen = true
    ui.settingsOpen = false
    theme.currentTheme = "Dark"
    theme.accentColor = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 }
    theme.contrastLevel = 1
    sidebar.searchQuery = ""
    sidebar.favorites = {}
    features.sectionStates = {}
    features.favorites = {}
    settings.settingsVersion = 1
    settings.autoSave = true
    initialized = false
end

--- Initialize the core module (idempotent)
function M.init()
    if initialized then
        return
    end
    initialized = true
    emitEvent("core:initComplete")
end

return M