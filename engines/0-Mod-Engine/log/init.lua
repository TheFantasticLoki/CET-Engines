--[[
    Log-Engine -- Unified Mod Version

    Simplified entry point for Log-Engine within the unified 0-Mod-Engine.
    CET callbacks are handled by the main init.lua, not here.

    Module loading order:
    1. config.lua        (defaults -- no dependencies)
    2. file_output.lua   (file I/O -- depends on config)
    3. logger.lua        (core engine -- depends on config, file_output)
    4. stats.lua         (statistics -- depends on logger instances)

    Public API returned by this module.
]]

---@class LogEngine
---@version 1.1.0
---@license MIT
--- Unified entry point for Log-Engine logging system.
--- Manages logger instances, statistics, and file output.

-- PROVE THIS FILE IS BEING EXECUTED (first line of executable code)
print("[LogEngine] log/init.lua executing (file version check)")

-- --- SafeRequire Pattern ---

--- Safely require a module with pcall
---@param path Module path
---@return table|nil Module table or nil if not found
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then
        return mod
    end
    print("[LogEngine] FAILED to load '" .. path .. "': " .. tostring(mod))
    return nil
end

-- --- Module Loading ---

local Config = SafeRequire("log/config")
local FileOutput = SafeRequire("log/file_output")
local LoggerModule = SafeRequire("log/logger")
local Stats = SafeRequire("log/stats")
print("[LogEngine] Sub-modules: Config=" .. tostring(Config ~= nil) .. " FileOutput=" .. tostring(FileOutput ~= nil) .. " LoggerModule=" .. tostring(LoggerModule ~= nil) .. " Stats=" .. tostring(Stats ~= nil))

-- --- Internal State ---

---@type boolean Whether Log-Engine has been initialized
local initialized = false
local frameCount = 0
local currentFrameRef = { value = 0 }  -- Shared reference for logger instances

-- Logger instances (modName -> logger)
---@type table<string, LoggerInstance>
local loggers = {}

-- Log-Engine's own logger (created during onInit)
---@type Logger?
local log = nil

-- Session ID (generated at init, persists across file rotations)
local sessionId = ""

--- Generate a short hex session ID
---@param length number Length of hex string (default: 8)
---@return string Hex session ID
local function generateSessionId(length)
    length = length or (Config and Config.SESSION_ID_LENGTH) or 8
    local id = ""
    for i = 1, length do
        id = id .. string.format("%x", math.random(0, 15))
    end
    return id
end

-- --- Public API ---

--- Create a logger instance for a consumer mod
---@param modName string Unique mod identifier
---@param config table? Optional { minLevel, ringSize, filePath, maxDebugPerFrame, dedupEnabled }
---@return LoggerInstance? logger Logger instance or nil on failure
local function CreateLogger(modName, config)
    if not LoggerModule then
        print("[LogEngine] CreateLogger: LoggerModule is nil - cannot create logger for '" .. tostring(modName) .. "'")
        return nil
    end

    if type(modName) ~= "string" or modName == "" then
        print("[LogEngine] CreateLogger: modName must be a non-empty string")
        return nil
    end

    -- Idempotent: return existing logger if already created
    if loggers[modName] then
        return loggers[modName]
    end

    local logger = LoggerModule.create(modName, config, currentFrameRef)
    loggers[modName] = logger

    -- Log the registration
    logger.info("Logger created for mod: " .. modName)

    return logger
end

--- Get an existing logger for a mod
---@param modName string Mod identifier
---@return LoggerInstance? logger Logger instance or nil
local function GetLogger(modName)
    return loggers[modName] or nil
end

--- Get all registered logger mod names
---@return string[] Array of mod name strings
local function GetLoggerNames()
    local names = {}
    for name, _ in pairs(loggers) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--- Get aggregate statistics across all loggers
---@return table Aggregate stats { totalMods, totalLogged, byLevel }
local function GetStats()
    if Stats then
        return Stats.getAggregateStats()
    end
    return { totalMods = 0, totalLogged = 0, byLevel = {} }
end

--- Get recent errors across all mods
---@param count number? Max errors (default: 20)
---@return table Array of error entries
local function GetRecentErrors(count)
    if Stats then
        return Stats.getRecentErrors(count)
    end
    return {}
end

--- Get mod summary for display
---@return table Array of { modName, totalLogged, errorCount, lastLog }
local function GetModSummary()
    if Stats then
        return Stats.getModSummary()
    end
    return {}
end

--- Get Log-Engine version
---@return string Version string
local function GetVersion()
    return "v1.1.0"
end

--- Set global minimum level for all loggers
---@param level string Minimum level ("debug", "info", "warn", "error")
local function SetGlobalLevel(level)
    for _, logger in pairs(loggers) do
        if logger.setLevel then
            logger.setLevel(level)
        end
    end
end

--- Flush all log files to disk
---@return void
local function FlushAll()
    if FileOutput then
        FileOutput.flushAll()
    end
end

--- Flush all pending dedup summaries
---@return void
local function FlushAllDedup()
    for _, logger in pairs(loggers) do
        if logger.flushDedup then
            logger.flushDedup()
        end
    end
end

--- Get the current session ID
---@return string Session ID
local function GetSessionId()
    return sessionId
end

-- --- CET Callbacks (called from main init.lua) ---

--- onInit handler
local function onInit()
    if initialized then
        return  -- Idempotent
    end
    initialized = true

    -- Generate session ID
    sessionId = generateSessionId()

    -- Initialize modules in order
    if FileOutput then
        FileOutput.init()
        FileOutput.setSessionId(sessionId)
    end

    if Stats then
        Stats.init(loggers)
    end

    -- Create Log-Engine's own logger and wire up the module-level loggers
    log = CreateLogger("LogEngine", { minLevel = "info" })
    if FileOutput and FileOutput.setLogger then FileOutput.setLogger(log) end
    if Stats and Stats.setLogger then Stats.setLogger(log) end
    if LoggerModule and LoggerModule.setLogger then LoggerModule.setLogger(log) end

    if log then log.info("Log-Engine initialized (session: " .. sessionId .. ")") end

    -- Startup summary
    print("[LogEngine] " .. GetVersion() .. " loaded (session: " .. sessionId .. ")")
    local modules = {
        Config = Config,
        FileOutput = FileOutput,
        Logger = LoggerModule,
        Stats = Stats,
    }
    for name, mod in pairs(modules) do
        print("[LogEngine]   " .. name .. ": " .. (mod and "OK" or "MISSING"))
    end
end

--- onDraw handler — called each frame
local function onDraw()
    frameCount = frameCount + 1
    currentFrameRef.value = frameCount

    -- Reset debug rate limiters for all loggers
    for _, logger in pairs(loggers) do
        if logger.resetFrameCounter then
            logger.resetFrameCounter()
        end
    end
end

--- onShutdown handler
local function onShutdown()
    -- Flush all pending dedup summaries
    FlushAllDedup()

    -- Flush all files
    FlushAll()

    -- Log shutdown for each mod
    for modName, logger in pairs(loggers) do
        if modName ~= "LogEngine" then
            pcall(function()
                logger.info("Log-Engine shutting down")
            end)
        end
    end

    -- Log-Engine's own shutdown
    local ownLogger = loggers["LogEngine"]
    if ownLogger then
        ownLogger.info("Log-Engine shutdown complete")
    end

    -- Final flush
    FlushAll()
end

-- --- Module Return ---

local M = {}

-- Public API
M.CreateLogger = CreateLogger
M.GetLogger = GetLogger
M.GetLoggerNames = GetLoggerNames
M.GetStats = GetStats
M.GetRecentErrors = GetRecentErrors
M.GetModSummary = GetModSummary
M.GetVersion = GetVersion
M.SetGlobalLevel = SetGlobalLevel
M.FlushAll = FlushAll
M.FlushAllDedup = FlushAllDedup
M.GetSessionId = GetSessionId

-- Configuration Setters (for live settings updates)
function M.setLogDir(dir)
    if FileOutput and FileOutput.setLogDir then
        FileOutput.setLogDir(dir)
    end
    if Config then Config.LOG_DIR = dir end
end

function M.setMaxFileSize(size)
    if FileOutput and FileOutput.setMaxFileSize then
        FileOutput.setMaxFileSize(size)
    end
    if Config then Config.MAX_FILE_SIZE = size end
end

function M.setMaxFiles(count)
    if FileOutput and FileOutput.setMaxFiles then
        FileOutput.setMaxFiles(count)
    end
    if Config then Config.MAX_FILES = count end
end

function M.setMaxDebugPerFrame(count)
    if Config then Config.MAX_DEBUG_PER_FRAME = count end
    for _, logger in pairs(loggers) do
        if logger.setMaxDebugPerFrame then
            logger.setMaxDebugPerFrame(count)
        end
    end
end

function M.setDedupEnabled(enabled)
    if Config then Config.DEDUP_ENABLED = enabled end
    for _, logger in pairs(loggers) do
        if logger.setDedupEnabled then
            logger.setDedupEnabled(enabled)
        end
    end
end

function M.setDedupMaxEntries(max)
    if Config then Config.DEDUP_MAX_ENTRIES = max end
    for _, logger in pairs(loggers) do
        if logger.setDedupMaxEntries then
            logger.setDedupMaxEntries(max)
        end
    end
end

function M.setRingSize(size)
    if Config then Config.RING_SIZE = size end
end

-- CET callbacks (called from main init.lua)
M.onInit = onInit
M.onDraw = onDraw
M.onShutdown = onShutdown

-- Direct access to modules (for advanced use)
M.Config = Config
M.FileOutput = FileOutput
M.LoggerModule = LoggerModule
M.Stats = Stats

return M
