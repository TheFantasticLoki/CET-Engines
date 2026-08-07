--[[
    Registry — UI-Engine

    Structured mod registration with schema validation,
    lifecycle management, and dependency tracking.

    Provides API for consumer mods to register with UI-Engine,
    specifying their display name, version, draw callback,
    settings schema, and dependencies.

    Depends on Core for state storage, Events for lifecycle notifications,
    and Logger for error reporting.
]]

---@class Registry
---Mod registration system with schema validation and lifecycle management.
local M = {}

-- --- Internal State ---

local initialized = false
---@type table|nil
local Core = nil
---@type table|nil
local Events = nil
---@type table|nil
local Logger = nil
---@type Logger?
local log = nil  -- Log-Engine fallback

-- --- Schema Validation ---

--- Validate a mod specification against the required schema.
---@param id string Mod identifier
---@param spec table<string, any> Mod specification
---@return boolean success
---@return string? error Error message if validation failed
local function validateSpec(id, spec)
    if type(id) ~= "string" or id == "" then
        return false, "Invalid mod ID: must be non-empty string"
    end
    if type(spec) ~= "table" then
        return false, "Invalid spec: must be table"
    end
    if type(spec.name) ~= "string" or spec.name == "" then
        return false, "Invalid spec.name: must be non-empty string"
    end
    if type(spec.version) ~= "string" then
        return false, "Invalid spec.version: must be string"
    end
    if spec.author ~= nil and type(spec.author) ~= "string" then
        return false, "Invalid spec.author: must be string or nil"
    end
    if spec.description ~= nil and type(spec.description) ~= "string" then
        return false, "Invalid spec.description: must be string or nil"
    end
    if spec.draw ~= nil and type(spec.draw) ~= "function" then
        return false, "Invalid spec.draw: must be function or nil"
    end
    if spec.settings ~= nil and type(spec.settings) ~= "table" then
        return false, "Invalid spec.settings: must be table or nil"
    end
    if spec.dependencies ~= nil and type(spec.dependencies) ~= "table" then
        return false, "Invalid spec.dependencies: must be table or nil"
    end
    if spec.onEnable ~= nil and type(spec.onEnable) ~= "function" then
        return false, "Invalid spec.onEnable: must be function or nil"
    end
    if spec.onDisable ~= nil and type(spec.onDisable) ~= "function" then
        return false, "Invalid spec.onDisable: must be function or nil"
    end
    return true, nil
end

-- --- Public API ---

--- Initialize the registry module (idempotent).
---@param deps table { Core: CoreModule, Events: EventsModule, Logger: LoggerModule? }
function M.init(deps)
    if initialized then
        return
    end
    initialized = true

    Core = deps and deps.Core
    Events = deps and deps.Events
    Logger = deps and deps.Logger

    -- Resolve Log-Engine as primary logger (has .info(), .warn(), etc.)
    if deps and deps.log then
        log = deps.log
    elseif Logger then
        -- Legacy Logger module: wrap to provide .info()/.warn() interface
        local rawLogger = Logger
        log = {
            info = function(msg) rawLogger.Log("Registry", msg, "info") end,
            warn = function(msg) rawLogger.Log("Registry", msg, "warn") end,
            error = function(msg) rawLogger.Log("Registry", msg, "error") end,
            debug = function(msg) rawLogger.Log("Registry", msg, "debug") end,
        }
    else
        local ok, LogEngine = pcall(require, "log/init")
        if ok and LogEngine then
            local ok2, lgr = pcall(LogEngine.CreateLogger, "UI-Engine-Registry", { minLevel = "warn" })
            if ok2 and lgr then log = lgr end
        end
    end
end

--- Register a mod with UI-Engine.
---@param id string Unique mod identifier
---@param spec table<string, any> Mod specification with name, version, draw, settings, etc.
---@return boolean success
---@return string? error Error message if registration failed
function M.register(id, spec)
    if not Core then
        return false, "Registry not initialized"
    end

    local valid, err = validateSpec(id, spec)
    if not valid then
        if log then log.error("Validation failed for '" .. id .. "': " .. tostring(err)) end
        return false, err
    end

    -- Check dependencies are available
    if spec.dependencies then
        for _, depId in ipairs(spec.dependencies) do
            local dep = Core.getPanel(depId)
            if not dep then
                return false, "Missing dependency: " .. tostring(depId)
            end
        end
    end

    -- Store the spec (updates if already exists)
    Core.setPanel(id, spec)

    -- Emit registration event
    if Events then
        Events.emit("uiengine:registered", id, spec)
    end

    -- Log registration
    if log then
        log.info("Registered mod: " .. spec.name .. " v" .. spec.version .. " (" .. id .. ")")
    elseif Logger then
        Logger.Log("Registry", "Registered mod: " .. spec.name .. " v" .. spec.version, "info")
    end

    return true, nil
end

--- Unregister a mod from UI-Engine.
---@param id string Mod identifier
---@return boolean success
function M.unregister(id)
    if not Core then
        return false
    end

    local spec = Core.getPanel(id)
    if not spec then
        return false
    end

    -- Call onDisable if available
    if spec.onDisable then
        local ok, err = pcall(spec.onDisable)
        if not ok then
            local msg = "Error calling onDisable for " .. id .. ": " .. tostring(err)
            if Logger then
                Logger.Log("Registry", msg, "error")
            elseif log then
                log.error(msg)
            end
        end
    end

    -- Remove from Core
    Core.removePanel(id)

    -- Clean up event subscriptions
    if Events then
        Events.cleanup(id)
    end

    -- Emit unregistration event
    if Events then
        Events.emit("uiengine:unregistered", id)
    end

    return true
end

--- Get a registered mod's spec.
---@param id string Mod identifier
---@return table<string, any>? spec The mod specification, or nil if not found
function M.getMod(id)
    if not Core then
        return nil
    end
    return Core.getPanel(id)
end

--- Get all registered mod IDs.
---@return string[] Array of mod ID strings
function M.getModIds()
    if not Core then
        return {}
    end
    return Core.getPanelIds()
end

--- Get mod count.
---@return number count Total registered mod count
function M.getModCount()
    local ids = M.getModIds()
    return #ids
end

return M
