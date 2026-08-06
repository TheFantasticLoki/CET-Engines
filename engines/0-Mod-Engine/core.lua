--[[
    Core State Store — 0-Mod-Engine

    Centralized state store for the unified CET engine. Manages all state groups
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

---@class CoreState
---@field getSelectedMod fun(): string|nil
---@field setSelectedMod fun(value: string|nil): nil
---@field getSidebarOpen fun(): boolean
---@field setSidebarOpen fun(value: boolean): nil
---@field getSettingsOpen fun(): boolean
---@field setSettingsOpen fun(value: boolean): nil
---@field getCurrentTheme fun(): string
---@field setCurrentTheme fun(value: string): nil
---@field getAccentColor fun(): ColorRGBA
---@field setAccentColor fun(value: ColorRGBA): nil
---@field getContrastLevel fun(): number
---@field setContrastLevel fun(value: number): nil
---@field getSearchQuery fun(): string
---@field setSearchQuery fun(value: string): nil
---@field getFavorites fun(): table
---@field setFavorites fun(value: table): nil
---@field getSectionState fun(id: string): any
---@field setSectionState fun(id: string, value: any): nil
---@field getSettingsVersion fun(): number
---@field setSettingsVersion fun(value: number): nil
---@field getAutoSave fun(): boolean
---@field setAutoSave fun(value: boolean): nil
---@field getPanel fun(id: string): table|nil
---@field setPanel fun(id: string, spec: table): nil
---@field removePanel fun(id: string): nil
---@field getPanelIds fun(): string[]
---@field getWindow fun(id: string): table|nil
---@field setWindow fun(id: string, spec: table): nil
---@field removeWindow fun(id: string): nil
---@field getWindowIds fun(): string[]
---@field getAllSettings fun(): table
---@field applySettings fun(data: table): nil
---@field init fun(): nil
---@field reset fun(): nil

local M = {}

-- --- Internal State ---

---@type table<string, table> Registered panel specs keyed by mod ID
local panels = {}
---@type table<string, table> Registered window specs keyed by window ID
local windows = {}
---@type UIState
local ui = {
    selectedMod = nil,
    sidebarOpen = true,
    settingsOpen = false,
}
---@type ThemeState
local theme = {
    currentTheme = "Dark",
    accentColor = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 },
    contrastLevel = 1,
}
---@type SidebarState
local sidebar = {
    searchQuery = "",
    favorites = {},
}
---@type FeaturesState
local features = {
    sectionStates = {},
    favorites = {},
}
---@type SettingsState
local settings = {
    settingsVersion = 1,
    autoSave = true,
}

---@type fun(event: string, ...: any): nil|nil Late-bound event emitter (set by Events during init)
local _emitEvent = nil

---@type boolean Initialization guard
local initialized = false

---@type Logger? Log-Engine logger instance (lazy-resolved)
local log = nil

-- Resolve Log-Engine as fallback for logging (direct require in unified mod)
do
    local ok, LogEngine = pcall(require, "log/init")
    if ok and LogEngine then
        local ok2, lgr = pcall(LogEngine.CreateLogger, "Core", { minLevel = "debug" })
        if ok2 and lgr then log = lgr end
    end
end

-- --- Event Emission ---

--- Emit an event via late-bound callback
---@param event string Event name
---@param ... any Event arguments
local function emitEvent(event, ...)
    if _emitEvent then
        _emitEvent(event, ...)
    end
end

--- Set the event emitter function (called by Events during init)
---@param emitterFn fun(event: string, ...: any): nil The event emitter function
function M.setEventEmitter(emitterFn)
    _emitEvent = emitterFn
end

-- --- UI Sub-store Getters/Setters ---

---@return string|nil
function M.getSelectedMod()
    return ui.selectedMod
end

---@param value string|nil
function M.setSelectedMod(value)
    local old = ui.selectedMod
    ui.selectedMod = value
    if old ~= value then
        emitEvent("core:selectedModChanged", value, old)
    end
end

---@return boolean
function M.getSidebarOpen()
    return ui.sidebarOpen
end

---@param value boolean
function M.setSidebarOpen(value)
    local old = ui.sidebarOpen
    ui.sidebarOpen = value
    if old ~= value then
        emitEvent("core:sidebarOpenChanged", value, old)
    end
end

---@return boolean
function M.getSettingsOpen()
    return ui.settingsOpen
end

---@param value boolean
function M.setSettingsOpen(value)
    local old = ui.settingsOpen
    ui.settingsOpen = value
    if old ~= value then
        emitEvent("core:settingsOpenChanged", value, old)
    end
end

---@return string
function M.getCurrentTheme()
    return theme.currentTheme
end

---@param value string
function M.setCurrentTheme(value)
    local old = theme.currentTheme
    theme.currentTheme = value
    if old ~= value then
        if log then log.trace("Theme changed: " .. tostring(old) .. " -> " .. tostring(value)) end
        emitEvent("core:themeChanged", value, old)
    end
end

---@return ColorRGBA
function M.getAccentColor()
    return theme.accentColor
end

---@param value ColorRGBA
function M.setAccentColor(value)
    local old = theme.accentColor
    theme.accentColor = value
    emitEvent("core:accentColorChanged", value, old)
end

---@return number
function M.getContrastLevel()
    return theme.contrastLevel
end

---@param value number
function M.setContrastLevel(value)
    local old = theme.contrastLevel
    theme.contrastLevel = value
    if old ~= value then
        emitEvent("core:contrastLevelChanged", value, old)
    end
end
---@return string
function M.getSearchQuery()
    return sidebar.searchQuery
end

---@param value string
function M.setSearchQuery(value)
    local old = sidebar.searchQuery
    sidebar.searchQuery = value
    if old ~= value then
        emitEvent("core:searchQueryChanged", value, old)
    end
end

---@return table
function M.getFavorites()
    return sidebar.favorites
end

---@param value table
function M.setFavorites(value)
    local old = sidebar.favorites
    sidebar.favorites = value
    emitEvent("core:favoritesChanged", value, old)
end

-- --- Features Sub-store Getters/Setters ---

---@param id string
---@return any
function M.getSectionState(id)
    return features.sectionStates[id]
end

---@param id string
---@param value any
function M.setSectionState(id, value)
    local old = features.sectionStates[id]
    features.sectionStates[id] = value
    if old ~= value then
        emitEvent("core:sectionStateChanged", id, value, old)
    end
end

-- --- Settings Sub-store Getters/Setters ---

---@return number
function M.getSettingsVersion()
    return settings.settingsVersion
end

---@param value number
function M.setSettingsVersion(value)
    local old = settings.settingsVersion
    settings.settingsVersion = value
    if old ~= value then
        emitEvent("core:settingsVersionChanged", value, old)
    end
end

---@return boolean
function M.getAutoSave()
    return settings.autoSave
end

---@param value boolean
function M.setAutoSave(value)
    local old = settings.autoSave
    settings.autoSave = value
    if old ~= value then
        emitEvent("core:autoSaveChanged", value, old)
    end
end

-- --- Panel Management ---

---@param id string
---@return table|nil
function M.getPanel(id)
    return panels[id]
end

---@param id string
---@param spec table
function M.setPanel(id, spec)
    panels[id] = spec
    if log then log.debug("Panel registered: " .. tostring(id)) end
    emitEvent("core:panelRegistered", id, spec)
end

---@param id string
function M.removePanel(id)
    local spec = panels[id]
    panels[id] = nil
    if spec then
        if log then log.debug("Panel removed: " .. tostring(id)) end
        emitEvent("core:panelRemoved", id)
    end
end

---@return string[]
function M.getPanelIds()
    local ids = {}
    for id, _ in pairs(panels) do
        table.insert(ids, id)
    end
    return ids
end

-- --- Window Management ---

---@param id string
---@return table|nil
function M.getWindow(id)
    return windows[id]
end

---@param id string
---@param spec table
function M.setWindow(id, spec)
    windows[id] = spec
    if log then log.debug("Window registered: " .. tostring(id)) end
    emitEvent("core:windowRegistered", id, spec)
end

---@param id string
function M.removeWindow(id)
    local spec = windows[id]
    windows[id] = nil
    if spec then
        if log then log.debug("Window removed: " .. tostring(id)) end
        emitEvent("core:windowRemoved", id)
    end
end

---@return string[]
function M.getWindowIds()
    local ids = {}
    for id, _ in pairs(windows) do
        table.insert(ids, id)
    end
    return ids
end

-- --- Bulk Serialization ---

--- Get all serializable settings as a table
---@return table All settings for serialization
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
---@param data table|nil Table of settings to apply
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
    if log then log.debug("Core initialized") end
    emitEvent("core:initComplete")
end

return M