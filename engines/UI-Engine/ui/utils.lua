--[[
    Utils — UI-Engine

    Shared utility functions for UI-Engine.
    All helper functions go here to avoid duplication.

    No dependencies (leaf module).
]]

---@class Utils
--- Shared utility functions for UI-Engine.
--- All helper functions go here to avoid duplication.
local M = {}

-- --- Public API ---

--- Show tooltip on hover.
---@param text string Tooltip text
function M.Tooltip(text)
    if text and text ~= "" then
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text(text)
            ImGui.EndTooltip()
        end
    end
end

--- CET hover-state workaround for Selectable.
---@param label string Selectable label
---@param selected boolean Whether the item is selected
---@return boolean clicked Whether the item was clicked
---@return boolean isSelected Whether the item is now selected
function M.SafeSelectable(label, selected)
    -- Direct call — CET's FFI breaks with pcall
    local clicked, nowSelected = ImGui.Selectable(label, selected)
    return clicked, nowSelected
end

--- Generic CET workaround wrapper (pcall-safe).
---@param name string Workaround name (for logging)
---@param fn function Function to wrap
---@return function wrapped Wrapped function with error handling
function M.CETWorkaround(name, fn)
    return function(...)
        local ok, result = pcall(fn, ...)
        if not ok then
            local errMsg = "[CET Workaround] " .. name .. ": " .. tostring(result)
            if _G.UIEngine and _G.UIEngine.Logger then
                _G.UIEngine.Logger.Log("Utils", errMsg, "warn")
            else
                print("[UIEngine] " .. errMsg)
            end
            return nil
        end
        return result
    end
end

--- Deep copy a table (recursive).
---@param tbl any Table to copy (non-tables returned as-is)
---@return any copy Deep copy
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

--- Merge two tables (override takes precedence, deep-merges nested tables).
---@param base? table Base table
---@param override? table Override table
---@return table merged Merged table
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

--- Format color table for ImGui (RGBA 0-1 range).
---@param color? table Color table with r, g, b, a fields (0-1 range)
---@return number r Red (0-1)
---@return number g Green (0-1)
---@return number b Blue (0-1)
---@return number a Alpha (0-1)
function M.FormatColor(color)
    if not color then
        return 1, 1, 1, 1
    end
    return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

--- Direct ImGui call wrapper (no pcall — CET's LuaJIT FFI breaks with pcall).
--- Errors propagate to the caller's top-level pcall in onDraw.
---@param fn function Function to call
---@param ... any Arguments
---@return any|nil result Result from function call
function M.SafeImGuiCall(fn, ...)
    return fn(...)
end

--- Validate component parameters against a schema.
---@param params table Parameter table to validate
---@param schema table<string, string> Schema table {name = type} where type is string type name
---@return boolean success Whether validation passed
---@return string|nil error Error message if validation failed, nil on success
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

-- --- Auto-Save Debounce Utilities ---

-- Auto-save debounce (frame-based, since CET's onDraw has no deltaTime)
---@type number Frame at which save becomes pending (0 = no pending save)
local _dirtyFrame = 0
---@type number Current frame number
local _currentFrame = 0
---@type number Frames to wait before auto-save triggers (~0.5s at 60fps)
local SAVE_DELAY_FRAMES = 30

--- Mark state as dirty (triggers auto-save debounce).
function M.markDirty()
    _dirtyFrame = _currentFrame + SAVE_DELAY_FRAMES
end

--- Update frame counter (called each frame).
---@param frame number Current frame number
function M.updateFrame(frame)
    _currentFrame = frame or 0
end

--- Check if save is pending (debounce timer elapsed).
---@return boolean pending True if save should be triggered
function M.isSavePending()
    return _dirtyFrame > 0 and _currentFrame >= _dirtyFrame
end

--- Clear pending save (call after successful save).
function M.clearPendingSave()
    _dirtyFrame = 0
end

--- Check if state is dirty (any unsaved changes).
---@return boolean dirty True if dirty
function M.isDirty()
    return _dirtyFrame > 0
end

return M