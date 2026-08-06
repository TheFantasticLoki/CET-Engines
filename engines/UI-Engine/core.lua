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

---@class CoreState
---Centralized state store for UI-Engine.
---@field getSelectedMod fun(): string|nil
---@field setSelectedMod fun(value: string|nil)
---@field getSidebarOpen fun(): boolean
---@field setSidebarOpen fun(value: boolean)
---@field getSettingsOpen fun(): boolean
---@field setSettingsOpen fun(value: boolean)
---@field getCurrentTheme fun(): string
---@field setCurrentTheme fun(value: string)
---@field getAccentColor fun(): ColorTable
---@field setAccentColor fun(value: ColorTable)
---@field getContrastLevel fun(): number
---@field setContrastLevel fun(value: number)
---@field getSearchQuery fun(): string
---@field setSearchQuery fun(value: string)
---@field getFavorites fun(): table
---@field setFavorites fun(value: table)
---@field getSectionState fun(id: string): any
---@field setSectionState fun(id: string, value: any)
---@field getSettingsVersion fun(): number
---@field setSettingsVersion fun(value: number)
---@field getAutoSave fun(): boolean
---@field setAutoSave fun(value: boolean)
---@field getPanel fun(id: string): table|nil
---@field setPanel fun(id: string, spec: table)
---@field removePanel fun(id: string)
---@field getPanelIds fun(): string[]
---@field getWindow fun(id: string): table|nil
---@field setWindow fun(id: string, spec: table)
---@field removeWindow fun(id: string)
---@field getWindowIds fun(): string[]
---@field getAllSettings fun(): table
---@field applySettings fun(data: table)
---@field init fun()
---@field reset fun()
---@field setEventEmitter fun(emitterFn: fun(event: string, ...: any))

---@class UIState
---@field selectedMod string|nil
---@field sidebarOpen boolean
---@field settingsOpen boolean

---@class ThemeState
---@field currentTheme string
---@field accentColor ColorTable
---@field contrastLevel number

---@class SidebarState
---@field searchQuery string
---@field favorites table<string, boolean>

---@class FeaturesState
---@field sectionStates table<string, boolean>
---@field favorites table<string, boolean>

---@class SettingsState
---@field settingsVersion number
---@field autoSave boolean

local M = {}

-- --- Internal State ---

-- Logger instance
local log = nil ---@type Logger?

-- Sub-stores
---@type table<string, table>
local panels = {}
---@type table<string, table>
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

-- Late-bound event emitter (set by Events during init)
---@type fun(event: string, ...: any)|nil
local _emitEvent = nil

-- Initialization guard
local initialized = false

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
---@param emitterFn fun(event: string, ...: any) The event emitter function
function M.setEventEmitter(emitterFn)
    _emitEvent = emitterFn
end

--- Resolve Log-Engine for logging support
---@param deps? table Optional dependency table with log field
function M.resolveLogger(deps)
    if deps and deps.log then
        log = deps.log
    elseif _LogEngine then
        local ok, logger = pcall(_LogEngine.CreateLogger, "Core", { minLevel = "debug" })
        if ok and logger then log = logger end
    end
end

-- --- UI Sub-store Getters/Setters ---

--- Get the currently selected mod ID
---@return string|nil selectedMod
function M.getSelectedMod()
    return ui.selectedMod
end

--- Set the currently selected mod ID
---@param value string|nil New selected mod ID
function M.setSelectedMod(value)
    local old = ui.selectedMod
    ui.selectedMod = value
    if old ~= value then
        emitEvent("core:selectedModChanged", value, old)
    end
end

--- Get sidebar open state
---@return boolean isOpen
function M.getSidebarOpen()
    return ui.sidebarOpen
end

--- Set sidebar open state
---@param value boolean New sidebar state
function M.setSidebarOpen(value)
    local old = ui.sidebarOpen
    ui.sidebarOpen = value
    if old ~= value then
        emitEvent("core:sidebarOpenChanged", value, old)
    end
end

--- Get settings panel open state
---@return boolean isOpen
function M.getSettingsOpen()
    return ui.settingsOpen
end

--- Set settings panel open state
---@param value boolean New settings state
function M.setSettingsOpen(value)
    local old = ui.settingsOpen
    ui.settingsOpen = value
    if old ~= value then
        emitEvent("core:settingsOpenChanged", value, old)
    end
end

-- --- Theme Sub-store Getters/Setters ---

--- Get the current theme name
---@return string themeName
function M.getCurrentTheme()
    return theme.currentTheme
end

--- Set the current theme name
---@param value string New theme name
function M.setCurrentTheme(value)
    local old = theme.currentTheme
    theme.currentTheme = value
    if old ~= value then
        if log then log.trace("Theme changed: " .. tostring(old) .. " -> " .. tostring(value)) end
        emitEvent("core:themeChanged", value, old)
    end
end

--- Get the current accent color
---@return ColorTable accentColor
function M.getAccentColor()
    return theme.accentColor
end

--- Set the accent color
---@param value ColorTable New accent color {r, g, b, a?}
function M.setAccentColor(value)
    local old = theme.accentColor
    theme.accentColor = value
    emitEvent("core:accentColorChanged", value, old)
end

--- Get the current contrast level (1-3)
---@return number contrastLevel
function M.getContrastLevel()
    return theme.contrastLevel
end

--- Set the contrast level
---@param value number New contrast level (1-3)
function M.setContrastLevel(value)
    local old = theme.contrastLevel
    theme.contrastLevel = value
    if old ~= value then
        emitEvent("core:contrastLevelChanged", value, old)
    end
end

-- --- Sidebar Sub-store Getters/Setters ---

--- Get the current search query string
---@return string query
function M.getSearchQuery()
    return sidebar.searchQuery
end

--- Set the search query string
---@param value string New search query
function M.setSearchQuery(value)
    local old = sidebar.searchQuery
    sidebar.searchQuery = value
    if old ~= value then
        emitEvent("core:searchQueryChanged", value, old)
    end
end

--- Get the favorites table
---@return table<string, boolean> favorites
function M.getFavorites()
    return sidebar.favorites
end

--- Set the favorites table
---@param value table<string, boolean> New favorites table
function M.setFavorites(value)
    local old = sidebar.favorites
    sidebar.favorites = value
    emitEvent("core:favoritesChanged", value, old)
end

-- --- Features Sub-store Getters/Setters ---

--- Get the collapsed/expanded state of a section
---@param id string Section identifier
---@return boolean|nil state
function M.getSectionState(id)
    return features.sectionStates[id]
end

--- Set the collapsed/expanded state of a section
---@param id string Section identifier
---@param value boolean|nil New state
function M.setSectionState(id, value)
    local old = features.sectionStates[id]
    features.sectionStates[id] = value
    if old ~= value then
        emitEvent("core:sectionStateChanged", id, value, old)
    end
end

-- --- Settings Sub-store Getters/Setters ---

--- Get the settings format version
---@return number version
function M.getSettingsVersion()
    return settings.settingsVersion
end

--- Set the settings format version
---@param value number New version number
function M.setSettingsVersion(value)
    local old = settings.settingsVersion
    settings.settingsVersion = value
    if old ~= value then
        emitEvent("core:settingsVersionChanged", value, old)
    end
end

--- Get whether auto-save is enabled
---@return boolean enabled
function M.getAutoSave()
    return settings.autoSave
end

--- Set whether auto-save is enabled
---@param value boolean New auto-save state
function M.setAutoSave(value)
    local old = settings.autoSave
    settings.autoSave = value
    if old ~= value then
        emitEvent("core:autoSaveChanged", value, old)
    end
end

-- --- Panel Management ---

--- Get a panel specification by ID
---@param id string Panel identifier
---@return table|nil spec
function M.getPanel(id)
    return panels[id]
end

--- Register or update a panel specification
---@param id string Panel identifier
---@param spec table Panel specification table
function M.setPanel(id, spec)
    panels[id] = spec
    if log then log.debug("Panel registered: " .. tostring(id)) end
    emitEvent("core:panelRegistered", id, spec)
end

--- Remove a panel specification
---@param id string Panel identifier
function M.removePanel(id)
    local spec = panels[id]
    panels[id] = nil
    if spec then
        if log then log.debug("Panel removed: " .. tostring(id)) end
        emitEvent("core:panelRemoved", id)
    end
end

--- Get all registered panel IDs
---@return string[] ids
function M.getPanelIds()
    local ids = {}
    for id, _ in pairs(panels) do
        table.insert(ids, id)
    end
    return ids
end

-- --- Window Management ---

--- Get a window specification by ID
---@param id string Window identifier
---@return table|nil spec
function M.getWindow(id)
    return windows[id]
end

--- Register or update a window specification
---@param id string Window identifier
---@param spec table Window specification table
function M.setWindow(id, spec)
    windows[id] = spec
    if log then log.debug("Window registered: " .. tostring(id)) end
    emitEvent("core:windowRegistered", id, spec)
end

--- Remove a window specification
---@param id string Window identifier
function M.removeWindow(id)
    local spec = windows[id]
    windows[id] = nil
    if spec then
        if log then log.debug("Window removed: " .. tostring(id)) end
        emitEvent("core:windowRemoved", id)
    end
end

--- Get all registered window IDs
---@return string[] ids
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
---@param data table Table of settings to apply
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
---@return nil
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
---@return nil
function M.init()
    if initialized then
        return
    end
    initialized = true
    emitEvent("core:initComplete")
end

return M