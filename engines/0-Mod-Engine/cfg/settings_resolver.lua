-- Config-Engine Settings Resolver
-- Merges defaults with saved values, validates against schema.

---@class SettingsResolver
local M = {}

--- Get the default value for a setting definition.
-- Delegates to SettingsSchema.getDefault to avoid duplication.
---@param setting table The setting definition table
---@return any The default value
function M._getDefault(setting)
    local Schema = require("cfg/settings_schema")
    return Schema.getDefault(setting)
end

--- Resolve settings by merging defaults with saved values.
-- Validates each value against its schema definition.
---@param schema table The mod's settings schema
---@param saved table|nil The saved settings table (may be nil or partial)
---@return table Resolved settings (all keys present with valid values)
---@return string[] Warnings array of warning strings
function M.resolveSettings(schema, saved)
    local resolved = {}
    local warnings = {}

    if not schema or not schema.settings then
        return resolved, warnings
    end

    saved = saved or {}

    for key, setting in pairs(schema.settings) do
        local value = saved[key]
        local default = M._getDefault(setting)

        if setting.type == "group" and setting.settings then
            -- Recurse into group settings
            local subSaved = saved[key] or {}
            local subResolved, subWarnings = M.resolveSettings(
                { settings = setting.settings },
                subSaved
            )
            resolved[key] = subResolved
            for _, w in ipairs(subWarnings) do
                table.insert(warnings, key .. "." .. w)
            end
        elseif value ~= nil then
            -- Validate saved value
            local valid = M.validateValue(setting, value)
            if valid then
                resolved[key] = value
            else
                -- Saved value invalid, fall back to default
                resolved[key] = default
                table.insert(warnings, key .. ": saved value invalid, using default")
            end
        else
            -- No saved value, use default
            resolved[key] = default
        end
    end

    return resolved, warnings
end

--- Validate a value against a setting definition (delegates to SettingsSchema).
---@param setting table The setting definition
---@param value any The value to validate
---@return boolean True if valid
function M.validateValue(setting, value)
    -- Lazy-load Schema to avoid circular dependency in tests
    local Schema = require("cfg/settings_schema")
    return Schema.validateValue(setting, value)
end

--- Get a nested setting value using dot-separated key path.
---@param settings table The resolved settings table
---@param keyPath string Dot-separated key path (e.g., "advanced.debug")
---@return any The value, or nil if not found
function M.getValue(settings, keyPath)
    local parts = {}
    for part in keyPath:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    local current = settings
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end

    return current
end

--- Set a nested setting value using dot-separated key path.
---@param settings table The resolved settings table (modified in place)
---@param keyPath string Dot-separated key path
---@param value any The new value
---@return boolean True if the value was set
function M.setValue(settings, keyPath, value)
    local parts = {}
    for part in keyPath:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    local current = settings
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end

    current[parts[#parts]] = value
    return true
end

return M
