--[[
    Config — Log-Engine

    Default configuration values for the Log-Engine logging system.
    All values can be overridden per-mod via CreateLogger(modName, config).
]]

---@alias LogLevel "debug" | "info" | "warn" | "error" | "print"

---@class LogConfig
---@field RING_SIZE number Ring buffer size per mod logger
---@field LEVEL_DEBUG number Numeric debug level
---@field LEVEL_INFO number Numeric info level
---@field LEVEL_WARN number Numeric warn level
---@field LEVEL_ERROR number Numeric error level
---@field LEVEL_PRINT number Numeric print level
---@field LEVEL_NAMES table<number, string> Level name lookup
---@field DEFAULT_MIN_LEVEL LogLevel Default minimum log level
---@field MAX_FILE_SIZE number Max file size in bytes before rotation
---@field MAX_FILES number Number of rotated files to keep
---@field LOG_DIR string Log file directory
---@field LOG_FILE_SUFFIX string Log file extension
---@field MAX_DEBUG_PER_FRAME number Max debug messages per frame per logger
---@field DEDUP_ENABLED boolean Enable deduplication
---@field DEDUP_MAX_ENTRIES number Max unique messages tracked before eviction
---@field SESSION_ID_LENGTH number Length of session ID hex string
local M = {}

-- Ring buffer
M.RING_SIZE = 1024  -- entries per mod logger

-- Log levels (numeric, for internal use)
M.LEVEL_DEBUG = 1
M.LEVEL_INFO = 2
M.LEVEL_WARN = 3
M.LEVEL_ERROR = 4
M.LEVEL_PRINT = 5

-- Level name lookup
---@type table<number, string>
M.LEVEL_NAMES = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
    [5] = "PRINT",
}

-- Default minimum level
M.DEFAULT_MIN_LEVEL = "debug"

-- File output
M.MAX_FILE_SIZE = 2 * 1024 * 1024  -- 2MB per file before rotation
M.MAX_FILES = 5                      -- number of rotated files to keep
M.LOG_DIR = ""                      -- write logs in mod's own directory (CET cannot create subdirs)
M.LOG_FILE_SUFFIX = ".log"           -- file extension

-- Rate limiting
M.MAX_DEBUG_PER_FRAME = 1  -- max debug messages per frame per logger

-- Deduplication
M.DEDUP_ENABLED = true       -- enable deduplication by default
M.DEDUP_MAX_ENTRIES = 256    -- max unique messages tracked before oldest is evicted

-- Session headers
M.SESSION_ID_LENGTH = 8      -- length of session ID hex string

return M