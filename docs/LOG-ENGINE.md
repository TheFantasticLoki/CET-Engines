# Log-Engine — API Reference

## Overview

Log-Engine is a **standalone CET mod** that provides robust, file-based logging to all other mods in the workspace. It is independent of UI-Engine — it can be deployed and used without UI-Engine installed.

Consumer mods access Log-Engine via `GetMod("0-Engine-Log")` and receive per-mod logger instances with independent ring buffers, file output, log levels, and rate limiting.

### Why Log-Engine Exists

The UI-Engine Logger (`modules/logger.lua`) is tightly coupled — when UIEngine fails to load, all logging is lost. Log-Engine is the first thing loaded and the last thing unloaded, providing a safety net for debugging all other mods.

### Architecture

```
┌─────────────────────────────────────────────┐
│  Consumer Mod (e.g., UI-Engine-DevKit)      │
│  local log = LogEngine.CreateLogger("Mod")  │
│  log.info("message")                        │
└──────────────────┬──────────────────────────┘
                   │ GetMod("0-Engine-Log")
┌──────────────────▼──────────────────────────┐
│  Log-Engine (0-Engine-Log/)                 │
│  ┌──────────┐ ┌────────────┐ ┌───────────┐ │
│  │ init.lua │ │ logger.lua │ │ stats.lua │ │
│  │ (entry)  │ │ (engine)   │ │ (agg)     │ │
│  └──────────┘ └─────┬──────┘ └───────────┘ │
│                ┌────▼──────┐                │
│                │file_output│                │
│                │  (.lua)   │                │
│                └─────┬─────┘                │
│                      │                      │
│              logs/ModName.log               │
│              logs/ModName.log.1             │
│              logs/ModName.log.2             │
└─────────────────────────────────────────────┘
```

---

## Quick Start

```lua
-- In your mod's init.lua:
local LogEngine = GetMod("0-Engine-Log")
local log = nil

if LogEngine then
    log = LogEngine.CreateLogger("MyMod", { minLevel = "debug" })
end

-- In onInit:
if log then log.info("MyMod loaded") end

-- In onDraw:
if log then log.debug("frame " .. frameCount) end

-- In onShutdown:
if log then log.info("MyMod shutting down") end
```

**Log file appears at:** `0-Engine-Log/logs/MyMod.log`

---

## Module Loading

Log-Engine loads 4 internal modules in order:

| Order | Module | File | Purpose |
|-------|--------|------|---------|
| 1 | Config | `config.lua` | Default values (no dependencies) |
| 2 | FileOutput | `file_output.lua` | File I/O and rotation (depends on Config) |
| 3 | LoggerModule | `logger.lua` | Core engine (depends on Config, FileOutput) |
| 4 | Stats | `stats.lua` | Aggregate statistics (depends on logger instances) |

All modules use **SafeRequire with inline fallbacks** — if a sibling `require` fails in CET's sandboxed Lua, the module still loads with default values. No module depends on another at load time.

---

## Public API — `GetMod("0-Engine-Log")`

### `LogEngine.CreateLogger(modName, config)`

Create (or retrieve) a logger instance for a mod. **Idempotent** — calling twice with the same `modName` returns the existing logger.

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `modName` | string | yes | Unique mod identifier (e.g., `"MyMod"`) |
| `config` | table | no | Configuration overrides |

**`config` fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `minLevel` | string | `"debug"` | Minimum log level (`"debug"`, `"info"`, `"warn"`, `"error"`) |
| `ringSize` | number | `1024` | Ring buffer entries per mod |
| `filePath` | string | `nil` | Custom log file path (relative or absolute) |
| `maxDebugPerFrame` | number | `1` | Max debug messages per frame (rate limiting) |

**Returns:** Logger instance (table) or `nil` if Log-Engine is not available.

```lua
local LogEngine = GetMod("0-Engine-Log")
local log = LogEngine.CreateLogger("MyMod", {
    minLevel = "info",
    ringSize = 512,
})
```

---

### `LogEngine.GetLogger(modName)`

Get an existing logger for a mod (does not create one).

**Returns:** Logger instance or `nil`.

```lua
local log = LogEngine.GetLogger("MyMod")
if log then log.info("already initialized") end
```

---

### `LogEngine.GetLoggerNames()`

Get all registered logger mod names.

**Returns:** Sorted array of mod name strings.

```lua
local names = LogEngine.GetLoggerNames()
-- {"LogEngine", "MyMod", "UI-Engine-DevKit"}
```

---

### `LogEngine.GetStats()`

Get aggregate statistics across all loggers.

**Returns:** Table with structure:

| Field | Type | Description |
|-------|------|-------------|
| `totalMods` | number | Number of registered loggers |
| `totalLogged` | number | Total entries logged across all mods |
| `byLevel` | table | `{ debug = N, info = N, warn = N, error = N }` |
| `modList` | table | Sorted array of mod names |

```lua
local stats = LogEngine.GetStats()
print("Total entries: " .. stats.totalLogged)
print("Errors: " .. stats.byLevel.error)
```

---

### `LogEngine.GetRecentErrors(count)`

Get recent error entries across all mods, newest first.

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `count` | number | `20` | Max errors to return |

**Returns:** Array of log entry tables sorted by timestamp descending.

```lua
local errors = LogEngine.GetRecentErrors(10)
for _, e in ipairs(errors) do
    print(e.modName .. ": " .. e.message)
end
```

---

### `LogEngine.GetModSummary()`

Get a summary of all registered loggers for display.

**Returns:** Array of tables:

| Field | Type | Description |
|-------|------|-------------|
| `modName` | string | Mod identifier |
| `totalLogged` | number | Total entries logged |
| `errorCount` | number | Number of error-level entries |
| `lastLog` | string | Timestamp of most recent log entry |

---

### `LogEngine.SetGlobalLevel(level)`

Set the minimum log level for **all** registered loggers.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `level` | string | `"debug"`, `"info"`, `"warn"`, or `"error"` |

```lua
LogEngine.SetGlobalLevel("warn")  -- silence debug and info across all mods
```

---

### `LogEngine.FlushAll()`

Flush all log files to disk. Files are normally flushed after each write, so this is only needed for explicit sync guarantees.

---

### `LogEngine.GetVersion()`

**Returns:** Version string (e.g., `"v1.0.0"`).

---

## Logger Instance API

The object returned by `LogEngine.CreateLogger()`. Each instance is independent.

### `log.log(level, message)`

Log a message at a specific level.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `level` | string | `"debug"`, `"info"`, `"warn"`, or `"error"` |
| `message` | string | Log message |

```lua
log.log("warn", "Deprecated API used")
```

---

### `log.debug(message)` / `log.info(message)` / `log.warn(message)` / `log.error(message)`

Shorthand methods for each level.

```lua
log.debug("Variable x = 42")
log.info("Mod loaded")
log.warn("Something looks off")
log.error("Critical failure")
```

---

### `log.logf(level, fmt, ...)`

Log a formatted message using `string.format`. Safely handles format errors.

```lua
log.logf("info", "User %s clicked button %d at %s", "V", 42, os.date("%H:%M:%S"))
log.logf("error", "Failed to load %d/%d modules", loaded, total)
```

---

### `log.setLevel(level)`

Change the minimum log level at runtime.

```lua
log.setLevel("warn")  -- only warn and error messages will be logged
```

---

### `log.getLevel()`

Get the current minimum level as a string.

**Returns:** `"debug"`, `"info"`, `"warn"`, or `"error"`.

---

### `log.getEntries(count, filterLevel)`

Get entries from the ring buffer.

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `count` | number | `100` | Max entries to return |
| `filterLevel` | string | `"debug"` | Minimum level filter |

**Returns:** Array of log entry tables.

---

### `log.getStats()`

Get statistics for this logger instance.

**Returns:** Table with `totalLogged` and `byLevel`.

---

### `log.getRecentErrors(count)`

Get recent error-level entries from this logger.

---

### `log.setFilePath(filePath)`

Override the log file path for this mod.

```lua
log.setFilePath("my_mod.log")  -- writes to current directory instead of logs/
```

---

## Log Entry Structure

Each log entry is a table with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | string | ISO timestamp with milliseconds (e.g., `"2026-08-02T00:07:54.524"`) |
| `frame` | number | CET frame number when logged |
| `modName` | string | Mod identifier |
| `message` | string | Log message |
| `level` | number | Numeric level (1=debug, 2=info, 3=warn, 4=error) |
| `levelName` | string | Level name (`"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`) |

---

## File Output

### Log File Location

Default: `0-Engine-Log/logs/<modName>.log`

Each mod gets its own log file. Files are written to a `logs/` subdirectory within the Log-Engine mod folder.

### File Format

```
[2026-08-02T00:07:54.524] [INFO] [0] MyMod: Mod loaded
[2026-08-02T00:07:54.525] [DEBUG] [0] MyMod: frame 1
[2026-08-02T00:07:55.100] [ERROR] [63] MyMod: Failed to load config
```

Format: `[timestamp] [LEVEL] [frame] modName: message`

### File Rotation

When a log file exceeds **2MB** (configurable), it rotates:

```
MyMod.log      → current (truncated)
MyMod.log.1    → previous
MyMod.log.2    → one before that
MyMod.log.3    → ...
MyMod.log.5    → oldest (deleted when exceeded)
```

Rotation uses **read-modify-write** (not `os.rename`) for Windows CET compatibility.

### CET Compatibility

- All file operations wrapped in `pcall`
- Write errors silently logged to CET console (no recursion into logger)
- `debug.getinfo` is NOT used (not available in CET sandbox)
- `os.rename` is NOT used (Windows file locking issues)
- Relative paths resolve from CET working directory

---

## Log Levels

| Level | Name | Numeric | Description |
|-------|------|---------|-------------|
| `debug` | DEBUG | 1 | Verbose trace data, rate-limited |
| `info` | INFO | 2 | Normal operational messages |
| `warn` | WARN | 3 | Something unexpected but recoverable |
| `error` | ERROR | 4 | Critical failures |

### Rate Limiting

Debug messages are rate-limited to **1 per frame** by default (configurable via `maxDebugPerFrame`). This prevents debug spam from overwhelming the log file during rendering.

---

## File Structure

```
engines/Log-Engine/
├── init.lua          # Entry point, SafeRequire, public API, CET callbacks
├── config.lua        # Default configuration values
├── logger.lua        # Core logging engine (ring buffer, levels, formatting)
├── file_output.lua   # File I/O, rotation, path management
├── stats.lua         # Aggregate statistics across all loggers
└── logs/             # Log file output directory (created at runtime)
```

---

## CET Callbacks

| Callback | Behavior |
|----------|----------|
| `onInit()` | Initializes FileOutput and Stats, creates LogEngine's own logger, prints startup summary |
| `onDraw()` | Increments frame counter, resets debug rate limiters |
| `onShutdown()` | Flushes all log files, logs shutdown for each mod |

---

## Configuration Defaults

| Setting | Default | Description |
|---------|---------|-------------|
| `RING_SIZE` | `1024` | Ring buffer entries per mod |
| `DEFAULT_MIN_LEVEL` | `"debug"` | Minimum log level |
| `MAX_FILE_SIZE` | `2097152` (2MB) | File size before rotation |
| `MAX_FILES` | `5` | Rotated files to keep |
| `LOG_DIR` | `"logs"` | Log file subdirectory |
| `LOG_FILE_SUFFIX` | `".log"` | File extension |
| `MAX_DEBUG_PER_FRAME` | `1` | Debug rate limit per frame |

---

## Integration with UI-Engine-DevKit

The DevKit mod demonstrates full Log-Engine integration:

```lua
-- Resolution
local LogEngine = GetMod("0-Engine-Log")
local log = nil
if LogEngine then
    log = LogEngine.CreateLogger("UI-Engine-DevKit", { minLevel = "debug" })
end

-- Every pcall logs errors automatically
local function pcallLog(context, fn, ...)
    local results = table.pack(pcall(fn, ...))
    if not results[1] then
        if log then log.error("PCALL FAIL [" .. context .. "]: " .. tostring(results[2])) end
    end
    return results[1], table.unpack(results, 2, results.n)
end

-- Module resolution logged
if log then log.info("Resolving GetMod(0-Engine-UI)...") end
local ok, result = pcall(GetMod, "0-Engine-UI")
if ok and result then
    if log then log.info("UIEngine resolved OK") end
end

-- Every test result logged
if log then log.info("TEST PASS [Public API] GetVersion() — v0.4.0") end
if log then log.warn("TEST FAIL [Registry API] register() — missing name") end
```

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Separate CET mod, not UI-Engine submodule | Available even when UI-Engine fails to load |
| Per-mod logger instances | Independent ring buffers, files, and levels |
| No `debug.getinfo` | Not available in CET's sandboxed Lua |
| Read-modify-write rotation | Windows CET compatibility (no `os.rename`) |
| Inline config with SafeRequire fallbacks | CET `require` may not resolve sibling modules |
| `require` uses `/` not `.` | CET Lua convention for subdirectory paths |
| File output to `logs/` subdirectory | Organized, not cluttering mod root |
| Rate limiting on debug | Prevents debug spam from overwhelming log files |
| Immediate flush per write | No data loss on crash |
| Idempotent `CreateLogger` | Safe to call multiple times (CET overlay toggle) |
