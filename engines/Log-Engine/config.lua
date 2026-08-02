--[[
    Config — Log-Engine

    Default configuration values for the Log-Engine logging system.
    All values can be overridden per-mod via CreateLogger(modName, config).
]]

local M = {}

-- Ring buffer
M.RING_SIZE = 1024  -- entries per mod logger

-- Log levels (numeric, for internal use)
M.LEVEL_DEBUG = 1
M.LEVEL_INFO = 2
M.LEVEL_WARN = 3
M.LEVEL_ERROR = 4

-- Level name lookup
M.LEVEL_NAMES = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
}

-- Default minimum level
M.DEFAULT_MIN_LEVEL = "debug"

-- File output
M.MAX_FILE_SIZE = 2 * 1024 * 1024  -- 2MB per file before rotation
M.MAX_FILES = 5                      -- number of rotated files to keep
M.LOG_DIR = "logs"                   -- subdirectory within Log-Engine for log files
M.LOG_FILE_SUFFIX = ".log"           -- file extension

-- Rate limiting
M.MAX_DEBUG_PER_FRAME = 1  -- max debug messages per frame per logger

return M
