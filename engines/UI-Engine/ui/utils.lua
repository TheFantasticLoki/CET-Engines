--[[
    Utils — UI-Engine

    Shared utility functions for UI-Engine.
    All helper functions go here to avoid duplication.

    No dependencies (leaf module).
]]

local M = {}

-- --- Public API ---

--- Show tooltip on hover
-- @param text Tooltip text
function M.Tooltip(text)
    if text and text ~= "" then
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text(text)
            ImGui.EndTooltip()
        end
    end
end

--- CET hover-state workaround for Selectable
-- @param label Selectable label
-- @param selected Whether the item is selected
-- @return boolean, boolean clicked, selected
function M.SafeSelectable(label, selected)
    -- CET workaround: use pcall to handle hover state issues
    local ok, clicked, nowSelected = pcall(function()
        return ImGui.Selectable(label, selected)
    end)
    if not ok then
        return false, selected
    end
    return clicked, nowSelected
end

--- Generic CET workaround wrapper
-- @param name Workaround name (for logging)
-- @param fn Function to wrap
-- @return function Wrapped function
function M.CETWorkaround(name, fn)
    return function(...)
        local ok, result = pcall(fn, ...)
        if not ok then
            -- Log error but don't crash
            if _G.print then
                _G.print("[CET Workaround] " .. name .. ": " .. tostring(result))
            end
            return nil
        end
        return result
    end
end

--- Deep copy a table
-- @param tbl Table to copy
-- @return table Deep copy
function M.DeepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local result = {}
    for k, v in pairs(tbl) do
        result[k] = M.DeepCopy(v)
    end
    return result
end

--- Merge two tables (override takes precedence)
-- @param base Base table
-- @param override Override table
-- @return table Merged table
function M.MergeTables(base, override)
    if not base then return M.DeepCopy(override) end
    if not override then return M.DeepCopy(base) end

    local result = M.DeepCopy(base)
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = M.MergeTables(result[k], v)
        else
            result[k] = M.DeepCopy(v)
        end
    end
    return result
end

--- Format color table for ImGui
-- @param color Color table with r, g, b, a fields (0-1 range)
-- @return number, number, number, number r, g, b, a
function M.FormatColor(color)
    if not color then
        return 1, 1, 1, 1
    end
    return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

--- Safe pcall-wrapped ImGui call (supports multiple return values)
-- @param fn Function to call
-- @param ... Arguments
-- @return any|nil Result or nil on error
function M.SafeImGuiCall(fn, ...)
    local n = select("#", ...)
    local r1, r2, r3, r4, r5, r6, r7, r8, r9, r10 = pcall(fn, ...)
    if not r1 then
        if _G.UIEngine and _G.UIEngine.Logger then
            _G.UIEngine.Logger.Log("Utils", "ImGui error: " .. tostring(r2), "error")
        end
        return nil
    end
    -- Return all results from the function call (skip the ok status)
    if n == 0 then return end
    if n == 1 then return r2 end
    if n == 2 then return r2, r3 end
    if n == 3 then return r2, r3, r4 end
    if n == 4 then return r2, r3, r4, r5 end
    if n == 5 then return r2, r3, r4, r5, r6 end
    return r2, r3, r4, r5, r6, r7, r8, r9, r10
end

--- Validate component parameters against a schema
-- @param params Parameter table to validate
-- @param schema Schema table {name = type, ...} where type is string type name
-- @return boolean, string|nil success, error message
function M.ValidateComponentParams(params, schema)
    if type(params) ~= "table" then
        return false, "Parameters must be a table"
    end

    for name, expectedType in pairs(schema) do
        local value = params[name]
        if value ~= nil and type(value) ~= expectedType then
            return false, string.format(
                "Invalid type for '%s': expected %s, got %s",
                name, expectedType, type(value)
            )
        end
    end

    return true, nil
end

return M