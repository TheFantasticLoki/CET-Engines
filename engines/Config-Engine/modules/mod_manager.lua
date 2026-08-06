-- Config-Engine Mod Manager
-- Handles mod discovery, registration, and lifecycle.

local RenderMode = require("modules.render_mode")
local Schema = require("modules.settings_schema")
local Resolver = require("modules.settings_resolver")

---@class ModManager
---Mod lifecycle management: register, unregister, enable/disable, settings sync.
local M = {}

-- Dependencies (late-bound)
---@type table?
local Core = nil
---@type table?
local Events = nil
---@type table?
local UIEngine = nil
---@type table?
local Logger = nil
---@type Logger?
local log = nil

--- Initialize the mod manager.
---@param deps table { core: CfgCore, events: EventsModule, uiEngine: UIEngineModule?, logger: LoggerModule? }
---@return nil
function M.init(deps)
    Core = deps.core
    Events = deps.events
    UIEngine = deps.uiEngine
    Logger = deps.logger

    if Logger then
        log = Logger
    end
end

--- Register a mod with Config-Engine.
---@param modId string Unique mod identifier
---@param spec table<string, any> Registration spec table
---@return boolean success
---@return string? error Error message if registration failed
function M.register(modId, spec)
    if not modId or type(modId) ~= "string" then
        return false, "modId must be a string"
    end
    if not spec or type(spec) ~= "table" then
        return false, "spec must be a table"
    end
    if not spec.name or type(spec.name) ~= "string" then
        return false, "spec.name is required"
    end
    if not spec.version or type(spec.version) ~= "string" then
        return false, "spec.version is required"
    end

    -- Detect render mode
    local renderMode = RenderMode.detectMode(spec)

    -- Validate schema if present
    if RenderMode.usesSchema(renderMode) then
        local ok, errors = Schema.validateSchema(spec)
        if not ok then
            local errMsg = "Schema validation failed: " .. table.concat(errors, "; ")
            if log then log.warn("Schema validation failed for '" .. modId .. "': " .. errMsg) end
            return false, errMsg
        end
    end

    -- Check if already registered (idempotent update)
    local existing = Core.getMod(modId)
    if existing then
        -- Update existing registration
        Core.setMod(modId, {
            spec = spec,
            renderMode = renderMode,
        })
        if log then
            log.info("Mod updated: " .. modId)
        elseif Logger then
            Logger.info("ConfigEngine", "Mod updated: " .. modId)
        end
        Events.emit("configengine:modRegistered", modId, spec)
        return true, nil
    end

    -- Create mod state
    local modState = {
        spec = spec,
        renderMode = renderMode,
        enabled = true,
        pinned = false,
        favorite = false,
        settings = {},
        wiki = spec.wiki or nil,
    }

    -- Resolve settings if schema-based
    if RenderMode.usesSchema(renderMode) then
        local savedSettings = Core.getMod(modId) and Core.getMod(modId).settings or nil
        local resolved, warnings = Resolver.resolveSettings(spec, savedSettings)
        modState.settings = resolved

        if warnings and #warnings > 0 and Logger then
            for _, w in ipairs(warnings) do
                Logger.warn("ConfigEngine", modId .. ": " .. w)
            end
        end
    end

    -- Store in core
    Core.setMod(modId, modState)

    -- Auto-categorize
    local Categories = nil
    pcall(function() Categories = require("config.categories") end)
    if Categories then
        local assignment = Core.getModCategory(modId)
        if not assignment then
            Core.setModCategory(modId, Categories.defaultCategory or "Uncategorized")
        end
    end

    if log then
        log.info("Mod registered: " .. modId .. " (" .. renderMode .. ")")
    elseif Logger then
        Logger.info("ConfigEngine", "Mod registered: " .. modId .. " (" .. renderMode .. ")")
    end

    Events.emit("configengine:modRegistered", modId, spec)
    return true, nil
end

--- Unregister a mod.
---@param modId string The mod identifier
---@return boolean success
function M.unregister(modId)
    local mod = Core.getMod(modId)
    if not mod then
        return false
    end

    Core.removeMod(modId)
    Events.emit("configengine:modUnregistered", modId)
    return true
end

--- Get mod info.
---@param modId string The mod identifier
---@return table? modState The mod state, or nil if not found
function M.getModInfo(modId)
    return Core.getMod(modId)
end

--- Get list of all registered mods.
---@return string[] Array of modId strings
function M.getModList()
    return Core.getSortedModIds()
end

--- Get mod count.
---@return number count Total registered mods
function M.getModCount()
    local count = 0
    for _ in pairs(Core.getAllMods()) do
        count = count + 1
    end
    return count
end

--- Enable a mod.
---@param modId string The mod identifier
---@return boolean success
function M.enable(modId)
    local mod = Core.getMod(modId)
    if not mod then return false end
    Core.setMod(modId, { enabled = true })
    Events.emit("configengine:modEnabled", modId)
    return true
end

--- Disable a mod.
---@param modId string The mod identifier
---@return boolean success
function M.disable(modId)
    local mod = Core.getMod(modId)
    if not mod then return false end
    Core.setMod(modId, { enabled = false })
    Events.emit("configengine:modDisabled", modId)
    return true
end

--- Pin a mod to the top of the list.
---@param modId string The mod identifier
---@param pinned boolean Pin state
---@return nil
function M.setPinned(modId, pinned)
    Core.setMod(modId, { pinned = pinned == true })
end

--- Favorite a mod.
---@param modId string The mod identifier
---@param favorite boolean Favorite state
---@return nil
function M.setFavorite(modId, favorite)
    Core.setMod(modId, { favorite = favorite == true })
end

--- Get a mod's current settings.
---@param modId string The mod identifier
---@return table? settings The settings table, or nil
function M.getSettings(modId)
    local mod = Core.getMod(modId)
    if not mod then return nil end
    return mod.settings
end

--- Update a mod's settings.
---@param modId string The mod identifier
---@param settings table<string, any> The new settings (merged with existing)
---@return boolean success
function M.updateSettings(modId, settings)
    local mod = Core.getMod(modId)
    if not mod then return false end

    local merged = {}
    -- Copy existing
    for k, v in pairs(mod.settings or {}) do
        merged[k] = v
    end
    -- Override with new
    for k, v in pairs(settings or {}) do
        merged[k] = v
    end

    Core.setMod(modId, { settings = merged })
    return true
end

--- Reset a mod's settings to defaults.
---@param modId string The mod identifier
---@return boolean success
function M.resetSettings(modId)
    local mod = Core.getMod(modId)
    if not mod or not mod.spec then return false end

    if not RenderMode.usesSchema(mod.renderMode) then
        return false
    end

    local resolved, _ = Resolver.resolveSettings(mod.spec, nil)
    Core.setMod(modId, { settings = resolved })
    Events.emit("configengine:settingsReset", modId)
    return true
end

return M
