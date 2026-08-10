-- Config-Engine Mod Manager
-- Handles mod discovery, registration, and lifecycle.

local RenderMode = require("cfg/render_mode")
local Schema = require("cfg/settings_schema")
local Resolver = require("cfg/settings_resolver")

---@class ModManager
local M = {}

-- Dependencies (late-bound)
---@type CfgCore|nil
local Core = nil
---@type table|nil
local Events = nil
---@type table|nil
local UIEngine = nil
---@type Logger|nil
local Logger = nil
---@type table|nil
local CfgUndoRedo = nil
---@type table|nil
local Categories = nil

--- Initialize the mod manager.
---@param deps table { core: CfgCore, events: table, modEngine: table|nil, logger: Logger|nil, undoRedo: table|nil, categories: table|nil }
---@return nil
function M.init(deps)
    Core = deps.core
    Events = deps.events
    UIEngine = deps.modEngine
    Logger = deps.logger
    CfgUndoRedo = deps.undoRedo
    Categories = deps.categories

    -- Resolve Log-Engine as fallback
    if not Logger then
        Logger = require("ui/utils").ResolveLogger("ModManager")
    end
end

--- Nil-safe event emit helper.
---@param event string Event name
---@param ... any Event arguments
local function safeEmit(event, ...)
    if Events and Events.emit then
        Events.emit(event, ...)
    end
end

--- Register a mod with Config-Engine.
---@param modId string Unique mod identifier
---@param spec table Registration spec table
---@return boolean success
---@return string|nil error message
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
            return false, errMsg
        end
    end

    if not Core then return false, "Core not initialized" end

    -- Check if already registered (idempotent update)
    local existing = Core.getMod(modId)
    if existing then
        -- Update existing registration (preserve tags if not provided)
        local updateData = {
            spec = spec,
            renderMode = renderMode,
        }
        if spec.tags then
            updateData.tags = spec.tags
        end
        if spec.tests then
            updateData.tests = spec.tests
        end
        Core.setMod(modId, updateData)
        if Logger then
            Logger.info("Mod updated: " .. modId)
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
        tags = spec.tags or {},  -- Array of tag strings
        tests = spec.tests or nil, -- Test functions { startup, full, debug }
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

    -- Auto-categorize: use spec.category if provided, else default
    local modCategories = Categories or (function()
        local ok, mod = pcall(require, "config/categories")
        return ok and mod or nil
    end)()
    if modCategories then
        local assignment = Core.getModCategory(modId)
        if not assignment then
            local cat = spec.category or modCategories.defaultCategory or "Uncategorized"
            Core.setModCategory(modId, cat, spec.subcategory)
        end
    end

    -- Shared panel: auto-register if spec.sharedPanel = true
    if spec.sharedPanel == true then
        Core.addSharedPanelMod(modId)
        if Logger then
            Logger.info("Mod added to shared panel: " .. modId)
        end
    end

    if Logger then
        Logger.info("Mod registered: " .. modId .. " (" .. renderMode .. ")")
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
    -- Remove from shared panel if registered there
    Core.removeSharedPanelMod(modId)
    -- Clear undo/redo entries for this mod to prevent stale references
    if CfgUndoRedo and CfgUndoRedo.clearForMod then
        CfgUndoRedo.clearForMod(modId)
    end
    if Logger then
        Logger.info("Mod unregistered: " .. modId)
    end
    Events.emit("configengine:modUnregistered", modId)
    return true
end

--- Get mod info.
---@param modId string The mod identifier
---@return table|nil The mod state
function M.getModInfo(modId)
    return Core.getMod(modId)
end

--- Get list of all registered mods.
---@return table Array of modId strings
function M.getModList()
    return Core.getSortedModIds()
end

--- Get a mod's current settings.
---@param modId The mod identifier
---@return table|nil The settings table
function M.getSettings(modId)
    local mod = Core.getMod(modId)
    if not mod then return nil end
    return mod.settings
end

--- Update a mod's settings.
---@param modId string The mod identifier
---@param settings table The new settings (merged with existing)
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
