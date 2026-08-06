-- Config-Engine Settings Resolver
-- Merges defaults with saved values, validates against schema.

---@class SettingsResolver
---Pure data resolution: merge defaults with saved values, validate against schema, get/set nested values.
local M = {}

--- Get the default value for a setting definition.
--- Duplicated from settings_schema to avoid circular dependency in tests.
---@param setting table<string, any> The setting definition table
---@return any default The default value
function M._getDefault(setting)
    if setting.type == "color" then
        if setting.default then
            return { r = setting.default.r, g = setting.default.g, b = setting.default.b, a = setting.default.a }
        end
        return { r = 1, g = 1, b = 1, a = 1 }
    end
    if setting.type == "multi_combo" then
        if setting.default then
            local copy = {}
            for i, v in ipairs(setting.default) do
                copy[i] = v
            end
            return copy
        end
        return {}
    end
    return setting.default
end

--- Resolve settings by merging defaults with saved values.
--- Validates each value against its schema definition.
---@param schema table<string, any> The mod's settings schema
---@param saved? table<string, any> The saved settings table (may be nil or partial)
---@return table<string, any> resolved Resolved settings (all keys present with valid values)
---@return string[] warnings Array of warning strings
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

--- Validate a value against a setting definition.
---@param setting table<string, any> The setting definition
---@param value any The value to validate
---@return boolean valid True if valid
function M.validateValue(setting, value)
    if not setting or not setting.type then
        return false
    end

    local t = setting.type

    if t == "toggle" then
        return type(value) == "boolean"

    elseif t == "slider" then
        if type(value) ~= "number" then return false end
        if setting.min and value < setting.min then return false end
        if setting.max and value > setting.max then return false end
        return true

    elseif t == "int_slider" then
        if type(value) ~= "number" then return false end
        if value ~= math.floor(value) then return false end
        if setting.min and value < setting.min then return false end
        if setting.max and value > setting.max then return false end
        return true

    elseif t == "combo" then
        if not setting.options then return false end
        -- Value can be string or number matching an option
        for _, opt in ipairs(setting.options) do
            if type(opt) == "table" then
                if opt.value == value then return true end
            else
                if opt == value then return true end
            end
        end
        return false

    elseif t == "multi_combo" then
        if type(value) ~= "table" then return false end
        return true

    elseif t == "text" then
        return type(value) == "string"

    elseif t == "number" then
        if type(value) ~= "number" then return false end
        if setting.min and value < setting.min then return false end
        if setting.max and value > setting.max then return false end
        return true

    elseif t == "color" then
        if type(value) ~= "table" then return false end
        if value.r == nil or value.g == nil or value.b == nil then return false end
        return true

    elseif t == "keybind" then
        return type(value) == "string"

    elseif t == "info" or t == "header" then
        return true

    elseif t == "button" then
        return true

    elseif t == "custom" then
        return true

    else
        return false
    end
end

--- Get a nested setting value using dot-separated key path.
---@param settings table<string, any> The resolved settings table
---@param keyPath string Dot-separated key path (e.g., "advanced.debug")
---@return any? value The value, or nil if not found
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
---@param settings table<string, any> The resolved settings table (modified in place)
---@param keyPath string Dot-separated key path
---@param value any The new value
---@return boolean set True if the value was set
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
