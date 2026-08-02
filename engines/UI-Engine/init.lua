--[[
    Init — UI-Engine Entry Point

    Entry point for the UI-Engine CET mod. Handles module loading,
    initialization, and the public API surface.

    Module loading order matches ARCHITECTURE.md exactly:
    1. core.lua          (state store — no dependencies)
    2. modules/logger.lua (logging — no dependencies)
    3. modules/storage.lua (persistence — depends on logger)
    4. api/events.lua    (pub/sub — depends on core)
    5. ui/utils.lua      (utilities — no dependencies)

    Phase 2+ modules (Theme, Components, Registry, Context, Window)
    are loaded via SafeRequire but may not exist yet.

    Public API: _G.UIEngine
]]

-- --- SafeRequire Pattern ---

--- Safely require a module with pcall
-- @param path Module path
-- @return table|nil Module table or nil if not found
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then
        return mod
    end
    -- Distinguish "module not found" (expected during phased dev) from real errors
    local err = tostring(mod)
    if not err:find("not found") and not err:find("no field") then
        print("[UIEngine] FAILED to load '" .. path .. "': " .. err)
    end
    return nil
end

-- --- Module Loading ---

-- Phase 1 modules (always loaded)
local Core = SafeRequire("core")
local Logger = SafeRequire("modules.logger")
local Storage = SafeRequire("modules.storage")
local Events = SafeRequire("api.events")
local Utils = SafeRequire("ui.utils")

-- Phase 2 modules (loaded if available)
local ThemeDefs = SafeRequire("config.themes")
local ColorEngine = SafeRequire("ui.color_engine")
local Tokens = SafeRequire("ui.tokens")
local DefaultConfig = SafeRequire("config.default_config")
local Theme = SafeRequire("ui.theme")

-- Phase 3+ modules (loaded if available)
local Window = SafeRequire("ui.window")
local Components = SafeRequire("ui.components")
local Registry = SafeRequire("api.registry")
local Context = SafeRequire("api.context")

-- Phase 4 modules (loaded if available)
local Windows = SafeRequire("api.windows")

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
local function SetTheme(themeName)
    if not Core then
        return
    end
    Core.setCurrentTheme(themeName)
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
    if Logger then
        Logger.Log("UIEngine", "DEPRECATED: " .. oldName .. " — use " .. (newName or "the new API"), "warn")
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

--- Log a message via the Logger
-- @param modName Module name
-- @param message Log message
-- @param level Level name string
local function Log(modName, message, level)
    if Logger then
        Logger.Log(modName, message, level)
    end
end

-- --- CET Callbacks ---

--- onInit handler — called when CET loads the mod
local function onInit()
    if initialized then
        return  -- Idempotent: safe to call multiple times
    end
    initialized = true

    -- Initialize modules in order
    if Logger then
        Logger.init()
    end

    if Storage then
        Storage.init(Logger)
    end

    if Events then
        Events.init(Logger, Core)
    end

    if Core then
        Core.init()
    end

    -- Initialize theme engine (Phase 2)
    if Theme and Theme.init then
        Theme.init(Core, ColorEngine, Tokens, ThemeDefs, Logger)
    end

    -- Phase 4: Initialize framework APIs
    if Registry and Registry.init then
        Registry.init({ Core = Core, Events = Events, Logger = Logger })
    end

    if Context and Context.init then
        Context.init({ Core = Core, Events = Events, Components = Components, Tokens = Tokens, Utils = Utils })
    end

    if Windows and Windows.init then
        Windows.init({ Core = Core, Events = Events, Logger = Logger })
    end

    -- Emit init complete event
    if Events then
        Events.emit("uiengine:initComplete")
    end

    -- Startup summary — always prints so failures are visible
    print("[UIEngine] v0.4.0-phase4 loaded")
    local phases = {
        {"Phase1", Core=Core, Logger=Logger, Storage=Storage, Events=Events, Utils=Utils},
        {"Phase2", ThemeDefs=ThemeDefs, ColorEngine=ColorEngine, Tokens=Tokens, DefaultConfig=DefaultConfig, Theme=Theme},
        {"Phase3", Window=Window, Components=Components, Registry=Registry, Context=Context},
        {"Phase4", Windows=Windows},
    }
    for _, phase in ipairs(phases) do
        local label = table.remove(phase, 1)
        for name, mod in pairs(phase) do
            print("[UIEngine]   " .. label .. "/" .. name .. ": " .. (mod and "OK" or "MISSING"))
        end
    end
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

    -- Push theme (Phase 2)
    if Theme then
        local ok, err = pcall(Theme.PushTheme)
        if not ok then
            print("[UIEngine] Theme.PushTheme error: " .. tostring(err))
        end
    end

    -- Draw standalone windows (Phase 4)
    if Windows and Windows.drawAll then
        local ok, err = pcall(Windows.drawAll)
        if not ok then
            print("[UIEngine] Windows.drawAll error: " .. tostring(err))
        end
    end

    -- Draw window (if available)
    if Window then
        local ok, err = pcall(Window.draw)
        if not ok then
            print("[UIEngine] Window.draw error: " .. tostring(err))
        end
    end

    -- Pop theme (Phase 2)
    if Theme then
        local ok, err = pcall(Theme.PopTheme)
        if not ok then
            print("[UIEngine] Theme.PopTheme error: " .. tostring(err))
        end
    end

    -- Draw logger overlay
    if Logger then
        Logger.Draw()
    end
end

--- onShutdown handler — called when CET unloads the mod
local function onShutdown()
    -- Flush pending saves on shutdown
    if Storage and Storage.IsDirty and Storage.IsDirty() then
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
end

-- --- Overlay Detection (Phase 4) ---

-- Register for overlay events (must be at module level, not in functions)
if registerForEvent then
    registerForEvent("onOverlayOpen", function()
        overlayOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        overlayOpen = false
        -- Flush pending auto-saves on overlay close
        if Storage and Storage.IsDirty and Storage.IsDirty() then
            Storage.Save()
        end
    end)
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
    Log = Log,

    -- Phase 4 public API (framework-level)
    IsOverlayOpen = IsOverlayOpen,
    Registry = Registry,
    Context = Context,
    Windows = Windows,
}

-- --- CET Entry Points ---

-- These are called by CET when the mod is loaded/unloaded
onInit = onInit
onDraw = onDraw
onShutdown = onShutdown

-- Return public API for GetMod() resolution
return UIEngine
