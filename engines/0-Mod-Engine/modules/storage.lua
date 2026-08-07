--[[
    Storage — UI-Engine

    Atomic JSON key-value storage for UI-Engine.
    Provides persistent storage for settings and other data.

    CET-compatible: Uses read-modify-write (NOT os.rename).
    Atomic writes: temp → backup → primary pattern.
    Depends on Logger for error reporting.
]]

---@class Storage
--- Atomic JSON key-value storage for UI-Engine.
--- Provides persistent storage for settings and other data.
local M = {}

-- --- Constants ---

local STORAGE_FILE = "uiengine_storage.json"
local BACKUP_FILE = "uiengine_storage.json.bak"
local TEMP_FILE = "uiengine_storage.json.tmp"

-- --- Internal State ---

---@type table<string, table<string, any>> All stored data keyed by mod name
local data = {}
---@type boolean Whether there are unsaved changes
local dirty = false
---@type boolean Whether storage has been initialized
local initialized = false
---@type table|nil Legacy Logger module reference (lazy-loaded dependency)
local Logger = nil
---@type Logger? Log-Engine logger instance
local log = nil

-- --- Helper Functions ---

local Utils = require("ui/utils")

--- Read entire file contents.
---@param path string File path
---@return string|nil content File contents, or nil if read failed
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

--- Write content to file (truncate + write).
---@param path string File path
---@param content string Content to write
---@return boolean success True on success
local function writeFile(path, content)
    local f = io.open(path, "w")
    if not f then
        logError("Failed to open '" .. path .. "' for writing")
        return false
    end
    local ok, err = pcall(function() f:write(content) end)
    f:close()
    if not ok then
        logError("Write error to '" .. path .. "': " .. tostring(err))
        return false
    end
    return true
end

--- Log an error message via legacy Logger or Log-Engine.
---@param msg string Error message
local function logError(msg)
    if Logger then
        Logger.Log("Storage", msg, "error")
    elseif log then
        log.error(msg)
    end
end

--- Scan a table recursively for non-JSON-serializable values (functions, userdata, threads).
--- Returns a sanitized copy with problematic values replaced by nil.
---@param t table The table to scan
---@param path string Current path for diagnostics
---@return table sanitized Sanitized copy
local function sanitizeForJson(t, path)
    if type(t) ~= "table" then return t end
    local result = {}
    for k, v in pairs(t) do
        local vtype = type(v)
        if vtype == "function" then
            -- Don't copy functions (not JSON-serializable)
        elseif vtype == "userdata" or vtype == "thread" then
            -- Skip userdata/threads (not JSON-serializable)
        elseif vtype == "table" then
            local ok, sub = pcall(sanitizeForJson, v, path .. "." .. tostring(k))
            if ok then
                result[k] = sub
            end
        else
            result[k] = v
        end
    end
    return result
end

--- Log an info message via legacy Logger or Log-Engine.
---@param msg string Info message
local function logInfo(msg)
    if Logger then
        Logger.Log("Storage", msg, "info")
    elseif log then
        log.info(msg)
    end
end

-- --- Public API ---

--- Initialize storage (idempotent).
--- Loads data from disk, falling back to backup then fresh state.
---@param logger? LegacyLogger Legacy Logger module reference
function M.init(logger)
    if initialized then
        return
    end
    initialized = true

    Logger = logger

    -- Storage initialized (paths are relative to CET mods directory)

    -- Resolve Log-Engine as fallback
    if not Logger then
        log = Utils.ResolveLogger("Storage")
    end

    -- Try to load from primary file
    local content = readFile(STORAGE_FILE)
    if content then
        local ok, parsed = pcall(json.decode, content)
        if ok and type(parsed) == "table" then
            data = parsed
            logInfo("Loaded storage from " .. STORAGE_FILE)
        else
            logError("Failed to parse " .. STORAGE_FILE .. ", trying backup")
            -- Try backup
            local backupContent = readFile(BACKUP_FILE)
            if backupContent then
                local ok2, parsed2 = pcall(json.decode, backupContent)
                if ok2 and type(parsed2) == "table" then
                    data = parsed2
                    logInfo("Loaded storage from backup " .. BACKUP_FILE)
                else
                    logError("Failed to parse backup, starting fresh")
                    data = {}
                end
            else
                logInfo("No backup found, starting fresh")
                data = {}
            end
        end
    else
        logInfo("No storage file found, starting fresh")
        data = {}
    end

    if log then log.info("Storage initialized: " .. tostring(next(data) and "loaded data" or "fresh state")) end
end

--- Save all data to disk (atomic write pattern: temp → backup → primary).
---@return boolean success True on success, false on failure
function M.Save()
    local ok, err = pcall(function()
        local sanitized = sanitizeForJson(data, "root")
        local encoded = json.encode(sanitized)
        if not writeFile(TEMP_FILE, encoded) then
            error("Failed to write temp file: " .. TEMP_FILE)
        end

        -- Step 2: Copy current to backup (if exists)
        local currentContent = readFile(STORAGE_FILE)
        if currentContent then
            writeFile(BACKUP_FILE, currentContent)
        end

        -- Step 3: Write temp to primary
        local tempContent = readFile(TEMP_FILE)
        if tempContent then
            writeFile(STORAGE_FILE, tempContent)
        end

        dirty = false
    end)

    if not ok then
        print("[Storage] Save FAILED: " .. tostring(err))
        logError("Save failed: " .. tostring(err))
        return false
    end

    if log then log.debug("Storage saved successfully") end
    return true
end

--- Set a value for a mod (marks storage as dirty).
---@param modName string Module name
---@param key string Key name
---@param value any Value to store
function M.Set(modName, key, value)
    if not data[modName] then
        data[modName] = {}
    end
    data[modName][key] = value
    dirty = true
end

--- Get a value for a mod.
---@param modName string Module name
---@param key string Key name
---@param defaultValue? any Default value if key doesn't exist
---@return any value The stored value or default
function M.Get(modName, key, defaultValue)
    if data[modName] and data[modName][key] ~= nil then
        return data[modName][key]
    end
    return defaultValue
end

--- Clear all data for a mod (marks storage as dirty).
---@param modName string Module name
function M.Clear(modName)
    if data[modName] then
        data[modName] = nil
        dirty = true
    end
end

--- Check if there are unsaved changes.
---@return boolean dirty True if dirty
function M.IsDirty()
    return dirty
end

return M