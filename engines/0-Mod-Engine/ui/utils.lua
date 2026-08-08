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

-- --- Auto-Save Debounce Utilities ---

-- Auto-save debounce (frame-based, since CET's onDraw has no deltaTime)
---@type number Frame when save becomes pending
local _dirtyFrame = 0
---@type number Current frame counter
local _currentFrame = 0
---@type number Number of frames to wait before saving (~0.5s at 60fps)
local SAVE_DELAY_FRAMES = 30  -- ~0.5s at 60fps

--- Update frame counter (called each frame)
---@param frame number Current frame number
function M.updateFrame(frame)
    _currentFrame = frame or 0
end

--- Mark state as dirty (used by tests)
function M.markDirty()
    _dirtyFrame = _currentFrame + SAVE_DELAY_FRAMES
end

--- Check if save is pending (used by tests)
---@return boolean pending True if save delay has elapsed
function M.isSavePending()
    return _dirtyFrame > 0 and _currentFrame >= _dirtyFrame
end

--- Clear pending save (used by tests)
---@return void
function M.clearPendingSave()
    _dirtyFrame = 0
end

--- Check if state is dirty (used by tests)
---@return boolean dirty True if dirty
function M.isDirty()
    return _dirtyFrame > 0
end

return M