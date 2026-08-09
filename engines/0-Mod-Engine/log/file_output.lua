--[[
    FileOutput — Log-Engine

    Handles all file I/O for Log-Engine.
    One file handle per mod, size-based rotation, CET-compatible.

    Rotation: mod.log -> mod.log.1 -> mod.log.2 -> ... -> mod.log.N (oldest deleted)
    Uses read-modify-write for rotation (NOT os.rename) for Windows CET compatibility.

    Features:
    - Session headers with session ID, start time, mod name, level, ring buffer size
    - Simplified timestamps (time-only, since date is in header)
    - Dedup summary writing
]]

local M = {}

-- --- SafeRequire (inline, no external deps) ---
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then return mod end
    return nil
end

-- Config values inlined with fallbacks (CET require may not resolve siblings)
local Config = SafeRequire("log/config") or {}

---@class FileOutput
--- Handles all file I/O for Log-Engine.
--- One file handle per mod, size-based rotation, CET-compatible.

-- Module-level logger (set by init.lua via setLogger)
---@type Logger?
local log = nil

-- --- Internal State ---

---@type boolean Whether file output has been initialized
local initialized = false
---@type string Log directory path (empty = write in mod's own directory)
local logDir = Config.LOG_DIR or ""  -- Empty = write logs in mod's own directory (CET can't create dirs)
---@type number Max file size in bytes before rotation
local maxFileSize = Config.MAX_FILE_SIZE or (2 * 1024 * 1024)
---@type number Max number of rotated files to keep
local maxFiles = Config.MAX_FILES or 5
---@type string Log file extension
local LOG_FILE_SUFFIX = Config.LOG_FILE_SUFFIX or ".log"
---@type table<string, file*> Cached file handles per mod
local fileHandles = {}   -- modName -> file handle (cached)
---@type table<string, string> Resolved file paths per mod
local filePaths = {}     -- modName -> resolved file path
---@type table<string, string> User-overridden paths per mod
local customPaths = {}   -- modName -> user-overridden path
---@type table<string, number> Current file size per mod (approximate)
local fileSizes = {}     -- modName -> current file size (approximate)
---@type table<string, boolean> Whether header has been written per mod
local headerWritten = {} -- modName -> true (whether header has been written)

-- Session ID (set by init.lua via setSessionId)
---@type string Current session ID
local sessionId = ""

--- Set the module-level logger (called by init.lua after creation)
---@param logger Logger? Logger instance or nil to disable
function M.setLogger(logger)
    log = logger
end

--- Set the log directory path
---@param dir string Log directory path
function M.setLogDir(dir)
    logDir = dir or ""
    -- Clear cached paths so they resolve with new dir
    filePaths = {}
end

--- Set max file size before rotation
---@param size number Max file size in bytes
function M.setMaxFileSize(size)
    maxFileSize = size or (2 * 1024 * 1024)
end

--- Set max number of rotated files
---@param count number Max rotated files
function M.setMaxFiles(count)
    maxFiles = count or 5
end

-- --- Helper Functions ---

--- Get the mod's own directory path (for relative path resolution)
-- In CET, io.open with relative paths resolves from the CET working directory.
-- We write to a "logs/" subdirectory relative to the working directory.
-- Note: debug.getinfo is NOT available in CET's sandboxed Lua.
---@return string Base directory prefix (empty string = current directory)
local function getLogEngineDir()
    -- CET sandbox does not expose the `debug` library.
    -- Use a simple relative path instead.
    return ""
end

--- Resolve the file path for a mod
---@param modName Mod identifier
---@return string Resolved file path
local function resolvePath(modName)
    -- Check for custom path first
    if customPaths[modName] then
        return customPaths[modName]
    end

    -- Check cached path
    if filePaths[modName] then
        return filePaths[modName]
    end

    -- CET's io.open resolves relative to the CET working directory,
    -- which is the cyber_engine_tweaks/ root. Write logs to logs/ subdirectory.
    local prefix = ""
    if logDir and logDir ~= "" then
        prefix = logDir .. "/"
    end
    local path = prefix .. modName .. LOG_FILE_SUFFIX
    filePaths[modName] = path
    return path
end

--- Get file size (approximate, by reading current position after append)
---@param modName Mod identifier
---@return number Size in bytes
local function getFileSize(modName)
    local path = resolvePath(modName)
    local ok, size = pcall(function()
        local f = io.open(path, "r")
        if not f then return 0 end
        f:seek("end")
        local s = f:seek()
        f:close()
        return s
    end)
    return ok and size or 0
end

--- Rotate log files for a mod (CET-compatible, read-modify-write)
--- Uses chunked I/O to avoid loading entire files into memory.
---@param modName Mod identifier
local function rotateFile(modName)
    local path = resolvePath(modName)

    -- Shift files: .N-1 -> .N (down to .1)
    for i = maxFiles - 1, 1, -1 do
        local src = path .. "." .. i
        local dst = path .. "." .. (i + 1)
        pcall(function()
            local sf = io.open(src, "r")
            if sf then
                local df = io.open(dst, "w")
                if df then
                    -- Stream in chunks to avoid loading entire file
                    while true do
                        local chunk = sf:read(8192)
                        if not chunk then break end
                        df:write(chunk)
                    end
                    df:close()
                end
                sf:close()
            end
        end)
    end

    -- Current file becomes .1
    pcall(function()
        local cf = io.open(path, "r")
        if cf then
            local nf = io.open(path .. ".1", "w")
            if nf then
                -- Stream in chunks
                while true do
                    local chunk = cf:read(8192)
                    if not chunk then break end
                    nf:write(chunk)
                end
                nf:close()
            end
            cf:close()
            -- Truncate current file
            local tf = io.open(path, "w")
            if tf then
                tf:close()
            end
        end
    end)

    -- Reset tracked size
    fileSizes[modName] = 0

    -- Mark header as not written for the new file
    headerWritten[modName] = false
end

--- Write session header to a log file
---@param modName Mod identifier
---@param config table Logger config (minLevel, ringSize, etc.)
local function writeHeader(modName, config)
    if headerWritten[modName] then return end

    local path = resolvePath(modName)
    local startTime = os.date("%Y-%m-%dT%H:%M:%S")
    local levelName = "debug"
    if config and config.minLevel then
        levelName = config.minLevel
    end
    local ringSize = (config and config.ringSize) or Config.RING_SIZE or 1024

    local header = string.format(
        "=== Log Session ===\n" ..
        "Session: %s\n" ..
        "Started: %s\n" ..
        "Mod: %s\n" ..
        "Level: %s\n" ..
        "Ring Buffer: %d\n" ..
        "===================\n",
        sessionId or "unknown",
        startTime,
        modName,
        levelName,
        ringSize
    )

    pcall(function()
        local f = io.open(path, "a")
        if f then
            f:write(header)
            f:close()
            fileSizes[modName] = (fileSizes[modName] or 0) + #header
        end
    end)

    headerWritten[modName] = true
end

--- Format a log entry for file output (time-only timestamp)
---@param entry Log entry table
---@return string Formatted line
local function formatLine(entry)
    return string.format("[%s] [%s] [%s] %s: %s\n",
        entry.timestamp or "",
        entry.levelName or "UNKNOWN",
        entry.frame or 0,
        entry.modName or "",
        entry.message or "")
end

--- Format a dedup summary line
---@param modName Mod identifier
---@param count number Number of duplicates
---@param firstSeen string Timestamp of first occurrence
---@param message string Original message
---@return string Formatted dedup line
local function formatDedupSummary(modName, count, firstSeen, message)
    return string.format("[%s] [DEDUP] [%s] %s: [x%d duplicates since %s] %s\n",
        os.date("%H:%M:%S"),
        0,
        modName,
        count,
        firstSeen,
        message)
end

-- --- Public API ---

--- Initialize file output module (idempotent)
---@param config Optional configuration overrides
--- Initialize file output module (idempotent)
---@param config table? Optional configuration overrides
function M.init(config)
    if initialized then
        return
    end
    initialized = true

    config = config or {}
    if config.logDir then logDir = config.logDir end
    if config.maxFileSize then maxFileSize = config.maxFileSize end
    if config.maxFiles then maxFiles = config.maxFiles end
    -- CET cannot create directories, so we don't call ensureDir.
    -- Logs are written to the mod's own directory (always exists).
    if log then log.info("FileOutput initialized") end
end

--- Set the session ID for this CET session
---@param id string Session ID (hex string)
function M.setSessionId(id)
    sessionId = id or ""
end

--- Get the current session ID
---@return string Session ID
function M.getSessionId()
    return sessionId
end

--- Set custom log file path for a mod
---@param modName string Mod identifier
---@param filePath string Relative or absolute file path
function M.setFilePath(modName, filePath)
    if type(modName) ~= "string" or modName == "" then return end
    if type(filePath) ~= "string" or filePath == "" then return end

    customPaths[modName] = filePath
    filePaths[modName] = filePath
    fileSizes[modName] = 0  -- Reset size tracking for new path
    headerWritten[modName] = false  -- Reset header for new path
end

--- Write a log entry to file
---@param modName string Mod identifier
---@param entry table Log entry table { timestamp, levelName, frame, modName, message }
---@param config table? Optional logger config for header writing
function M.write(modName, entry, config)
    if type(modName) ~= "string" or modName == "" then return end
    if type(entry) ~= "table" then return end

    local path = resolvePath(modName)

    -- Write header if not yet written
    if not headerWritten[modName] then
        writeHeader(modName, config)
    end

    -- Format the line
    local line = formatLine(entry)

    -- Write to file
    local ok, err = pcall(function()
        local f = io.open(path, "a")
        if f then
            f:write(line)
            f:close()

            -- Track approximate file size
            fileSizes[modName] = (fileSizes[modName] or 0) + #line

            -- Check if rotation needed
            if fileSizes[modName] >= maxFileSize then
                rotateFile(modName)
            end
        end
    end)

    if not ok then
        -- Silently fail on file write errors — don't recurse into logger
        if log then log.error("[FileOutput] File write error for " .. modName .. ": " .. tostring(err)) end
        if print then
            print("[LogEngine] File write error for " .. modName .. ": " .. tostring(err))
        end
    end
end

--- Write a dedup summary line to file
---@param modName Mod identifier
---@param count number Number of duplicates
---@param firstSeen string Timestamp of first occurrence
---@param message string Original message
function M.writeDedupSummary(modName, count, firstSeen, message)
    if type(modName) ~= "string" or modName == "" then return end

    local path = resolvePath(modName)

    -- Write header if not yet written
    if not headerWritten[modName] then
        writeHeader(modName, {})
    end

    local line = formatDedupSummary(modName, count, firstSeen, message)

    pcall(function()
        local f = io.open(path, "a")
        if f then
            f:write(line)
            f:close()
            fileSizes[modName] = (fileSizes[modName] or 0) + #line

            -- Check if rotation needed
            if fileSizes[modName] >= maxFileSize then
                rotateFile(modName)
            end
        end
    end)
end

--- Flush a specific mod's file (close and reopen to force disk write)
---@param modName string Mod identifier
function M.flush(modName)
    -- Our implementation writes and closes immediately,
    -- so flush is effectively a no-op. Kept for API compatibility.
end

--- Flush all file handles
---@return void
function M.flushAll()
    -- All handles are closed after each write, so this is a no-op.
    -- Kept for API compatibility and future buffered mode.
end

--- Close all file handles (for shutdown)
---@return void
function M.closeAll()
    fileHandles = {}
    fileSizes = {}
    headerWritten = {}
end

--- Get the resolved file path for a mod
---@param modName string Mod identifier
---@return string File path
function M.getFilePath(modName)
    return resolvePath(modName)
end

--- Check if file output is enabled (always true — we write by default)
---@return boolean
function M.isEnabled()
    return true
end

return M