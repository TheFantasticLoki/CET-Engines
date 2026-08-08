--[[
    Logger — UI-Engine (Adapter)

    Thin adapter that delegates to Log-Engine for unified logging.
    Preserves the legacy Logger.Log(modName, msg, level) API while routing
    all output through Log-Engine's ring buffer, file output, and dedup.

    Phase 1 of logger consolidation (C4 fix).
    Phase 2 will migrate callers to use Log-Engine instances directly.
    Phase 3 will remove this adapter entirely.
]]

---@class LegacyLogger
--- Adapter that delegates to Log-Engine for unified logging.
local M = {}

-- --- Internal State ---

---@type boolean Whether adapter has been initialized
local initialized = false
---@type table|nil Log-Engine logger instance
local _logger = nil

-- --- Public API ---

--- Initialize the adapter (idempotent).
--- Creates a Log-Engine logger instance for legacy callers.
---@param config? table Optional configuration (ignored, kept for API compat)
function M.init(config)
    if initialized then
        return
    end
    initialized = true

    -- Resolve Log-Engine via pcall (safe for load-order issues)
    local ok, LogEngine = pcall(require, "log/init")
    if ok and LogEngine and LogEngine.CreateLogger then
        local ok2, lgr = pcall(LogEngine.CreateLogger, "Legacy", { minLevel = "debug" })
        if ok2 and lgr then
            _logger = lgr
        end
    end
end

--- Set the current frame number (no-op — Log-Engine manages frames internally).
---@param frame number Frame number
function M.SetFrame(frame)
    -- Log-Engine handles frame counting internally
end

--- Set the minimum log level.
---@param level string Level name string ("debug", "info", "warn", "error")
function M.SetLevel(level)
    if _logger and _logger.setLevel then
        _logger.setLevel(level)
    end
end

--- Get the current minimum log level.
---@return number minLevel Current minimum level (1=debug)
function M.GetLevel()
    if _logger and _logger.getLevel then
        return _logger.getLevelNum() or 1
    end
    return 1
end

--- Enable or disable the ImGui overlay (no-op — Log-Engine handles overlay).
---@param enabled boolean Whether overlay should be shown
function M.SetOverlay(enabled)
    -- Log-Engine manages overlay rendering
end

--- Check if the overlay is enabled.
---@return boolean enabled Whether overlay is enabled
function M.IsOverlayEnabled()
    return false
end

--- Set max debug messages per frame (delegates to Log-Engine).
---@param count number Max debug messages per frame
function M.SetMaxDebugPerFrame(count)
    if _logger and _logger.setMaxDebugPerFrame then
        _logger.setMaxDebugPerFrame(count)
    end
end

--- Get max debug messages per frame.
---@return number Max debug messages per frame
function M.GetMaxDebugPerFrame()
    return 1
end

--- Log a message at the specified level.
--- Routes through Log-Engine with module name prefix.
---@param modName string Module name
---@param message string Log message
---@param level? string Level name string ("debug", "info", "warn", "error")
function M.Log(modName, message, level)
    if not _logger then return end

    local msg = "[" .. (modName or "unknown") .. "] " .. (message or "")
    local lvl = level or "info"

    if lvl == "error" then
        _logger.error(msg)
    elseif lvl == "warn" then
        _logger.warn(msg)
    elseif lvl == "debug" then
        _logger.debug(msg)
    else
        _logger.info(msg)
    end
end

--- Get recent log entries (delegates to Log-Engine).
---@param count? number Number of entries to retrieve (default: 50)
---@param filterMod? string Optional module name filter
---@param filterLevel? string Optional minimum level filter
---@return table[] entries Array of log entries
function M.GetEntries(count, filterMod, filterLevel)
    if _logger and _logger.getEntries then
        return _logger.getEntries(count or 50, filterLevel)
    end
    return {}
end

--- Clear all log entries (no-op — Log-Engine manages its own buffer).
---@return void
function M.Clear()
    -- Log-Engine manages its own ring buffer
end

--- Draw the ImGui overlay (no-op — Log-Engine handles overlay rendering).
---@return void
function M.Draw()
    -- Log-Engine manages overlay rendering
end

return M