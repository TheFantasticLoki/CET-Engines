--[[
    Init — Log-Engine Entry Point

    Entry point for the Log-Engine CET mod. Provides robust file-based
    logging to all other mods in the workspace.

    Consumer mods access Log-Engine via GetMod("0-Engine-Log"):
        local LogEngine = GetMod("0-Engine-Log")
        local log = LogEngine.CreateLogger("MyMod")
        log.info("Mod loaded")
        log.print("Console output")  -- prints to CET console AND logs to file

    Module loading order:
    1. config.lua        (defaults — no dependencies)
    2. file_output.lua   (file I/O — depends on config)
    3. logger.lua        (core engine — depends on config, file_output)
    4. stats.lua         (statistics — depends on logger instances)

    Public API returned by this module.
]]

-- --- SafeRequire Pattern ---

--- Safely require a module with pcall
-- @param path Module path
-- @return table|nil Module table or nil if not found
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then
        return mod
    end
    local err = tostring(mod)
    if not err:find("not found") and not err:find("no field") then
        print("[LogEngine] FAILED to load '" .. path .. "': " .. err)
    end
    return nil
end

-- --- Module Loading ---

local Config = SafeRequire("config")
local FileOutput = SafeRequire("file_output")
local LoggerModule = SafeRequire("logger")
local Stats = SafeRequire("stats")

-- --- Internal State ---

local initialized = false
local frameCount = 0
local currentFrameRef = { value = 0 }  -- Shared reference for logger instances

-- Logger instances (modName -> logger)
local loggers = {}

-- Session ID (generated at init, persists across file rotations)
local sessionId = ""

--- Generate a short hex session ID
-- @param length number Length of hex string (default: 8)
-- @return string Hex session ID
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
-- @param modName string Unique mod identifier
-- @param config table Optional { minLevel, ringSize, filePath, maxDebugPerFrame, dedupEnabled }
-- @return table Logger instance
local function CreateLogger(modName, config)
    if not LoggerModule then
        print("[LogEngine] Logger module not loaded, cannot create logger for: " .. tostring(modName))
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
-- @param modName string Mod identifier
-- @return table|nil Logger instance or nil
local function GetLogger(modName)
    return loggers[modName] or nil
end

--- Get all registered logger mod names
-- @return table Array of mod name strings
local function GetLoggerNames()
    local names = {}
    for name, _ in pairs(loggers) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

--- Get aggregate statistics across all loggers
-- @return table Aggregate stats
local function GetStats()
    if Stats then
        return Stats.getAggregateStats()
    end
    return { totalMods = 0, totalLogged = 0, byLevel = {} }
end

--- Get recent errors across all mods
-- @param count number Max errors (default: 20)
-- @return table Array of error entries
local function GetRecentErrors(count)
    if Stats then
        return Stats.getRecentErrors(count)
    end
    return {}
end

--- Get mod summary for display
-- @return table Array of { modName, totalLogged, errorCount, lastLog }
local function GetModSummary()
    if Stats then
        return Stats.getModSummary()
    end
    return {}
end

--- Get Log-Engine version
-- @return string Version string
local function GetVersion()
    return "v1.1.0"
end

--- Set global minimum level for all loggers
-- @param level string Minimum level ("debug", "info", "warn", "error")
local function SetGlobalLevel(level)
    for _, logger in pairs(loggers) do
        if logger.setLevel then
            logger.setLevel(level)
        end
    end
end

--- Flush all log files to disk
local function FlushAll()
    if FileOutput then
        FileOutput.flushAll()
    end
end

--- Flush all pending dedup summaries
local function FlushAllDedup()
    for _, logger in pairs(loggers) do
        if logger.flushDedup then
            logger.flushDedup()
        end
    end
end

--- Get the current session ID
-- @return string Session ID
local function GetSessionId()
    return sessionId
end

-- --- CET Callbacks ---

--- onInit handler — called when CET loads the mod
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

    -- Log-Engine's own logger
    CreateLogger("LogEngine", { minLevel = "info" })

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

--- onShutdown handler — called when CET unloads the mod
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

-- CET callbacks (exposed for CET to call)
M.onInit = onInit
M.onDraw = onDraw
M.onShutdown = onShutdown

-- Direct access to modules (for advanced use)
M.Config = Config
M.FileOutput = FileOutput
M.LoggerModule = LoggerModule
M.Stats = Stats

return M