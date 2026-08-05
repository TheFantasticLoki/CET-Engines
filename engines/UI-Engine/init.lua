--[[
    Init — UI-Engine Entry Point

    Entry point for the UI-Engine CET mod. Handles module loading,
    initialization, and the public API surface.

    Module loading order matches ARCHITECTURE.md exactly:
    0. Log-Engine        (safety-net logging — first thing loaded)
    1. core.lua          (state store — no dependencies)
    2. modules/logger.lua (logging — no dependencies)
    3. modules/storage.lua (persistence — depends on logger)
    4. api/events.lua    (pub/sub — depends on core)
    5. ui/utils.lua      (utilities — no dependencies)

    Phase 2+ modules (Theme, Components, Registry, Context, Window)
    are loaded via SafeRequire but may not exist yet.

    Public API: _G.UIEngine
]]

-- ============================================================================
-- TRACE: Top-level execution begins (print ALWAYS goes to CET console)
-- ============================================================================
print("[UIEngine TRACE] >>>>>> TOP-LEVEL CODE START <<<<<<")

-- --- Direct File Debug (last resort — works even if Log-Engine is broken) ---

local _debugFile = nil
local function dbgWrite(msg)
    -- Write to a debug trace file that we can always check
    local f = io.open("UIEngine_DEBUG.trace", "a")
    if f then
        f:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        f:close()
    end
end
dbgWrite("TOP-LEVEL CODE START")

-- Clear previous debug trace
do
    local f = io.open("UIEngine_DEBUG.trace", "w")
    if f then f:write("--- UIEngine Debug Trace ---\n"); f:close() end
end
dbgWrite("trace file cleared")

-- --- Log-Engine Integration (FIRST, before anything else) ---

print("[UIEngine TRACE] Resolving Log-Engine...")
dbgWrite("resolving Log-Engine")

local LogEngine = nil
local log = nil

-- NOTE: GetMod() deferred to onInit — CET requires event system to be set up first
-- LogEngine will be resolved in onInit(), not at top level

-- --- SafeRequire Pattern ---

print("[UIEngine TRACE] Defining SafeRequire...")
dbgWrite("defining SafeRequire")

--- Safely require a module with pcall, logging success/failure to Log-Engine
-- @param path Module path
-- @return table|nil Module table or nil if not found
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then
        if log then log.info("Loaded: " .. path) end
        print("[UIEngine] Loaded: " .. path)
        dbgWrite("LOADED: " .. path)
        return mod
    end
    local err = tostring(mod)
    if log then log.error("FAILED to load '" .. path .. "': " .. err) end
    print("[UIEngine] FAILED to load '" .. path .. "': " .. err)
    dbgWrite("FAILED: " .. path .. " — " .. err)
    return nil
end

-- --- Module Loading ---

print("[UIEngine TRACE] Starting module loading...")
dbgWrite("module loading start")

-- Phase 1 modules (always loaded)
local Core = SafeRequire("core")
local Logger = SafeRequire("modules/logger")
local Storage = SafeRequire("modules/storage")
local Events = SafeRequire("api/events")
local Utils = SafeRequire("ui/utils")

-- Phase 2 modules (loaded if available)
local ThemeDefs = SafeRequire("config/themes")
local ColorEngine = SafeRequire("ui/color_engine")
local Tokens = SafeRequire("ui/tokens")
local DefaultConfig = SafeRequire("config/default_config")
local Theme = SafeRequire("ui/theme")

-- Phase 3+ modules (loaded if available)
local Window = SafeRequire("ui/window")
local Components = SafeRequire("ui/components")
local Registry = SafeRequire("api/registry")
local Context = SafeRequire("api/context")

-- Phase 4 modules (loaded if available)
local Windows = SafeRequire("api/windows")

print("[UIEngine TRACE] All modules loaded — starting function definitions")
dbgWrite("all modules loaded, defining functions")

-- --- Initialization State ---

local initialized = false
local frameCount = 0
local overlayOpen = false  -- Phase 4: overlay detection

-- --- Public API ---

--- Register a mod with UI-Engine
-- @param id Mod identifier
-- @param spec Mod specification table
-- @return boolean, string|nil success, error message
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

    -- Store in Core
    Core.setPanel(id, spec)

    -- Emit event
    if Events then
        Events.emit("uiengine:registered", id, spec)
    end

    return true, nil
end

--- Unregister a mod from UI-Engine
-- @param id Mod identifier
-- @return boolean, string|nil success, error message
local function Unregister(id)
    if not Core then
        return false, "Core module not loaded"
    end

    if not id or type(id) ~= "string" then
        return false, "Invalid mod ID"
    end

    -- Remove from Core
    Core.removePanel(id)

    -- Clean up event subscriptions
    if Events then
        Events.cleanup(id)
    end

    -- Emit event
    if Events then
        Events.emit("uiengine:unregistered", id)
    end

    return true, nil
end

--- Get a context object for a mod
-- @param id Mod identifier
-- @return table|nil Context object or nil
local function GetContext(id)
    if not Core then
        return nil
    end

    local spec = Core.getPanel(id)
    if not spec then
        return nil
    end

    -- If Context module is available, use it
    if Context then
        return Context.create(id, spec)
    end

    -- Fallback: return a basic context
    return {
        modId = id,
        spec = spec,
    }
end

--- Get the current theme
-- @return string Current theme name
local function GetTheme()
    if not Core then
        return "Dark"
    end
    return Core.getCurrentTheme()
end

--- Set the current theme
-- @param themeName Theme name
-- @return boolean success
local function SetTheme(themeName)
    -- Delegate to Theme module for validation when available
    if Theme and Theme.SetTheme then
        return Theme.SetTheme(themeName)
    end
    -- Fallback: no validation
    if not Core then
        return false
    end
    Core.setCurrentTheme(themeName)
    return true
end

--- Get the list of available themes
-- @return table Array of theme names
local function GetThemeList()
    if Theme then
        return Theme.GetThemeList()
    end
    return { "Dark" }
end

--- Subscribe to an event
-- @param event Event name
-- @param handler Handler function
-- @param source Source label
-- @return function Unsubscribe function
local function On(event, handler, source)
    if not Events then
        return function() end
    end
    return Events.on(event, handler, source)
end

--- Emit an event
-- @param event Event name
-- @param ... Event arguments
local function Emit(event, ...)
    if not Events then
        return
    end
    Events.emit(event, ...)
end

--- Unsubscribe from an event
-- @param event Event name
-- @param handler Handler function
local function Off(event, handler)
    if not Events then
        return
    end
    Events.off(event, handler)
end

--- Show deprecation warning
-- @param oldName Old API name
-- @param newName New API name
local function Deprecated(oldName, newName)
    local msg = "DEPRECATED: " .. oldName .. " — use " .. (newName or "the new API")
    if log then log.warn(msg) end
    if Logger then
        Logger.Log("UIEngine", msg, "warn")
    end
end

--- Check if a mod is registered
-- @param id Mod identifier
-- @return boolean True if registered
local function IsRegistered(id)
    if not Core then
        return false
    end
    return Core.getPanel(id) ~= nil
end

--- Get list of registered mod IDs
-- @return table Array of mod IDs
local function GetRegisteredMods()
    if not Core then
        return {}
    end
    return Core.getPanelIds()
end

--- Get the UI-Engine version
-- @return string Version string
local function GetVersion()
    return "v0.1.0-core"
end

--- Enable a mod (set its panel as active)
-- @param id Mod identifier
-- @return boolean, string|nil success, error message
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

--- Disable a mod (set its panel as inactive)
-- @param id Mod identifier
-- @return boolean, string|nil success, error message
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

--- Log a message via both Logger and Log-Engine
-- @param modName Module name
-- @param message Log message
-- @param level Level name string
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

-- --- CET Callbacks ---

--- onInit handler — called when CET loads the mod
local function onInit()
    print("[UIEngine TRACE] >>>>>> onInit() CALLED <<<<<<")
    dbgWrite("onInit() CALLED, initialized=" .. tostring(initialized))

    if initialized then
        print("[UIEngine TRACE] onInit: already initialized, skipping")
        dbgWrite("onInit: already initialized, skipping")
        if log then log.debug("onInit called again — idempotent guard, skipping") end
        return  -- Idempotent: safe to call multiple times
    end
    initialized = true

    print("[UIEngine TRACE] onInit: starting module initialization")
    dbgWrite("onInit: starting module initialization")

    -- Resolve Log-Engine NOW (after event system is ready)
    print("[UIEngine TRACE] onInit: resolving Log-Engine...")
    dbgWrite("onInit: resolving Log-Engine")
    LogEngine = GetMod("0-Engine-Log")
    if LogEngine then
        print("[UIEngine TRACE] Log-Engine found, creating logger...")
        dbgWrite("Log-Engine found")
        local ok, logger = pcall(LogEngine.CreateLogger, "UI-Engine", { minLevel = "debug", maxDebugPerFrame = 5 })
        if ok and logger then
            log = logger
            print("[UIEngine] Log-Engine connected")
            dbgWrite("Log-Engine logger created")
        else
            print("[UIEngine] WARNING: Log-Engine CreateLogger failed: " .. tostring(logger))
            dbgWrite("Log-Engine CreateLogger FAILED: " .. tostring(logger))
        end
    else
        print("[UIEngine] WARNING: 0-Engine-Log not found — errors will only go to CET console")
        dbgWrite("Log-Engine NOT FOUND")
    end

    if log then log.info("=== onInit START ===") end

    -- Initialize modules in order
    print("[UIEngine TRACE] onInit: Logger=" .. tostring(Logger ~= nil))
    if Logger then
        if log then log.info("Initializing Logger module") end
        Logger.init()
        print("[UIEngine TRACE] onInit: Logger.init() done")
    end

    print("[UIEngine TRACE] onInit: Storage=" .. tostring(Storage ~= nil))
    if Storage then
        if log then log.info("Initializing Storage module") end
        Storage.init(Logger)
        print("[UIEngine TRACE] onInit: Storage.init() done")
    end

    print("[UIEngine TRACE] onInit: Events=" .. tostring(Events ~= nil))
    if Events then
        if log then log.info("Initializing Events module") end
        Events.init(Logger, Core)
        print("[UIEngine TRACE] onInit: Events.init() done")
    end

    print("[UIEngine TRACE] onInit: Core=" .. tostring(Core ~= nil))
    if Core then
        if log then log.info("Initializing Core module") end
        Core.init()
        print("[UIEngine TRACE] onInit: Core.init() done")
    end

    -- Initialize theme engine (Phase 2)
    print("[UIEngine TRACE] onInit: Theme=" .. tostring(Theme ~= nil))
    if Theme and Theme.init then
        if log then log.info("Initializing Theme module") end
        Theme.init(Core, ColorEngine, Tokens, ThemeDefs, Logger)
        print("[UIEngine TRACE] onInit: Theme.init() done")
    end

    -- Phase 4: Initialize framework APIs
    print("[UIEngine TRACE] onInit: Registry=" .. tostring(Registry ~= nil))
    if Registry and Registry.init then
        if log then log.info("Initializing Registry module") end
        Registry.init({ Core = Core, Events = Events, Logger = Logger })
        print("[UIEngine TRACE] onInit: Registry.init() done")
    end

    print("[UIEngine TRACE] onInit: Context=" .. tostring(Context ~= nil))
    if Context and Context.init then
        if log then log.info("Initializing Context module") end
        Context.init({ Core = Core, Events = Events, Components = Components, Tokens = Tokens, Utils = Utils })
        print("[UIEngine TRACE] onInit: Context.init() done")
    end

    print("[UIEngine TRACE] onInit: Windows=" .. tostring(Windows ~= nil))
    if Windows and Windows.init then
        if log then log.info("Initializing Windows module") end
        Windows.init({ Core = Core, Events = Events, Logger = Logger })
        print("[UIEngine TRACE] onInit: Windows.init() done")
    end

    -- Initialize Components (Phase 3)
    print("[UIEngine TRACE] onInit: Components=" .. tostring(Components ~= nil))
    if Components and Components.init then
        if log then log.info("Initializing Components module") end
        Components.init(Logger, Core, Theme)
        print("[UIEngine TRACE] onInit: Components.init() done")
    end

    -- Emit init complete event
    if Events then
        Events.emit("uiengine:initComplete")
    end

    -- Startup summary — always prints so failures are visible
    if log then log.info("=== UIEngine v0.5.0-phase4 loaded ===") end
    print("[UIEngine] v0.5.0-phase4 loaded")
    local phases = {
        {"Phase0", LogEngine=LogEngine, log=log},
        {"Phase1", Core=Core, Logger=Logger, Storage=Storage, Events=Events, Utils=Utils},
        {"Phase2", ThemeDefs=ThemeDefs, ColorEngine=ColorEngine, Tokens=Tokens, DefaultConfig=DefaultConfig, Theme=Theme},
        {"Phase3", Window=Window, Components=Components, Registry=Registry, Context=Context},
        {"Phase4", Windows=Windows},
    }
    for _, phase in ipairs(phases) do
        local label = table.remove(phase, 1)
        for name, mod in pairs(phase) do
            local status = mod and "OK" or "MISSING"
            if log then
                if mod then
                    log.info("  " .. label .. "/" .. name .. ": OK")
                else
                    log.warn("  " .. label .. "/" .. name .. ": MISSING")
                end
            end
            print("[UIEngine]   " .. label .. "/" .. name .. ": " .. status)
        end
    end

    if log then log.info("=== onInit END ===") end
    print("[UIEngine TRACE] >>>>>> onInit() COMPLETE <<<<<<")
    dbgWrite("onInit() COMPLETE")
end

--- onDraw handler — called each frame
local function onDraw()
    frameCount = frameCount + 1

    -- Update frame counter for Logger
    if Logger then
        Logger.SetFrame(frameCount)
    end

    -- Update frame counter for auto-save debounce (Phase 4)
    if Utils and Utils.updateFrame then
        Utils.updateFrame(frameCount)
    end

    -- SINGLE pcall wrapping all ImGui calls — CET's FFI breaks with per-call pcall
    local drawOk, drawErr = pcall(function()
        -- Push theme (Phase 2)
        if Theme then Theme.PushTheme() end

        -- Draw standalone windows (Phase 4)
        if Windows and Windows.drawAll then Windows.drawAll() end

        -- Draw window (if available)
        if Window then Window.draw() end

        -- Pop theme (Phase 2)
        if Theme then Theme.PopTheme() end

        -- Draw logger overlay
        if Logger then Logger.Draw() end
    end)

    if not drawOk then
        if log then log.error("onDraw error: " .. tostring(drawErr)) end
        print("[UIEngine] onDraw error: " .. tostring(drawErr))
        -- Attempt to pop theme if it was pushed before the error
        if Theme then pcall(Theme.PopTheme) end
    end
end

--- onShutdown handler — called when CET unloads the mod
local function onShutdown()
    print("[UIEngine TRACE] >>>>>> onShutdown() CALLED <<<<<<")
    dbgWrite("onShutdown() CALLED")
    if log then log.info("=== onShutdown START ===") end

    -- Flush pending saves on shutdown
    if Storage and Storage.IsDirty and Storage.IsDirty() then
        if log then log.info("Flushing pending storage saves") end
        Storage.Save()
    end

    -- Clean up event subscriptions
    if Events then
        Events.cleanup("uiengine")
    end

    -- Log final state
    if Logger then
        Logger.Log("UIEngine", "Shutdown complete", "info")
    end

    -- Flush Log-Engine
    if log then
        log.info("=== onShutdown END ===")
        log.flush()
    end
end

-- --- Overlay Detection (Phase 4) ---

-- Register for overlay events (must be at module level, not in functions)
print("[UIEngine TRACE] registerForEvent available: " .. tostring(registerForEvent ~= nil))
dbgWrite("registerForEvent: " .. tostring(registerForEvent ~= nil))

if registerForEvent then
    registerForEvent("onOverlayOpen", function()
        overlayOpen = true
        print("[UIEngine TRACE] onOverlayOpen fired")
        dbgWrite("onOverlayOpen fired")
        if log then log.info("CET overlay opened") end
    end)

    registerForEvent("onOverlayClose", function()
        overlayOpen = false
        print("[UIEngine TRACE] onOverlayClose fired")
        dbgWrite("onOverlayClose fired")
        if log then log.info("CET overlay closed") end
        -- Flush pending auto-saves on overlay close
        if Storage and Storage.IsDirty and Storage.IsDirty() then
            if log then log.info("Flushing pending storage on overlay close") end
            Storage.Save()
        end
    end)
else
    print("[UIEngine TRACE] WARNING: registerForEvent is nil!")
    dbgWrite("WARNING: registerForEvent is nil")
end

--- Check if the CET overlay is open
-- @return boolean True if overlay is visible
local function IsOverlayOpen()
    return overlayOpen
end

-- --- Global API ---

-- NOTE: In CET's sandboxed Lua environment, _G is nil.
-- Use rawset or direct assignment to set globals.
UIEngine = {
    -- Phase 0: Log-Engine access
    Log = Log,

    -- Phase 1 public API
    Register = Register,
    Unregister = Unregister,
    GetContext = GetContext,
    GetTheme = GetTheme,
    SetTheme = SetTheme,
    GetThemeList = GetThemeList,
    On = On,
    Emit = Emit,
    Off = Off,
    Deprecated = Deprecated,
    IsRegistered = IsRegistered,
    GetRegisteredMods = GetRegisteredMods,
    GetVersion = GetVersion,
    Enable = Enable,
    Disable = Disable,

    -- Phase 1 core modules (exposed for consumer access)
    Core = Core,
    Events = Events,

    -- Phase 2 theme modules
    Theme = Theme,
    Tokens = Tokens,

    -- Phase 3 component modules
    Components = Components,
    Registry = Registry,
    Context = Context,

    -- Phase 4 framework APIs
    IsOverlayOpen = IsOverlayOpen,
    Windows = Windows,
}

-- --- CET Entry Points ---

-- CET's global onInit/onDraw/onShutdown callbacks are NOT being called for our mod.
-- Evidence: scripting.log shows globals set to true but no "onInit() CALLED" trace.
-- Fix: Use registerForEvent() which we've proven works (onOverlayOpen fires correctly).

print("[UIEngine TRACE] Registering CET events via registerForEvent...")
dbgWrite("registering CET events")

registerForEvent("onInit", onInit)
print("[UIEngine TRACE] registerForEvent('onInit') registered")
dbgWrite("registerForEvent('onInit') done")

registerForEvent("onDraw", onDraw)
print("[UIEngine TRACE] registerForEvent('onDraw') registered")
dbgWrite("registerForEvent('onDraw') done")

registerForEvent("onShutdown", onShutdown)
print("[UIEngine TRACE] registerForEvent('onShutdown') registered")
dbgWrite("registerForEvent('onShutdown') done")

-- Also keep global assignments as fallback (some CET versions may use them)
onInit = onInit
onDraw = onDraw
onShutdown = onShutdown
print("[UIEngine TRACE] Global callbacks also set as fallback")
dbgWrite("global callbacks set as fallback")

-- Return public API for GetMod() resolution
print("[UIEngine TRACE] >>>>>> TOP-LEVEL CODE END (returning UIEngine) <<<<<<")
dbgWrite("TOP-LEVEL CODE END")
return UIEngine
