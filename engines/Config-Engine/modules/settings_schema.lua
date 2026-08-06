-- Config-Engine Settings Schema System
-- Defines setting types, validation, and schema management.

---@class SettingsSchema
---Setting type definitions, schema validation, index building, and default resolution.
local M = {}

---@type Logger?
local log = nil

-- Valid setting types
local VALID_TYPES = {
    toggle = true,
    slider = true,
    int_slider = true,
    combo = true,
    multi_combo = true,
    text = true,
    number = true,
    color = true,
    keybind = true,
    header = true,
    group = true,
    info = true,
    button = true,
    custom = true,
}

-- Types that don't need a default value
local NO_DEFAULT_TYPES = {
    info = true,
    header = true,
    group = true,
    button = true,
    custom = true,
}

--- Validate a complete schema table.
---@param schema table<string, any> The schema table to validate
---@return boolean success
---@return string[]? errors Array of error strings
function M.validateSchema(schema)
    local errors = {}

    if not schema or type(schema) ~= "table" then
        return false, { "Schema must be a table" }
    end

    if not schema.settings or type(schema.settings) ~= "table" then
        return false, { "Schema must have 'settings' table" }
    end

    for key, setting in pairs(schema.settings) do
        local ok, errs = M.validateSetting(key, setting)
        if not ok then
            for _, err in ipairs(errs) do
                table.insert(errors, key .. ": " .. err)
            end
        end
    end

    return #errors == 0, #errors > 0 and errors or nil
end

--- Validate a single setting definition.
---@param key string The setting key (for error messages)
---@param setting table<string, any> The setting definition table
---@return boolean success
---@return string[]? errors Array of error strings
function M.validateSetting(key, setting)
    local errors = {}

    if not setting or type(setting) ~= "table" then
        return false, { "setting must be a table" }
    end

    -- Type check
    if not setting.type then
        table.insert(errors, "missing 'type'")
    elseif not VALID_TYPES[setting.type] then
        table.insert(errors, "unknown type: " .. tostring(setting.type))
    end

    -- Default value check (skip for info/header)
    if setting.type and not NO_DEFAULT_TYPES[setting.type] then
        if setting.default == nil and setting.type ~= "button" then
            table.insert(errors, "missing 'default'")
        end
    end

    -- Slider validation
    if setting.type == "slider" or setting.type == "int_slider" then
        if setting.min == nil then
            table.insert(errors, "slider missing 'min'")
        end
        if setting.max == nil then
            table.insert(errors, "slider missing 'max'")
        end
        if setting.min ~= nil and setting.max ~= nil and setting.min >= setting.max then
            table.insert(errors, "min must be < max")
        end
    end

    -- Combo validation
    if setting.type == "combo" then
        if not setting.options or type(setting.options) ~= "table" then
            table.insert(errors, "combo missing 'options'")
        end
    end

    -- Multi-combo validation
    if setting.type == "multi_combo" then
        if not setting.options or type(setting.options) ~= "table" then
            table.insert(errors, "multi_combo missing 'options'")
        end
        if setting.default ~= nil and type(setting.default) ~= "table" then
            table.insert(errors, "multi_combo default must be a table")
        end
    end

    -- Color validation
    if setting.type == "color" then
        local d = setting.default
        if d ~= nil then
            if type(d) ~= "table" or d.r == nil or d.g == nil or d.b == nil then
                table.insert(errors, "color default must be {r, g, b}")
            end
        end
    end

    -- Group validation (recursive)
    if setting.type == "group" then
        if not setting.settings or type(setting.settings) ~= "table" then
            table.insert(errors, "group missing 'settings'")
        else
            for subKey, subSetting in pairs(setting.settings) do
                local ok, errs = M.validateSetting(key .. "." .. subKey, subSetting)
                if not ok then
                    for _, err in ipairs(errs) do
                        table.insert(errors, err)
                    end
                end
            end
        end
    end

    -- Custom type requires render function
    if setting.type == "custom" then
        if not setting.render or type(setting.render) ~= "function" then
            table.insert(errors, "custom type requires 'render' function")
        end
    end

    local success = #errors == 0
    if not success and log then
        log.warn("Setting validation failed for '" .. key .. "': " .. table.concat(errors, "; "))
    end
    return success, #errors > 0 and errors or nil
end

--- Get the default value for a setting.
---@param setting table<string, any> The setting definition
---@return any default The default value
function M.getDefault(setting)
    if setting.type == "color" then
        -- Deep copy color tables
        if setting.default then
            return { r = setting.default.r, g = setting.default.g, b = setting.default.b, a = setting.default.a }
        end
        return { r = 1, g = 1, b = 1, a = 1 }
    end
    if setting.type == "multi_combo" then
        -- Deep copy arrays
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

--- Build a flat index of all setting keys in a schema (for search).
---@param settings table<string, table> The settings table (may be nested with groups)
---@param prefix? string[] Key prefix for nested settings
---@return table[] Array of { key: string, label: string, type: string } entries
function M.buildIndex(settings, prefix)
    prefix = prefix or {}
    local index = {}

    for key, setting in pairs(settings) do
        local fullKey = table.concat(prefix, ".")
        if #prefix > 0 then
            fullKey = fullKey .. "." .. key
        else
            fullKey = key
        end

        table.insert(index, {
            key = fullKey,
            label = setting.label or key,
            type = setting.type,
        })

        -- Recurse into groups
        if setting.type == "group" and setting.settings then
            local subPrefix = {}
            for _, v in ipairs(prefix) do
                table.insert(subPrefix, v)
            end
            table.insert(subPrefix, key)
            local subIndex = M.buildIndex(setting.settings, subPrefix)
            for _, entry in ipairs(subIndex) do
                table.insert(index, entry)
            end
        end
    end

    return index
end

--- Collect all setting keys and their definitions into a flat table.
---@param settings table<string, table> The settings table (may be nested with groups)
---@param prefix? string[] Key prefix for nested settings
---@return table<string, table> Flat map of { [fullKey: string] = settingDef }
function M.flattenSettings(settings, prefix)
    prefix = prefix or {}
    local flat = {}

    for key, setting in pairs(settings) do
        local fullKey = table.concat(prefix, ".")
        if #prefix > 0 then
            fullKey = fullKey .. "." .. key
        else
            fullKey = key
        end

        flat[fullKey] = setting

        if setting.type == "group" and setting.settings then
            local subPrefix = {}
            for _, v in ipairs(prefix) do
                table.insert(subPrefix, v)
            end
            table.insert(subPrefix, key)
            local subFlat = M.flattenSettings(setting.settings, subPrefix)
            for k, v in pairs(subFlat) do
                flat[k] = v
            end
        end
    end

    return flat
end

return M
