--[[
    Utils — UI-Engine

    Shared utility functions for UI-Engine.
    All helper functions go here to avoid duplication.

    No dependencies (leaf module).
]]

---@class Utils
--- Shared utility functions for UI-Engine.
--- All helper functions go here to avoid duplication.
--- No dependencies (leaf module).
local M = {}

-- --- Public API ---

--- Show tooltip on hover
---@param text Tooltip text
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
---@param label Selectable label
---@param selected Whether the item is selected
---@return boolean, boolean clicked, selected
function M.SafeSelectable(label, selected)
    -- Direct call — CET's FFI breaks with pcall
    local clicked, nowSelected = ImGui.Selectable(label, selected)
    return clicked, nowSelected
end

--- Generic CET workaround wrapper
---@param name Workaround name (for logging)
---@param fn Function to wrap
---@return function Wrapped function
function M.CETWorkaround(name, fn)
    return function(...)
        local ok, result = pcall(fn, ...)
        if not ok then
            local errMsg = "[CET Workaround] " .. name .. ": " .. tostring(result)
            if Logger then
                Logger.Log("Utils", errMsg, "warn")
            else
                print("[ModEngine Utils] " .. errMsg)
            end
            return nil
        end
        return result
    end
end

--- Deep copy a table
---@param tbl Table to copy
---@return table Deep copy
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

--- Resolve a logger instance from Log-Engine with fallback
---@param name string Logger name
---@param level string? Minimum log level (default: "warn")
---@return table? logger Logger instance or nil
function M.ResolveLogger(name, level)
    local ok, LogEngine = pcall(require, "log/init")
    if ok and LogEngine then
        local ok2, lgr = pcall(LogEngine.CreateLogger, name, { minLevel = level or "warn" })
        if ok2 and lgr then return lgr end
    end
    return nil
end

--- Generate a theme cache key from current core state
---@param core CoreState Core state module
---@return string Cache key
function M.GetThemeCacheKey(core)
    if not core then return "default" end

    local themeName = core.getCurrentTheme() or "Dark"
    local accent = core.getAccentColor() or { r = 0.4, g = 0.6, b = 1.0 }
    local contrast = core.getContrastLevel() or 1

    return themeName .. ":" .. tostring(accent.r) .. ":" .. tostring(accent.g) .. ":" .. tostring(accent.b) .. ":" .. tostring(contrast)
end

--- Merge two tables (override takes precedence)
---@param base Base table
---@param override Override table
---@return table Merged table
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
---@param color Color table with r, g, b, a fields (0-1 range)
---@return number, number, number, number r, g, b, a
function M.FormatColor(color)
    if not color then
        return 1, 1, 1, 1
    end
    return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

--- Direct ImGui call wrapper (no pcall — CET's LuaJIT FFI breaks with pcall)
-- Previously wrapped in pcall which broke CET's FFI binding.
-- Now passes through directly. Errors propagate to the caller's
-- top-level pcall in onDraw.
---@param fn Function to call
---@param ... Arguments
---@return any|nil Result
function M.SafeImGuiCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    return fn(...)
end

--- Validate component parameters against a schema
---@param params Parameter table to validate
---@param schema Schema table {name = type, ...} where type is string type name
---@return boolean, string|nil success, error message
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
---@type number Frame when save becomes pending
local _dirtyFrame = 0
---@type number Current frame counter
local _currentFrame = 0
---@type number Number of frames to wait before saving (~0.5s at 60fps)
local SAVE_DELAY_FRAMES = 30  -- ~0.5s at 60fps

--- Mark state as dirty (triggers auto-save debounce)
function M.markDirty()
    _dirtyFrame = _currentFrame + SAVE_DELAY_FRAMES
end

--- Update frame counter (called each frame)
---@param frame number Current frame number
function M.updateFrame(frame)
    _currentFrame = frame or 0
end

--- Check if save is pending
---@return boolean pending True if save delay has elapsed
function M.isSavePending()
    return _dirtyFrame > 0 and _currentFrame >= _dirtyFrame
end

--- Clear pending save
---@return void
function M.clearPendingSave()
    _dirtyFrame = 0
end

--- Check if state is dirty
---@return boolean dirty True if dirty
function M.isDirty()
    return _dirtyFrame > 0
end

return M