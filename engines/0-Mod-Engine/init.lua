---@class ModEngine
--- 0-Mod-Engine — Unified CET Mod Entry Point
---
--- Combines Log-Engine, UI-Engine, and Config-Engine into a single CET mod.
--- Eliminates race conditions by using direct require() instead of GetMod().
---
--- Public API: ModEngine (global), backward-compat: UIEngine, ConfigEngine, LogEngine
---
--- Module loading order:
--- 0. Log-Engine        (safety-net logging -- first thing loaded)
--- 1. core.lua          (state store -- no dependencies)
--- 2. modules/logger.lua (logging -- no dependencies)
--- 3. modules/storage.lua (persistence -- depends on logger)
--- 4. api/events.lua    (pub/sub -- depends on core)
--- 5. ui/utils.lua      (utilities -- no dependencies)
--- 6. Theme engine       (depends on core)
--- 7. Components         (depends on core, theme)
--- 8. Registry           (depends on core, events)
--- 9. Context            (depends on core, events, components)
--- 10. Windows           (depends on core, events)
--- 11. Config-Engine     (depends on UI-Engine modules)
---
---@version 1.0.0-unified
---@license MIT

-- ============================================================================
-- SafeRequire Pattern
-- ============================================================================

--- Safely require a module with pcall
---@param path string Module path
---@return table? mod Module table or nil if not found
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then
        return mod
    end
    print("[ModEngine] FAILED to load '" .. path .. "': " .. tostring(mod))
    return nil
end

-- ============================================================================
-- Phase 0: Log-Engine (first -- other modules depend on logging)
-- ============================================================================

local LogEngine = SafeRequire("log/init")
local _LogEngine = LogEngine  -- private ref, survives backward compat overwrite

-- ============================================================================
-- Phase 1: Core Systems (no dependencies between them)
-- ============================================================================

local Core = SafeRequire("core")
local Logger = SafeRequire("modules/logger")
local Storage = SafeRequire("modules/storage")
local Events = SafeRequire("api/events")
local Utils = SafeRequire("ui/utils")

-- ============================================================================
-- Phase 2: Theme Engine (depends on core)
-- ============================================================================

local ThemeDefs = SafeRequire("config/themes")
local ColorEngine = SafeRequire("ui/color_engine")
local Tokens = SafeRequire("ui/tokens")
local DefaultConfig = SafeRequire("config/default_config")
local Theme = SafeRequire("ui/theme")
local Animation = SafeRequire("ui/animation")

-- ============================================================================
-- Phase 3: Components & APIs (depends on core, theme)
-- ============================================================================

local Components = SafeRequire("ui/components")
local Registry = SafeRequire("api/registry")
local Context = SafeRequire("api/context")
local Windows = SafeRequire("api/windows")

-- ============================================================================
-- Phase 4: Config-Engine Modules
-- ============================================================================

local CfgCore = SafeRequire("cfg/core")
local CfgModManager = SafeRequire("cfg/mod_manager")
local CfgSchema = SafeRequire("cfg/settings_schema")
local CfgResolver = SafeRequire("cfg/settings_resolver")
local CfgRenderer = SafeRequire("cfg/settings_renderer")
local CfgUndoRedo = SafeRequire("cfg/undo_redo")
local CfgStateSync = SafeRequire("cfg/state_sync")
local CfgRenderMode = SafeRequire("cfg/render_mode")
local CfgWindow = SafeRequire("cfg/ui/window")
local CfgSidebar = SafeRequire("cfg/ui/sidebar")
local CfgContentArea = SafeRequire("cfg/ui/content_area")
local EngineSchemas = SafeRequire("config/engine_schemas")

-- New modules for features
local SearchParser = SafeRequire("cfg/search_parser")
local TestResults = SafeRequire("cfg/test_results")
local TestRunner = SafeRequire("cfg/test_runner")
local Categories = SafeRequire("config/categories")

-- ============================================================================
-- State
-- ============================================================================

---@type boolean
local initialized = false
---@type number
local frameCount = 0
---@type boolean
local overlayOpen = false
---@type Logger?
local log = nil  -- Log-Engine logger for this module

-- ============================================================================
-- Helper: Create a logger via Log-Engine
-- ============================================================================

--- Create a logger via Log-Engine (pcall-safe)
---@param modName string Unique mod identifier
---@param config? table Logger configuration overrides
---@return Logger? logger Logger instance or nil
local function createLogger(modName, config)
    if not _LogEngine then
        return nil
    end
    local ok, logger = pcall(_LogEngine.CreateLogger, modName, config)
    if not ok then
        print("[ModEngine] createLogger error: " .. tostring(logger))
        return nil
    end
    return logger
end

-- ============================================================================
-- Public API Functions
-- ============================================================================

--- Register a mod with UI-Engine
---@param id string Mod identifier
---@param spec table Mod specification table
---@return boolean, string? success, error message
local function Register(id, spec)
    if not Core then
        return false, "Core module not loaded"
    end
    if not id or type(id) ~= "string" then
        return false, "Invalid mod ID"
    end
    if not spec or type(spec) ~= "table" then
        return false, "Invalid mod specification"
    end
    Core.setPanel(id, spec)
    if Events then
        Events.emit("uiengine:registered", id, spec)
    end
    return true, nil
end

--- Unregister a mod from UI-Engine
---@param id string Mod identifier
---@return boolean, string? success, error message
local function Unregister(id)
    if not Core then
        return false, "Core module not loaded"
    end
    if not id or type(id) ~= "string" then
        return false, "Invalid mod ID"
    end
    Core.removePanel(id)
    if Events then
        Events.cleanup(id)
        Events.emit("uiengine:unregistered", id)
    end
    return true, nil
end

--- Get a context object for a mod
---@param id string Mod identifier
---@return table? ctx Context object or nil
local function GetContext(id)
    if not Core then
        return nil
    end
    local spec = Core.getPanel(id)
    if not spec then
        return nil
    end
    if Context then
        return Context.create(id, spec)
    end
    return {
        modId = id,
        spec = spec,
    }
end

--- Get the current theme
---@return string Current theme name
local function GetTheme()
    if not Core then
        return "Dark"
    end
    return Core.getCurrentTheme()
end

--- Set the current theme
---@param themeName Theme name
---@return boolean success
local function SetTheme(themeName)
    if Theme and Theme.SetTheme then
        return Theme.SetTheme(themeName)
    end
    if not Core then
        return false
    end
    Core.setCurrentTheme(themeName)
    return true
end

--- Get the list of available themes
---@return string[] themeNames Array of theme names
local function GetThemeList()
    if Theme then
        return Theme.GetThemeList()
    end
    return { "Dark" }
end

--- Get the current contrast level
---@return number contrastLevel 1=normal, 2=high, 3=very high
local function GetContrastLevel()
    if not Core then return 1 end
    return Core.getContrastLevel() or 1
end

--- Set the contrast level
---@param level number 1=normal, 2=high, 3=very high
local function SetContrastLevel(level)
    if Theme and Theme.SetHighContrast then
        Theme.SetHighContrast(level)
    elseif Core then
        Core.setContrastLevel(level)
    end
end

--- Subscribe to an event
---@param event string Event name
---@param handler function Handler function
---@param source? string Source label
---@return function unsubscribe Unsubscribe function
local function On(event, handler, source)
    if not Events then
        return function() end
    end
    return Events.on(event, handler, source)
end

--- Emit an event
---@param event string Event name
---@param ... any Event arguments
local function Emit(event, ...)
    if not Events then
        return
    end
    Events.emit(event, ...)
end

--- Unsubscribe from an event
---@param event string Event name
---@param handler function Handler function to remove
local function Off(event, handler)
    if not Events then
        return
    end
    Events.off(event, handler)
end

--- Check if a mod is registered
---@param id string Mod identifier
---@return boolean True if registered
local function IsRegistered(id)
    if not Core then
        return false
    end
    return Core.getPanel(id) ~= nil
end

--- Get list of registered mod IDs
---@return string[] modIds Array of mod IDs
local function GetRegisteredMods()
    if not Core then
        return {}
    end
    return Core.getPanelIds()
end

--- Get the version string
---@return string Version string
local function GetVersion()
    return "v1.0.0-unified"
end

--- Enable a mod
---@param id string Mod identifier
---@return boolean, string? success, error message
local function Enable(id)
    if not Core then
        return false, "Core module not loaded"
    end
    local spec = Core.getPanel(id)
    if not spec then
        return false, "Mod not registered: " .. tostring(id)
    end
    spec.enabled = true
    if Events then
        Events.emit("uiengine:modEnabled", id)
    end
    return true, nil
end

--- Disable a mod
---@param id string Mod identifier
---@return boolean, string? success, error message
local function Disable(id)
    if not Core then
        return false, "Core module not loaded"
    end
    local spec = Core.getPanel(id)
    if not spec then
        return false, "Mod not registered: " .. tostring(id)
    end
    spec.enabled = false
    if Events then
        Events.emit("uiengine:modDisabled", id)
    end
    return true, nil
end

--- Check if overlay is open
---@return boolean True if overlay is visible
local function IsOverlayOpen()
    return overlayOpen
end

--- Register a standalone window
---@param id string Window identifier
---@param spec table Window specification {title, width, height, draw_fn}
---@return boolean, string? success, error message
local function RegisterWindow(id, spec)
    if not Windows then
        return false, "Windows module not loaded"
    end
    return Windows.register(id, spec)
end

-- ============================================================================
-- Config-Engine Public API Wrappers
-- ============================================================================

--- Register a mod with Config-Engine (settings schema)
---@param modId string Mod identifier
---@param spec table Mod specification with settings schema
---@return boolean, string? success, error message
local function ConfigRegister(modId, spec)
    if not CfgModManager then
        return false, "Config-Engine not initialized"
    end
    return CfgModManager.register(modId, spec)
end

--- Unregister a mod from Config-Engine
---@param modId string Mod identifier
---@return boolean success
local function ConfigUnregister(modId)
    if not CfgModManager then
        return false
    end
    return CfgModManager.unregister(modId)
end

--- Get a registered mod's info from Config-Engine
---@param modId string Mod identifier
---@return table? modInfo Mod info or nil
local function ConfigGetMod(modId)
    if not CfgModManager then
        return nil
    end
    return CfgModManager.getModInfo(modId)
end

--- Get all registered mods from Config-Engine
---@return table[] modList Array of mod info tables
local function ConfigGetMods()
    if not CfgModManager then
        return {}
    end
    return CfgModManager.getModList()
end

--- Get settings for a mod from Config-Engine
---@param modId string Mod identifier
---@return table? settings Mod settings or nil
local function ConfigGetSettings(modId)
    if not CfgModManager then
        return nil
    end
    return CfgModManager.getSettings(modId)
end

--- Update settings for a mod in Config-Engine
---@param modId string Mod identifier
---@param settings table New settings values
---@return boolean success
local function ConfigSetSettings(modId, settings)
    if not CfgModManager then
        return false
    end
    return CfgModManager.updateSettings(modId, settings)
end

--- Reset settings for a mod to defaults
---@param modId string Mod identifier
---@return boolean success
local function ConfigResetSettings(modId)
    if not CfgModManager then
        return false
    end
    return CfgModManager.resetSettings(modId)
end

--- Undo the last Config-Engine setting change
---@return boolean success
local function ConfigUndo()
    if not CfgUndoRedo then
        return false
    end
    return CfgUndoRedo.undo(function(cmd)
        if cmd.type == "setting" then
            local mod = CfgCore.getMod(cmd.modId)
            if mod and mod.settings then
                CfgResolver.setValue(mod.settings, cmd.key, cmd.oldValue)
                CfgCore.markDirty()
                return true
            end
            return false
        end
        return false
    end) ~= nil
end

--- Redo the last undone Config-Engine setting change
---@return boolean success
local function ConfigRedo()
    if not CfgUndoRedo then
        return false
    end
    return CfgUndoRedo.redo(function(cmd)
        if cmd.type == "setting" then
            local mod = CfgCore.getMod(cmd.modId)
            if mod and mod.settings then
                CfgResolver.setValue(mod.settings, cmd.key, cmd.newValue)
                CfgCore.markDirty()
                return true
            end
            return false
        end
        return false
    end) ~= nil
end

--- Check if undo is available
---@return boolean
local function ConfigCanUndo()
    if not CfgUndoRedo then
        return false
    end
    return CfgUndoRedo.canUndo()
end

--- Check if redo is available
---@return boolean
local function ConfigCanRedo()
    if not CfgUndoRedo then
        return false
    end
    return CfgUndoRedo.canRedo()
end

-- ============================================================================
-- Engine Registration with Config-Engine
-- ============================================================================

--- Register built-in engine schemas with Config-Engine
local function registerEngines()
    if not CfgModManager then
        print("[ModEngine] ModManager not loaded, cannot register engines")
        return
    end
    if not EngineSchemas then
        print("[ModEngine] No engine schemas to register")
        return
    end
    local count = 0
    for engineId, schema in pairs(EngineSchemas) do
        if not CfgCore.getMod(engineId) then
            local regOk, err = CfgModManager.register(engineId, schema)
            if regOk then
                print("[ModEngine] Registered engine: " .. engineId)
                count = count + 1
            else
                print("[ModEngine] Failed to register " .. engineId .. ": " .. tostring(err))
            end
        end
    end
    if count > 0 then
        print("[ModEngine] Registered " .. count .. " engine(s)")
    end
end

--- Bridge saved engine settings to actual engine subsystems at startup.
--- Called after registerEngines() so saved settings override hardcoded defaults.
local function bridgeEngineSettings()
    if not CfgCore then return end

    -- UI-Engine settings
    local uiMod = CfgCore.getMod("0-Engine-UI")
    if uiMod and uiMod.settings then
        local s = uiMod.settings
        if s.currentTheme and Theme and Theme.SetTheme then
            Theme.SetTheme(s.currentTheme)
        end
        if s.contrastLevel and Theme and Theme.SetHighContrast then
            Theme.SetHighContrast(s.contrastLevel)
        end
        if s.accentColor and Core and Core.setAccentColor then
            Core.setAccentColor(s.accentColor)
        end
        if s.autoSave ~= nil and Core and Core.setAutoSave then
            Core.setAutoSave(s.autoSave)
        end
        if s.showSidebar ~= nil and Core and Core.setSidebarOpen then
            Core.setSidebarOpen(s.showSidebar)
        end
        if s.showLoggerOverlay ~= nil and Logger and Logger.SetOverlay then
            Logger.SetOverlay(s.showLoggerOverlay)
        end
        if s.maxDebugPerFrame and Logger and Logger.SetMaxDebugPerFrame then
            Logger.SetMaxDebugPerFrame(s.maxDebugPerFrame)
        end
    end

    -- Log-Engine settings
    local logMod = CfgCore.getMod("0-Engine-Log")
    if logMod and logMod.settings and _LogEngine then
        local s = logMod.settings
        if s.globalMinLevel then _LogEngine.SetGlobalLevel(s.globalMinLevel) end
        if s.logDir then _LogEngine.setLogDir(s.logDir) end
        if s.maxFileSize then _LogEngine.setMaxFileSize(s.maxFileSize) end
        if s.maxFiles then _LogEngine.setMaxFiles(s.maxFiles) end
        if s.maxDebugPerFrame then _LogEngine.setMaxDebugPerFrame(s.maxDebugPerFrame) end
        if s.dedupEnabled ~= nil then _LogEngine.setDedupEnabled(s.dedupEnabled) end
        if s.dedupMaxEntries then _LogEngine.setDedupMaxEntries(s.dedupMaxEntries) end
        if s.ringSize then _LogEngine.setRingSize(s.ringSize) end
    end

    -- Config-Engine settings
    local cfgMod = CfgCore.getMod("0-Engine-Config")
    if cfgMod and cfgMod.settings then
        local s = cfgMod.settings
        if s.sidebarWidth and Core and Core.setSidebarWidth then
            CfgCore.setSidebarWidth(s.sidebarWidth)
        end
        if s.sortMode then
            local _, sortAsc = CfgCore.getSortMode()
            CfgCore.setSortMode(s.sortMode, sortAsc)
        end
        if s.sortAscending ~= nil then
            local sortMode = CfgCore.getSortMode()
            CfgCore.setSortMode(sortMode, s.sortAscending)
        end
        if s.compactMode ~= nil and CfgCore.setCompactMode then
            CfgCore.setCompactMode(s.compactMode)
        end
        if s.maxUndoSteps and CfgUndoRedo then
            CfgUndoRedo.init({ maxSteps = s.maxUndoSteps, maxRedoSteps = s.maxRedoSteps or 50 })
        end
    end
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

local function initModules()
    if initialized then return end
    initialized = true

    -- Create logger for this module
    log = createLogger("ModEngine", { minLevel = "debug" })
    if log then log.info("=== onInit START ===") end

    -- Initialize Log-Engine
    if _LogEngine and _LogEngine.onInit then
        _LogEngine.onInit()
        if log then log.info("Log-Engine initialized") end
    end

    -- Initialize core
    if Core then
        Core.init()
        if log then log.info("Core initialized") end
    end

    -- Initialize storage
    if Storage then
        Storage.init(Logger)
        if log then log.info("Storage initialized") end
    end

    -- Initialize events
    if Events then
        Events.init(Logger, Core)
        if log then log.info("Events initialized") end
    end

    -- Initialize theme
    if Theme and Theme.init then
        Theme.init(Core, ColorEngine, Tokens, ThemeDefs, Logger)
        if log then log.info("Theme initialized") end
    end

    -- Initialize components
    if Components and Components.init then
        Components.init(Logger, Core, Theme)
        if log then log.info("Components initialized") end
    end

    -- Initialize registry
    if Registry and Registry.init then
        Registry.init({ Core = Core, Events = Events, Logger = Logger })
        if log then log.info("Registry initialized") end
    end

    -- Initialize context
    if Context and Context.init then
        Context.init({ Core = Core, Events = Events, Components = Components, Tokens = Tokens, Utils = Utils })
        if log then log.info("Context initialized") end
    end

    -- Initialize windows
    if Windows and Windows.init then
        Windows.init({ Core = Core, Events = Events, Logger = Logger })
        if log then log.info("Windows initialized") end
    end

    -- Initialize Config-Engine modules
    if CfgCore then
        CfgCore.init()
        if log then log.info("CfgCore initialized") end
    end

    if CfgModManager then
        CfgModManager.init({
            core = CfgCore or Core,
            events = Events,
            modEngine = ModEngine,
            logger = log,
        })
        if log then log.info("CfgModManager initialized") end
    end

    if CfgRenderer then
        CfgRenderer.init({
            core = CfgCore or Core,
            events = Events,
            components = Components,
            undoRedo = CfgUndoRedo,
            resolver = CfgResolver,
        })
        if log then log.info("CfgRenderer initialized") end
    end

    if CfgUndoRedo then
        -- Read maxUndoSteps and maxRedoSteps from saved settings
        local undoSteps = 50
        local redoSteps = 50
        local cfgMod = CfgCore and CfgCore.getMod("0-Engine-Config")
        if cfgMod and cfgMod.settings then
            if cfgMod.settings.maxUndoSteps then undoSteps = cfgMod.settings.maxUndoSteps end
            if cfgMod.settings.maxRedoSteps then redoSteps = cfgMod.settings.maxRedoSteps end
        end
        CfgUndoRedo.init({ maxSteps = undoSteps, maxRedoSteps = redoSteps })
        if log then log.info("CfgUndoRedo initialized") end
    end

    if CfgStateSync then
        -- Read autoSaveDelayFrames from saved settings
        local saveDelay = 30
        local cfgMod = CfgCore and CfgCore.getMod("0-Engine-Config")
        if cfgMod and cfgMod.settings and cfgMod.settings.autoSaveDelayFrames then
            saveDelay = cfgMod.settings.autoSaveDelayFrames
        end
        CfgStateSync.init({
            core = CfgCore or Core,
            storage = Storage,
            logger = log,
            config = { AUTO_SAVE_DELAY_FRAMES = saveDelay },
        })
        if log then log.info("CfgStateSync initialized") end
    end

    -- Initialize test system
    if TestResults then
        if log then log.info("TestResults initialized") end
    end

    if TestRunner then
        TestRunner.init({
            core = CfgCore or Core,
            testResults = TestResults,
            logger = log,
        })
        if log then log.info("TestRunner initialized") end
    end

    if CfgWindow then
        CfgWindow.init({
            core = CfgCore or Core,
            components = Components,
            tokens = Tokens,
        })
        if log then log.info("CfgWindow initialized") end
    end

    if CfgSidebar then
        CfgSidebar.init({
            core = CfgCore or Core,
            searchParser = SearchParser,
            testResults = TestResults,
            categories = Categories,
        })
        if log then log.info("CfgSidebar initialized") end
    end

    if CfgContentArea then
        CfgContentArea.init({
            core = CfgCore or Core,
            settingsRenderer = CfgRenderer,
            resolver = CfgResolver,
            undoRedo = CfgUndoRedo,
            stateSync = CfgStateSync,
            testResults = TestResults,
            testRunner = TestRunner,
        })
        if log then log.info("CfgContentArea initialized") end
    end

    -- Register engines
    registerEngines()

    -- Bridge saved settings to engine subsystems
    bridgeEngineSettings()

    -- Emit init complete event
    if Events then
        Events.emit("modengine:initComplete")
    end

    -- Run startup tests after all modules are initialized
    if TestRunner then
        TestRunner.runStartupTests()
        if log then log.info("Startup tests completed") end
    end

    if log then log.info("=== onInit END ===") end
    print("[ModEngine] v1.0.0-unified loaded")
end

-- ============================================================================
-- Public API (Global)
-- ============================================================================

--- Log a message via both Logger (ring buffer) and Log-Engine (file output)
---@param modName string Module name
---@param message string Log message
---@param level string? Level name string ("info", "warn", "error", "debug")
local function Log(modName, message, level)
    -- Log to UI-Engine's internal Logger (overlay, ring buffer)
    if Logger then
        Logger.Log(modName, message, level)
    end
    -- Also log to Log-Engine (file output, cross-mod visibility)
    if log then
        log.log(level or "info", "[" .. modName .. "] " .. message)
    end
end

ModEngine = {
    -- Log subsystem
    Log = Log,
    CreateLogger = function(modName, config)
        return createLogger(modName, config)
    end,
    GetLogger = function(modName)
        if _LogEngine then return _LogEngine.GetLogger(modName) end
        return nil
    end,
    GetLoggerNames = function()
        if _LogEngine then return _LogEngine.GetLoggerNames() end
        return {}
    end,
    GetStats = function()
        if _LogEngine then return _LogEngine.GetStats() end
        return {}
    end,
    GetRecentErrors = function(count)
        if _LogEngine then return _LogEngine.GetRecentErrors(count) end
        return {}
    end,
    GetModSummary = function()
        if _LogEngine then return _LogEngine.GetModSummary() end
        return {}
    end,
    SetGlobalLevel = function(level)
        if _LogEngine then _LogEngine.SetGlobalLevel(level) end
    end,
    FlushAll = function()
        if _LogEngine then _LogEngine.FlushAll() end
    end,

    -- UI subsystem
    Register = Register,
    Unregister = Unregister,
    GetContext = GetContext,
    GetTheme = GetTheme,
    SetTheme = SetTheme,
    GetThemeList = GetThemeList,
    GetContrastLevel = GetContrastLevel,
    SetContrastLevel = SetContrastLevel,
    IsRegistered = IsRegistered,
    GetRegisteredMods = GetRegisteredMods,
    Enable = Enable,
    Disable = Disable,
    RegisterWindow = RegisterWindow,

    -- Config subsystem
    RegisterMod = ConfigRegister,
    UnregisterMod = ConfigUnregister,
    GetMod = ConfigGetMod,
    GetMods = ConfigGetMods,
    GetModSettings = ConfigGetSettings,
    SetModSettings = ConfigSetSettings,
    ResetModSettings = ConfigResetSettings,
    Undo = ConfigUndo,
    Redo = ConfigRedo,
    CanUndo = ConfigCanUndo,
    CanRedo = ConfigCanRedo,

    -- Events
    On = On,
    Emit = Emit,
    Off = Off,

    -- Status
    IsOverlayOpen = IsOverlayOpen,
    GetVersion = GetVersion,

    -- Internal modules (for advanced use)
    Core = Core,
    Events = Events,
    Theme = Theme,
    Tokens = Tokens,
    Components = Components,
    Storage = Storage,
    Logger = Logger,
    Registry = Registry,
    Context = Context,
    Windows = Windows,
    _LogEngine = _LogEngine,
}

-- ============================================================================
-- Backward Compatibility (deprecated)
-- ============================================================================

UIEngine = ModEngine
ConfigEngine = ModEngine
LogEngine = ModEngine

-- ============================================================================
-- CET Callbacks
-- ============================================================================

registerForEvent("onInit", initModules)

registerForEvent("onDraw", function()
    -- Only draw when CET overlay is open
    if not overlayOpen then return end

    frameCount = frameCount + 1

    -- Update frame counters
    if Logger then Logger.SetFrame(frameCount) end
    if Utils and Utils.updateFrame then Utils.updateFrame(frameCount) end

    -- Update Log-Engine frame counter
    if _LogEngine and _LogEngine.onDraw then
        _LogEngine.onDraw()
    end

    -- SINGLE pcall wrapping all ImGui calls (CET FFI breaks with per-call pcall)
    local drawOk, drawErr = pcall(function()
        -- Push theme
        if Theme then Theme.PushTheme() end

        -- Draw standalone windows
        if Windows and Windows.drawAll then Windows.drawAll() end

        -- Draw Config-Engine window (inline, same pattern as original)
        if CfgCore and CfgModManager then
            -- Read window size from settings
            local winW, winH = 800, 600
            local cfgMod = CfgCore.getMod("0-Engine-Config")
            if cfgMod and cfgMod.settings then
                if cfgMod.settings.defaultWindowWidth then winW = cfgMod.settings.defaultWindowWidth end
                if cfgMod.settings.defaultWindowHeight then winH = cfgMod.settings.defaultWindowHeight end
            end
            ImGui.SetNextWindowSize(winW, winH, ImGuiCond.FirstUseEver)
            if ImGui.Begin("Config Engine") then
                -- Menu bar
                if ImGui.BeginMenuBar() then
                    if ImGui.BeginMenu("Edit") then
                        if ImGui.MenuItem("Undo", nil, false, ConfigCanUndo()) then
                            ConfigUndo()
                        end
                        if ImGui.MenuItem("Redo", nil, false, ConfigCanRedo()) then
                            ConfigRedo()
                        end
                        ImGui.EndMenu()
                    end
                    ImGui.EndMenuBar()
                end

                -- Main content: sidebar + content area
                local sidebarWidth = CfgCore.getSidebarWidth()

                -- Check if sidebar is visible
                local showSidebar = true
                local uiMod = CfgCore.getMod("0-Engine-UI")
                if uiMod and uiMod.settings and uiMod.settings.showSidebar ~= nil then
                    showSidebar = uiMod.settings.showSidebar
                end

                if showSidebar then
                    -- Sidebar
                    ImGui.BeginChild("##cfgsidebar", sidebarWidth, 0, true)
                    if CfgSidebar and CfgSidebar.draw then
                        CfgSidebar.draw()
                    end
                    ImGui.EndChild()

                    ImGui.SameLine()
                end

                -- Content area
                ImGui.BeginChild("##cfgcontent", 0, 0, true)
                if CfgContentArea and CfgContentArea.draw then
                    CfgContentArea.draw()
                end
                ImGui.EndChild()
            end
            ImGui.End()
        end

        -- Pop theme
        if Theme then Theme.PopTheme() end

        -- Draw logger overlay (ring buffer debug display)
        if Logger then Logger.Draw() end
    end)

    if not drawOk then
        local errMsg = "onDraw error: " .. tostring(drawErr)
        print("[ModEngine] " .. errMsg)
        if log then log.error(errMsg) end
        if Theme then pcall(Theme.PopTheme) end
    end
end)

registerForEvent("onShutdown", function()
    -- Shutdown Log-Engine
    if _LogEngine and _LogEngine.onShutdown then
        _LogEngine.onShutdown()
    end

    -- Flush pending saves
    if Storage and Storage.IsDirty and Storage.IsDirty() then
        Storage.Save()
    end

    -- Clean up events
    if Events then
        Events.cleanup("modengine")
    end
end)

registerForEvent("onOverlayOpen", function()
    overlayOpen = true
    if log then log.info("CET overlay opened") end
end)

registerForEvent("onOverlayClose", function()
    overlayOpen = false
    if log then log.info("CET overlay closed") end
    -- Flush pending auto-saves on overlay close
    if Storage and Storage.IsDirty and Storage.IsDirty() then
        Storage.Save()
    end
    -- Flush Config-Engine state sync
    if CfgStateSync and CfgStateSync.flush then
        CfgStateSync.flush()
    end
end)

-- ============================================================================
-- Return for GetMod() resolution (CRITICAL - CET returns this)
-- ============================================================================

return ModEngine
