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
    return nil
end

-- --- Module Loading ---

-- Phase 1 modules (always loaded)
local Core = SafeRequire("engines.UI-Engine.core")
local Logger = SafeRequire("engines.UI-Engine.modules.logger")
local Storage = SafeRequire("engines.UI-Engine.modules.storage")
local Events = SafeRequire("engines.UI-Engine.api.events")
local Utils = SafeRequire("engines.UI-Engine.ui.utils")

-- Phase 2 modules (loaded if available)
local ThemeDefs = SafeRequire("engines.UI-Engine.config.themes")
local ColorEngine = SafeRequire("engines.UI-Engine.ui.color_engine")
local Tokens = SafeRequire("engines.UI-Engine.ui.tokens")
local DefaultConfig = SafeRequire("engines.UI-Engine.config.default_config")
local Theme = SafeRequire("engines.UI-Engine.ui.theme")

-- Phase 3+ modules (loaded if available)
local Window = SafeRequire("engines.UI-Engine.ui.window")
local Registry = SafeRequire("engines.UI-Engine.api.registry")
local Context = SafeRequire("engines.UI-Engine.api.context")

-- --- Initialization State ---

local initialized = false
local frameCount = 0

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

    -- Emit init complete event
    if Events then
        Events.emit("uiengine:initComplete")
    end
end

--- onDraw handler — called each frame
local function onDraw()
    frameCount = frameCount + 1

    -- Update frame counter
    if Logger then
        Logger.SetFrame(frameCount)
    end

    -- Push theme (Phase 2)
    if Theme then
        pcall(function()
            Theme.PushTheme()
        end)
    end

    -- Draw window (if available)
    if Window then
        pcall(function()
            Window.draw()
        end)
    end

    -- Pop theme (Phase 2)
    if Theme then
        pcall(function()
            Theme.PopTheme()
        end)
    end

    -- Draw logger overlay
    if Logger then
        Logger.Draw()
    end
end

--- onShutdown handler — called when CET unloads the mod
local function onShutdown()
    -- Flush pending saves
    if Storage and Storage.IsDirty() then
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

-- --- Global API ---

-- NOTE: In CET's sandboxed Lua environment, _G is nil.
-- Use rawset or direct assignment to set globals.
UIEngine = {
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
}

-- --- CET Entry Points ---

-- These are called by CET when the mod is loaded/unloaded
onInit = onInit
onDraw = onDraw
onShutdown = onShutdown
