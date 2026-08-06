--[[
    Logger — UI-Engine

    Leveled logging system with ring buffer, file output,
    ImGui overlay, and rate-limited debug messages.

    Log levels: debug, info, warn, error
    Ring buffer: 512 entries
    File output: 4 rotating files
    Rate limiting: 1 debug message per frame to console
]]

---@class LegacyLogEntry
---@field timestamp string Timestamp in ISO format
---@field frame number Frame counter when logged
---@field modName string Source module name
---@field message string Log message
---@field level number Numeric log level
---@field levelName string Level name string

---@class LegacyLogger
--- Leveled logging system with ring buffer, file output, ImGui overlay,
--- and rate-limited debug messages. This is the legacy UI-Engine logger.
local M = {}

-- --- Constants ---

local MAX_ENTRIES = 512
local MAX_FILE_SIZE = 1024 * 1024  -- 1MB per file
local MAX_FILES = 4
local LEVEL_DEBUG = 1
local LEVEL_INFO = 2
local LEVEL_WARN = 3
local LEVEL_ERROR = 4

local LEVEL_NAMES = {
    [LEVEL_DEBUG] = "DEBUG",
    [LEVEL_INFO] = "INFO",
    [LEVEL_WARN] = "WARN",
    [LEVEL_ERROR] = "ERROR",
}

-- --- Internal State ---

---@type table<number, LegacyLogEntry> Ring buffer entries
local entries = {}
---@type number Total entries logged (including overwritten)
local entryCount = 0
---@type number Current frame number
local currentFrame = 0
---@type number Debug messages logged this frame
local debugCountThisFrame = 0
---@type number Max debug messages per frame
local maxDebugPerFrame = 1
---@type number Current minimum log level
local minLevel = LEVEL_DEBUG
---@type boolean Whether ImGui overlay is enabled
local overlayEnabled = false
---@type boolean Whether logger has been initialized
local initialized = false

-- File output state
---@type string|nil Current log file path
local logFilePath = nil
---@type number Current log file index
local logFileIndex = 0

-- --- Helper Functions ---

--- Get the current timestamp string
---@return string Timestamp in ISO format
local function getTimestamp()
    return os.date("%Y-%m-%dT%H:%M:%S")
end

--- Get the level name for a numeric level.
---@param level number Numeric log level
---@return string name Level name
local function getLevelName(level)
    return LEVEL_NAMES[level] or "UNKNOWN"
end

--- Get the numeric level for a string level.
---@param levelStr string Level name string
---@return number level Numeric level
local function getLevelNum(levelStr)
    if levelStr == "debug" then return LEVEL_DEBUG end
    if levelStr == "info" then return LEVEL_INFO end
    if levelStr == "warn" then return LEVEL_WARN end
    if levelStr == "error" then return LEVEL_ERROR end
    return LEVEL_DEBUG
end

--- Write a log entry to the ring buffer.
---@param modName string Module name
---@param message string Log message
---@param level number Numeric log level
---@return LegacyLogEntry entry The added entry
local function addEntry(modName, message, level)
    local entry = {
        timestamp = getTimestamp(),
        frame = currentFrame,
        modName = modName or "unknown",
        message = message or "",
        level = level or LEVEL_DEBUG,
        levelName = getLevelName(level or LEVEL_DEBUG),
    }

    -- Ring buffer: overwrite oldest entry when full
    entryCount = entryCount + 1
    local idx = ((entryCount - 1) % MAX_ENTRIES) + 1
    entries[idx] = entry
    return entry
end

--- Write log entry to file (if file output is enabled).
---@param entry LegacyLogEntry Log entry to write
local function writeToFile(entry)
    if not logFilePath then return end

    local ok, err = pcall(function()
        local f = io.open(logFilePath, "a")
        if f then
            f:write(string.format("[%s] [%s] [%s] %s: %s\n",
                entry.timestamp,
                entry.levelName,
                entry.frame,
                entry.modName,
                entry.message))
            f:close()
        end
    end)

    if not ok then
        -- Silently fail on file write errors
        -- Don't recurse into logger
    end
end

--- Rotate log files
local function rotateFiles()
    if not logFilePath then return end

    -- Simple rotation: shift files
    for i = MAX_FILES - 1, 1, -1 do
        local src = logFilePath .. "." .. i
        local dst = logFilePath .. "." .. (i + 1)
        pcall(function()
            os.rename(src, dst)
        end)
    end

    -- Current file becomes .1
    pcall(function()
        os.rename(logFilePath, logFilePath .. ".1")
    end)
end

-- --- Public API ---

--- Initialize the logger (idempotent).
---@param config? table Optional configuration table { logFilePath, minLevel, overlayEnabled }
function M.init(config)
    if initialized then
        return
    end
    initialized = true

    config = config or {}

    if config.logFilePath then
        logFilePath = config.logFilePath
    end

    if config.minLevel then
        minLevel = getLevelNum(config.minLevel)
    end

    if config.overlayEnabled ~= nil then
        overlayEnabled = config.overlayEnabled
    end
end

--- Set the current frame number (called each frame).
---@param frame number Frame number
function M.SetFrame(frame)
    currentFrame = frame or 0
    debugCountThisFrame = 0
end

--- Set the minimum log level.
---@param level string Level name string ("debug", "info", "warn", "error")
function M.SetLevel(level)
    minLevel = getLevelNum(level)
end

--- Get the current minimum log level.
---@return number minLevel Current minimum level
function M.GetLevel()
    return minLevel
end

--- Enable or disable the ImGui overlay.
---@param enabled boolean Whether overlay should be shown
function M.SetOverlay(enabled)
    overlayEnabled = enabled
end

--- Check if the overlay is enabled.
---@return boolean enabled Whether overlay is enabled
function M.IsOverlayEnabled()
    return overlayEnabled
end

--- Set max debug messages per frame.
---@param count number Max debug messages per frame
function M.SetMaxDebugPerFrame(count)
    maxDebugPerFrame = count or 1
end

--- Get max debug messages per frame.
---@return number Max debug messages per frame
function M.GetMaxDebugPerFrame()
    return maxDebugPerFrame
end

--- Log a message at the specified level.
---@param modName string Module name
---@param message string Log message
---@param level? string Level name string ("debug", "info", "warn", "error")
function M.Log(modName, message, level)
    local levelNum = getLevelNum(level or "info")

    -- Check minimum level
    if levelNum < minLevel then
        return
    end

    -- Rate limiting for debug messages
    if levelNum == LEVEL_DEBUG then
        debugCountThisFrame = debugCountThisFrame + 1
        if debugCountThisFrame > maxDebugPerFrame then
            return  -- Rate limited
        end
    end

    -- Add to ring buffer
    addEntry(modName, message, levelNum)

    -- Write to file
    writeToFile(entries[((entryCount - 1) % MAX_ENTRIES) + 1])
end

--- Get recent log entries from the ring buffer.
---@param count? number Number of entries to retrieve (default: 50)
---@param filterMod? string Optional module name filter
---@param filterLevel? string Optional minimum level filter
---@return LegacyLogEntry[] entries Array of log entries
function M.GetEntries(count, filterMod, filterLevel)
    count = count or 50
    filterLevel = filterLevel and getLevelNum(filterLevel) or LEVEL_DEBUG

    local result = {}
    -- Clamp startIdx to the oldest entry in the ring buffer
    local maxStored = math.min(entryCount, MAX_ENTRIES)
    local startIdx = math.max(entryCount - maxStored + 1, entryCount - count + 1)
    startIdx = math.max(1, startIdx)

    for i = startIdx, entryCount do
        local idx = ((i - 1) % MAX_ENTRIES) + 1
        local entry = entries[idx]
        if entry then
            if (not filterMod or entry.modName == filterMod) and entry.level >= filterLevel then
                table.insert(result, entry)
            end
        end
    end

    return result
end

--- Clear all log entries
---@return void
function M.Clear()
    entries = {}
    entryCount = 0
    debugCountThisFrame = 0
end

--- Draw the ImGui overlay (if enabled).
--- Stub — actual ImGui rendering will be implemented when Window module is created.
---@return void
function M.Draw()
    if not overlayEnabled then
        return
    end

    -- This is a stub — actual ImGui rendering will be implemented
    -- when the Window module is created. For now, this is a no-op
    -- that can be called safely.
end

return M