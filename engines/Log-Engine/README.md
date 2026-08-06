# Log-Engine

**Version:** v1.1.0  
**Author:** 0-Loki  
**CET Mod Name:** `0-Engine-Log`

## Overview

Log-Engine is a robust file-based logging system for CET mods. It provides per-mod loggers with ring buffers, file output with rotation, deduplication, and rate limiting.

## Public API

```lua
local LogEngine = GetMod("0-Engine-Log")

-- Create a logger (idempotent)
local log = LogEngine.CreateLogger("MyMod", {
    minLevel = "debug",      -- Minimum log level
    ringSize = 1024,         -- Ring buffer entries
    maxDebugPerFrame = 1,    -- Rate limit debug messages
    dedupEnabled = true,     -- Deduplicate messages
})

-- Logging
log.debug("Debug message")
log.info("Info message")
log.warn("Warning message")
log.error("Error message")
log.print("Console + file output")

-- Management
LogEngine.GetLoggerNames()     -- List all loggers
LogEngine.GetStats()           -- Aggregate statistics
LogEngine.GetRecentErrors(20)  -- Recent errors
LogEngine.GetModSummary()      -- Per-mod summary
LogEngine.SetGlobalLevel("warn")  -- Set min level for all
LogEngine.FlushAll()           -- Flush all files
LogEngine.GetVersion()         -- "v1.1.0"
```

## Log Levels

| Level | Name | Description |
|-------|------|-------------|
| 1 | DEBUG | Detailed diagnostic info |
| 2 | INFO | General information |
| 3 | WARN | Warnings |
| 4 | ERROR | Errors |
| 5 | PRINT | Console + file output |

## Configuration

Log-Engine is configurable via Config-Engine. Settings include:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `globalMinLevel` | combo | "debug" | Min level for all loggers |
| `ringSize` | int_slider | 1024 | Ring buffer entries per logger |
| `maxFileSize` | combo | 2MB | Max file size before rotation |
| `maxFiles` | int_slider | 5 | Rotated files to keep |
| `maxDebugPerFrame` | int_slider | 1 | Debug messages/frame/logger |
| `dedupEnabled` | toggle | true | Enable deduplication |
| `dedupMaxEntries` | int_slider | 256 | Max dedup entries |

## File Output

- Logs are written to `engines/Log-Engine/logs/` directory
- Each mod gets its own log file
- Files rotate when they exceed `maxFileSize`
- Up to `maxFiles` rotated files are kept per mod

## Deduplication

When enabled, repeated identical log messages within a session are:
1. First occurrence: logged normally
2. Subsequent occurrences: suppressed
3. Session end: summary of suppressed counts is flushed

## Rate Limiting

Debug messages are rate-limited per logger per frame to prevent log flooding:
- Default: 1 debug message per frame per logger
- Configurable via `maxDebugPerFrame`

## Integration with Config-Engine

Log-Engine automatically registers with Config-Engine if available. This enables:
- Global log level adjustment
- Ring buffer size configuration
- File rotation settings
- Deduplication toggle

## File Structure

```
engines/Log-Engine/
├── init.lua              # Entry point, public API
├── config.lua            # Default configuration values
├── file_output.lua       # File I/O and rotation
├── logger.lua            # Core logger with ring buffer
├── stats.lua             # Statistics tracking
└── README.md             # This file
```
