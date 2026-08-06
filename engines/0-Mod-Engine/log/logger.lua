--[[
    Logger — Log-Engine

    Core logging engine. Each consumer mod gets its own logger instance
    with independent ring buffer, file output, and log level.

    API:
        local log = LogEngine.CreateLogger("MyMod")
        log.info("Mod loaded")
        log.error("Something went wrong")
        log.logf("warn", "Value is %d", 42)
        log.print("Console output")  -- prints to CET console AND logs to file

    Log levels: debug, info, warn, error, print
    Ring buffer: configurable per instance (default 1024)
    File output: delegated to file_output.lua
    Rate limiting: max N debug messages per frame per logger
    Deduplication: suppresses duplicate messages, writes summary
]]

---@class LogEntry
---@field timestamp string Timestamp in HH:MM:SS.mmm format
---@field frame number Frame counter when logged
---@field modName string Source mod identifier
---@field message string Log message
---@field level number Numeric log level
---@field levelName string Level name string

---@class LoggerInstance
---@field modName string Unique mod identifier
---@field log fun(level: string, message: string) Log a message at a specific level
---@field debug fun(message: string) Log at debug level
---@field trace fun(message: string) Log at trace level (alias for debug)
---@field info fun(message: string) Log at info level
---@field warn fun(message: string) Log at warn level
---@field error fun(message: string) Log at error level
---@field print fun(message: string) Log at print level
---@field logf fun(level: string, fmt: string, ...) Log a formatted message
---@field setLevel fun(level: string) Change minimum log level at runtime
---@field getLevel fun(): string Get current minimum level name
---@field getLevelNum fun(): number Get current minimum level number
---@field getEntries fun(count?: number, filterLevel?: string): LogEntry[] Get entries from ring buffer
---@field getStats fun(): table Get logging statistics
---@field getRecentErrors fun(count?: number): LogEntry[] Get recent error entries
---@field setFilePath fun(path: string) Set custom file path
---@field flush fun() Flush log file to disk
---@field clear fun() Clear ring buffer
---@field resetFrameCounter fun() Reset debug rate limiter
---@field getTotalLogged fun(): number Get total entries ever logged
---@field getCapacity fun(): number Get ring buffer capacity
---@field getDedupStats fun(): table Get deduplication statistics
---@field flushDedup fun() Flush all pending dedup summaries
local M = {}

-- --- SafeRequire (inline, no external deps) ---
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then return mod end
    return nil
end

-- Config values inlined with fallbacks (CET require may not resolve siblings)
local Config = SafeRequire("log/config") or {}
local FileOutput = SafeRequire("log/file_output")
print("[Logger] logger.lua loaded: Config=" .. tostring(Config ~= nil) .. " FileOutput=" .. tostring(FileOutput ~= nil))

-- --- Level Names (with fallback) ---
local LEVEL_NAMES = Config.LEVEL_NAMES or {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
    [5] = "PRINT",
}

-- --- Level Helpers ---

---@type number Numeric debug level constant
local LEVEL_DEBUG = Config.LEVEL_DEBUG or 1
---@type number Numeric info level constant
local LEVEL_INFO = Config.LEVEL_INFO or 2
---@type number Numeric warn level constant
local LEVEL_WARN = Config.LEVEL_WARN or 3
---@type number Numeric error level constant
local LEVEL_ERROR = Config.LEVEL_ERROR or 4
---@type number Numeric print level constant
local LEVEL_PRINT = Config.LEVEL_PRINT or 5

-- Module-level logger for internal diagnostics
---@type Logger?
local log = nil

--- Set the module-level logger (called by init.lua after first logger is created)
---@param logger Logger? Logger instance or nil to disable
function M.setLogger(logger)
    log = logger
end

--- Get numeric level from string
---@param levelStr Level name ("debug", "info", "warn", "error", "print")
---@return number Numeric level
local function getLevelNum(levelStr)
    if levelStr == "debug" then return LEVEL_DEBUG end
    if levelStr == "info" then return LEVEL_INFO end
    if levelStr == "warn" then return LEVEL_WARN end
    if levelStr == "error" then return LEVEL_ERROR end
    if levelStr == "print" then return LEVEL_PRINT end
    return LEVEL_DEBUG
end

--- Get timestamp string (time-only, since date is in session header)
---@return string Timestamp in HH:MM:SS.mmm format
local function getTimestamp()
    local sec = os.date("%H:%M:%S")
    -- os.clock() gives CPU time as a sub-second approximation
    local ms = math.floor((os.clock() % 1) * 1000)
    return sec .. string.format(".%03d", ms)
end

-- --- Logger Instance Factory ---

--- Create a logger instance for a mod
---@param modName string Unique mod identifier
---@param config table Optional overrides { minLevel, ringSize, filePath, maxDebugPerFrame, dedupEnabled }
---@param currentFrameRef table Reference to shared frame counter { value = N }
---@return table Logger instance with public methods
function M.create(modName, config, currentFrameRef)
    if type(modName) ~= "string" or modName == "" then
        error("LogEngine.CreateLogger: modName must be a non-empty string")
    end

    config = config or {}
    local ringSize = config.ringSize or Config.RING_SIZE or 1024
    local minLevel = getLevelNum(config.minLevel or Config.DEFAULT_MIN_LEVEL or "debug")
    local maxDebugPerFrame = config.maxDebugPerFrame or Config.MAX_DEBUG_PER_FRAME or 5
    local dedupEnabled = config.dedupEnabled
    if dedupEnabled == nil then
        dedupEnabled = Config.DEDUP_ENABLED ~= false
    end
    local dedupMaxEntries = config.dedupMaxEntries or Config.DEDUP_MAX_ENTRIES or 256

    -- Ring buffer state
    local entries = {}
    local entryCount = 0
    local debugCountThisFrame = 0

    -- Deduplication state
    local dedupTable = {}  -- [level..":"..message] = { count, firstSeen, lastSeen, firstEntry }
    local dedupOrder = {}  -- ordered list of dedup keys for eviction

    -- Set custom file path if provided
    if config.filePath and FileOutput then
        FileOutput.setFilePath(modName, config.filePath)
    end

    -- Logger instance
    local logger = {}
    logger.modName = modName
    if log then log.debug("Logger created for mod: " .. modName) end

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

        -- Write to file (with fallback to print on failure)
        if FileOutput then
            local ok, err = pcall(FileOutput.write, modName, entry, config)
            if not ok then
                -- File write failed — always print to CET console as fallback
                print("[" .. modName .. "] [" .. entry.levelName .. "] " .. entry.message)
            end
        else
            -- No FileOutput — always print to CET console
            print("[" .. modName .. "] [" .. entry.levelName .. "] " .. entry.message)
        end

        return entry
    end

    --- Flush pending dedup summaries for a specific key
    ---@param key string Dedup key
    local function flushDedup(key)
        local info = dedupTable[key]
        if info and info.count > 1 then
            if FileOutput then
                FileOutput.writeDedupSummary(modName, info.count, info.firstSeen, info.message)
            end
        end
        dedupTable[key] = nil
    end

    --- Flush all pending dedup summaries
    local function flushAllDedup()
        for key, info in pairs(dedupTable) do
            if info.count > 1 then
                if FileOutput then
                    FileOutput.writeDedupSummary(modName, info.count, info.firstSeen, info.message)
                end
            end
        end
        dedupTable = {}
        dedupOrder = {}
    end

    --- Evict oldest dedup entry if at max capacity
    local function evictOldestDedup()
        if #dedupOrder > dedupMaxEntries then
            local oldestKey = table.remove(dedupOrder, 1)
            local info = dedupTable[oldestKey]
            if info and info.count > 1 then
                -- Flush the evicted entry's summary before dropping it
                pcall(FileOutput.writeDedupSummary, modName, info.count, info.firstSeen, info.message)
            end
            dedupTable[oldestKey] = nil
        end
    end

    -- --- Public API ---

    --- Log a message at a specific level
    ---@param level string Log level ("debug", "info", "warn", "error", "print")
    ---@param message string Log message
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

        -- Deduplication
        if dedupEnabled then
            local dedupKey = levelNum .. ":" .. (message or "")
            local existing = dedupTable[dedupKey]

            if existing then
                -- Duplicate found: increment count, don't write
                existing.count = existing.count + 1
                existing.lastSeen = getTimestamp()
                return
            else
                -- New message: track it (don't flush the whole table — that destroys dedup for concurrent messages)
                dedupTable[dedupKey] = {
                    count = 1,
                    firstSeen = getTimestamp(),
                    lastSeen = getTimestamp(),
                    message = message or "",
                }
                table.insert(dedupOrder, dedupKey)
                evictOldestDedup()
            end
        end

        addEntry(message, levelNum)
    end

    --- Log at debug level
    ---@param message string Log message
    function logger.debug(message)
        logger.log("debug", message)
    end

    --- Log at trace level (alias for debug — hot path entry/exit)
    ---@param message string Log message
    function logger.trace(message)
        logger.log("debug", message)
    end

    --- Log at info level
    ---@param message string Log message
    function logger.info(message)
        logger.log("info", message)
    end

    --- Log at warn level
    ---@param message string Log message
    function logger.warn(message)
        logger.log("warn", message)
    end

    --- Log at error level
    ---@param message string Log message
    function logger.error(message)
        logger.log("error", message)
    end

    --- Log at print level (console + file)
    ---@param message string Log message
    function logger.print(message)
        logger.log("print", message)
    end

    --- Log a formatted message (string.format)
    ---@param level string Log level
    ---@param fmt string Format string
    ---@param ... Format arguments
    function logger.logf(level, fmt, ...)
        local ok, msg = pcall(string.format, fmt, ...)
        if ok then
            logger.log(level, msg)
        else
            logger.log("error", "LogEngine logf format error: " .. tostring(msg))
        end
    end

    --- Change the minimum log level at runtime
    ---@param level string New minimum level
    function logger.setLevel(level)
        minLevel = getLevelNum(level or "debug")
    end

    --- Get the current minimum log level as a string
    ---@return string Current minimum level name
    function logger.getLevel()
        for levelNum, levelName in pairs(LEVEL_NAMES) do
            if levelNum == minLevel then return levelName:lower() end
        end
        return "debug"
    end

    --- Get the current minimum log level as a number
    ---@return number Current minimum level
    function logger.getLevelNum()
        return minLevel
    end

    --- Get entries from this logger's ring buffer
    ---@param count number Max entries to return (default: 100)
    ---@param filterLevel string Optional minimum level filter
    ---@return table Array of log entries
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
    ---@return table { totalLogged, byLevel = {debug=N, info=N, warn=N, error=N, print=N} }
    function logger.getStats()
        local stats = {
            totalLogged = entryCount,
            byLevel = { debug = 0, info = 0, warn = 0, error = 0, print = 0 },
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
    ---@param count number Max errors to return (default: 20)
    ---@return table Array of error entries
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
    ---@param path string Relative or absolute file path
    function logger.setFilePath(path)
        FileOutput.setFilePath(modName, path)
    end

    --- Flush this mod's log file to disk
    ---@return void
    function logger.flush()
        FileOutput.flush(modName)
    end

    --- Clear this logger's ring buffer
    ---@return void
    function logger.clear()
        entries = {}
        entryCount = 0
        debugCountThisFrame = 0
        dedupTable = {}
        dedupOrder = {}
    end

    --- Reset the debug rate limiter (called each frame)
    ---@return void
    function logger.resetFrameCounter()
        debugCountThisFrame = 0
    end

    --- Get the total number of entries logged (including overwritten)
    ---@return number Total entries ever logged
    function logger.getTotalLogged()
        return entryCount
    end

    --- Get the ring buffer capacity
    ---@return number Ring buffer size
    function logger.getCapacity()
        return ringSize
    end

    --- Get dedup statistics
    ---@return table { totalDeduped, pendingSummaries }
    function logger.getDedupStats()
        local pending = 0
        for _, info in pairs(dedupTable) do
            if info.count > 1 then
                pending = pending + 1
            end
        end
        return {
            totalDeduped = entryCount,
            pendingSummaries = pending,
        }
    end

    --- Flush all pending dedup summaries to file
    ---@return void
    function logger.flushDedup()
        flushAllDedup()
    end

    return logger
end

return M