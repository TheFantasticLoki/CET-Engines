--[[
    FileOutput — Log-Engine

    Handles all file I/O for Log-Engine.
    One file handle per mod, size-based rotation, CET-compatible.

    Rotation: mod.log -> mod.log.1 -> mod.log.2 -> ... -> mod.log.N (oldest deleted)
    Uses read-modify-write for rotation (NOT os.rename) for Windows CET compatibility.
]]

local M = {}

-- --- SafeRequire (inline, no external deps) ---
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then return mod end
    return nil
end

-- Config values inlined with fallbacks (CET require may not resolve siblings)
local Config = SafeRequire("config") or {}

-- --- Internal State ---

local initialized = false
local logDir = Config.LOG_DIR or "logs"
local maxFileSize = Config.MAX_FILE_SIZE or (2 * 1024 * 1024)
local maxFiles = Config.MAX_FILES or 5
local LOG_FILE_SUFFIX = Config.LOG_FILE_SUFFIX or ".log"
local fileHandles = {}   -- modName -> file handle (cached)
local filePaths = {}     -- modName -> resolved file path
local customPaths = {}   -- modName -> user-overridden path
local fileSizes = {}     -- modName -> current file size (approximate)

-- --- Helper Functions ---

--- Get the mod's own directory path (for relative path resolution)
-- In CET, io.open with relative paths resolves from the CET working directory.
-- We write to a "logs/" subdirectory relative to the working directory.
-- Note: debug.getinfo is NOT available in CET's sandboxed Lua.
-- @return string Base directory prefix (empty string = current directory)
local function getLogEngineDir()
    -- CET sandbox does not expose the `debug` library.
    -- Use a simple relative path instead.
    return ""
end

--- Ensure the log directory exists
-- @param dirPath Directory to create
local function ensureDir(dirPath)
    if dirPath == "" then return end
    pcall(function()
        -- Try creating directory via os.execute (works on most platforms)
        -- CET may not have os.execute; fall back gracefully
        if os.execute then
            -- mkdir -p pattern (cross-platform attempt)
            os.execute('mkdir -p "' .. dirPath .. '"')
        end
    end)
end

--- Resolve the file path for a mod
-- @param modName Mod identifier
-- @return string Resolved file path
local function resolvePath(modName)
    -- Check for custom path first
    if customPaths[modName] then
        return customPaths[modName]
    end

    -- Check cached path
    if filePaths[modName] then
        return filePaths[modName]
    end

    -- Default: Log-Engine/logs/<modName>.log
    local engineDir = getLogEngineDir()
    local path = engineDir .. logDir .. "/" .. modName .. LOG_FILE_SUFFIX
    filePaths[modName] = path
    return path
end

--- Get file size (approximate, by reading current position after append)
-- @param modName Mod identifier
-- @return number Size in bytes
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
-- @param modName Mod identifier
local function rotateFile(modName)
    local path = resolvePath(modName)

    -- Shift files: .N-1 -> .N (down to .1)
    for i = maxFiles - 1, 1, -1 do
        local src = path .. "." .. i
        local dst = path .. "." .. (i + 1)
        pcall(function()
            -- Read source, write to destination
            local sf = io.open(src, "r")
            if sf then
                local content = sf:read("*a")
                sf:close()
                local df = io.open(dst, "w")
                if df then
                    df:write(content)
                    df:close()
                end
            end
        end)
    end

    -- Current file becomes .1
    pcall(function()
        local cf = io.open(path, "r")
        if cf then
            local content = cf:read("*a")
            cf:close()
            local nf = io.open(path .. ".1", "w")
            if nf then
                nf:write(content)
                nf:close()
            end
            -- Truncate current file
            local tf = io.open(path, "w")
            if tf then
                tf:close()
            end
        end
    end)

    -- Reset tracked size
    fileSizes[modName] = 0
end

--- Format a log entry for file output
-- @param entry Log entry table
-- @return string Formatted line
local function formatLine(entry)
    return string.format("[%s] [%s] [%s] %s: %s\n",
        entry.timestamp or "",
        entry.levelName or "UNKNOWN",
        entry.frame or 0,
        entry.modName or "",
        entry.message or "")
end

-- --- Public API ---

--- Initialize file output module (idempotent)
-- @param config Optional configuration overrides
function M.init(config)
    if initialized then
        return
    end
    initialized = true

    config = config or {}
    if config.logDir then logDir = config.logDir end
    if config.maxFileSize then maxFileSize = config.maxFileSize end
    if config.maxFiles then maxFiles = config.maxFiles end

    -- Ensure log directory exists (best-effort, not critical)
    local engineDir = getLogEngineDir()
    local dirPath = engineDir .. logDir
    if dirPath ~= "" then
        ensureDir(dirPath)
    end
end

--- Set custom log file path for a mod
-- @param modName Mod identifier
-- @param filePath Relative or absolute file path
function M.setFilePath(modName, filePath)
    if type(modName) ~= "string" or modName == "" then return end
    if type(filePath) ~= "string" or filePath == "" then return end

    customPaths[modName] = filePath
    filePaths[modName] = filePath
    fileSizes[modName] = 0  -- Reset size tracking for new path
end

--- Write a log entry to file
-- @param modName Mod identifier
-- @param entry Log entry table { timestamp, levelName, frame, modName, message }
function M.write(modName, entry)
    if type(modName) ~= "string" or modName == "" then return end
    if type(entry) ~= "table" then return end

    local path = resolvePath(modName)

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
        -- Try to log the error to CET console as a last resort
        if print then
            print("[LogEngine] File write error for " .. modName .. ": " .. tostring(err))
        end
    end
end

--- Flush a specific mod's file (close and reopen to force disk write)
-- @param modName Mod identifier
function M.flush(modName)
    -- Our implementation writes and closes immediately,
    -- so flush is effectively a no-op. Kept for API compatibility.
end

--- Flush all file handles
function M.flushAll()
    -- All handles are closed after each write, so this is a no-op.
    -- Kept for API compatibility and future buffered mode.
end

--- Close all file handles (for shutdown)
function M.closeAll()
    fileHandles = {}
    fileSizes = {}
end

--- Get the resolved file path for a mod
-- @param modName Mod identifier
-- @return string File path
function M.getFilePath(modName)
    return resolvePath(modName)
end

--- Check if file output is enabled (always true — we write by default)
-- @return boolean
function M.isEnabled()
    return true
end

return M
