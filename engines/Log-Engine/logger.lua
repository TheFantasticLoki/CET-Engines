--[[
    Logger — Log-Engine

    Core logging engine. Each consumer mod gets its own logger instance
    with independent ring buffer, file output, and log level.

    API:
        local log = LogEngine.CreateLogger("MyMod")
        log.info("Mod loaded")
        log.error("Something went wrong")
        log.logf("warn", "Value is %d", 42)

    Log levels: debug, info, warn, error
    Ring buffer: configurable per instance (default 1024)
    File output: delegated to file_output.lua
    Rate limiting: max N debug messages per frame per logger
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
local FileOutput = SafeRequire("file_output")

-- --- Level Names (with fallback) ---
local LEVEL_NAMES = Config.LEVEL_NAMES or {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
}

-- --- Level Helpers ---

local LEVEL_DEBUG = Config.LEVEL_DEBUG or 1
local LEVEL_INFO = Config.LEVEL_INFO or 2
local LEVEL_WARN = Config.LEVEL_WARN or 3
local LEVEL_ERROR = Config.LEVEL_ERROR or 4

--- Get numeric level from string
-- @param levelStr Level name ("debug", "info", "warn", "error")
-- @return number Numeric level
local function getLevelNum(levelStr)
    if levelStr == "debug" then return LEVEL_DEBUG end
    if levelStr == "info" then return LEVEL_INFO end
    if levelStr == "warn" then return LEVEL_WARN end
    if levelStr == "error" then return LEVEL_ERROR end
    return LEVEL_DEBUG
end

--- Get timestamp string with millisecond approximation
-- @return string Timestamp in ISO format with .ms suffix
local function getTimestamp()
    local sec = os.date("%Y-%m-%dT%H:%M:%S")
    -- os.clock() gives CPU time as a sub-second approximation
    local ms = math.floor((os.clock() % 1) * 1000)
    return sec .. string.format(".%03d", ms)
end

-- --- Logger Instance Factory ---

--- Create a logger instance for a mod
-- @param modName string Unique mod identifier
-- @param config table Optional overrides { minLevel, ringSize, filePath, maxDebugPerFrame }
-- @param currentFrameRef table Reference to shared frame counter { value = N }
-- @return table Logger instance with public methods
function M.create(modName, config, currentFrameRef)
    if type(modName) ~= "string" or modName == "" then
        error("LogEngine.CreateLogger: modName must be a non-empty string")
    end

    config = config or {}
    local ringSize = config.ringSize or Config.RING_SIZE or 1024
    local minLevel = getLevelNum(config.minLevel or Config.DEFAULT_MIN_LEVEL or "debug")
    local maxDebugPerFrame = config.maxDebugPerFrame or Config.MAX_DEBUG_PER_FRAME or 5

    -- Ring buffer state
    local entries = {}
    local entryCount = 0
    local debugCountThisFrame = 0

    -- Set custom file path if provided
    if config.filePath and FileOutput then
        FileOutput.setFilePath(modName, config.filePath)
    end

    -- Logger instance
    local logger = {}
    logger.modName = modName

    -- --- Internal: add entry to ring buffer ---

    local function addEntry(message, level)
        local entry = {
            timestamp = getTimestamp(),
            frame = currentFrameRef and currentFrameRef.value or 0,
            modName = modName,
            message = message or "",
            level = level,
            levelName = LEVEL_NAMES[level] or "UNKNOWN",
        }

        -- Ring buffer: overwrite oldest when full
        entryCount = entryCount + 1
        local idx = ((entryCount - 1) % ringSize) + 1
        entries[idx] = entry

        -- Write to file
        if FileOutput then
            FileOutput.write(modName, entry)
        end

        return entry
    end

    -- --- Public API ---

    --- Log a message at a specific level
    -- @param level string Log level ("debug", "info", "warn", "error")
    -- @param message string Log message
    function logger.log(level, message)
        local levelNum = getLevelNum(level or "info")

        -- Check minimum level
        if levelNum < minLevel then
            return
        end

        -- Rate limiting for debug messages
        if levelNum == LEVEL_DEBUG then
            debugCountThisFrame = debugCountThisFrame + 1
            if debugCountThisFrame > maxDebugPerFrame then
                return
            end
        end

        addEntry(message, levelNum)
    end

    --- Log at debug level
    -- @param message string Log message
    function logger.debug(message)
        logger.log("debug", message)
    end

    --- Log at info level
    -- @param message string Log message
    function logger.info(message)
        logger.log("info", message)
    end

    --- Log at warn level
    -- @param message string Log message
    function logger.warn(message)
        logger.log("warn", message)
    end

    --- Log at error level
    -- @param message string Log message
    function logger.error(message)
        logger.log("error", message)
    end

    --- Log a formatted message (string.format)
    -- @param level string Log level
    -- @param fmt string Format string
    -- @param ... Format arguments
    function logger.logf(level, fmt, ...)
        local ok, msg = pcall(string.format, fmt, ...)
        if ok then
            logger.log(level, msg)
        else
            logger.log("error", "LogEngine logf format error: " .. tostring(msg))
        end
    end

    --- Change the minimum log level at runtime
    -- @param level string New minimum level
    function logger.setLevel(level)
        minLevel = getLevelNum(level or "debug")
    end

    --- Get the current minimum log level as a string
    -- @return string Current minimum level name
    function logger.getLevel()
        for levelNum, levelName in pairs(LEVEL_NAMES) do
            if levelNum == minLevel then return levelName:lower() end
        end
        return "debug"
    end

    --- Get the current minimum log level as a number
    -- @return number Current minimum level
    function logger.getLevelNum()
        return minLevel
    end

    --- Get entries from this logger's ring buffer
    -- @param count number Max entries to return (default: 100)
    -- @param filterLevel string Optional minimum level filter
    -- @return table Array of log entries
    function logger.getEntries(count, filterLevel)
        count = count or 100
        local filterNum = filterLevel and getLevelNum(filterLevel) or LEVEL_DEBUG

        local result = {}
        local maxStored = math.min(entryCount, ringSize)
        local startIdx = math.max(entryCount - maxStored + 1, entryCount - count + 1)
        startIdx = math.max(1, startIdx)

        for i = startIdx, entryCount do
            local idx = ((i - 1) % ringSize) + 1
            local entry = entries[idx]
            if entry and entry.level >= filterNum then
                table.insert(result, entry)
            end
        end

        return result
    end

    --- Get logging statistics for this mod
    -- @return table { totalLogged, byLevel = {debug=N, info=N, warn=N, error=N} }
    function logger.getStats()
        local stats = {
            totalLogged = entryCount,
            byLevel = { debug = 0, info = 0, warn = 0, error = 0 },
        }

        local maxStored = math.min(entryCount, ringSize)
        local startIdx = math.max(entryCount - maxStored + 1, 1)

        for i = startIdx, entryCount do
            local idx = ((i - 1) % ringSize) + 1
            local entry = entries[idx]
            if entry then
                local name = entry.levelName and entry.levelName:lower() or "debug"
                stats.byLevel[name] = (stats.byLevel[name] or 0) + 1
            end
        end

        return stats
    end

    --- Get recent error entries
    -- @param count number Max errors to return (default: 20)
    -- @return table Array of error entries
    function logger.getRecentErrors(count)
        count = count or 20
        local errors = {}

        local maxStored = math.min(entryCount, ringSize)
        local startIdx = math.max(entryCount - maxStored + 1, 1)

        -- Scan from newest to oldest
        for i = entryCount, startIdx, -1 do
            local idx = ((i - 1) % ringSize) + 1
            local entry = entries[idx]
            if entry and entry.level >= LEVEL_ERROR then
                table.insert(errors, entry)
                if #errors >= count then
                    break
                end
            end
        end

        return errors
    end

    --- Set a custom file path for this mod's logs
    -- @param path string Relative or absolute file path
    function logger.setFilePath(path)
        FileOutput.setFilePath(modName, path)
    end

    --- Flush this mod's log file to disk
    function logger.flush()
        FileOutput.flush(modName)
    end

    --- Clear this logger's ring buffer
    function logger.clear()
        entries = {}
        entryCount = 0
        debugCountThisFrame = 0
    end

    --- Reset the debug rate limiter (called each frame)
    function logger.resetFrameCounter()
        debugCountThisFrame = 0
    end

    --- Get the total number of entries logged (including overwritten)
    -- @return number Total entries ever logged
    function logger.getTotalLogged()
        return entryCount
    end

    --- Get the ring buffer capacity
    -- @return number Ring buffer size
    function logger.getCapacity()
        return ringSize
    end

    return logger
end

return M
