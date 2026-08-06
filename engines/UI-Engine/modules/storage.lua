--[[
    Storage — UI-Engine

    Atomic JSON key-value storage for UI-Engine.
    Provides persistent storage for settings and other data.

    CET-compatible: Uses read-modify-write (NOT os.rename).
    Atomic writes: temp → backup → primary pattern.
    Depends on Logger for error reporting.
]]

local M = {}

-- --- Constants ---

local STORAGE_FILE = "uiengine_storage.json"
local BACKUP_FILE = "uiengine_storage.json.bak"
local TEMP_FILE = "uiengine_storage.json.tmp"

-- --- Internal State ---

local data = {}
local dirty = false
local initialized = false
local Logger = nil  -- Lazy-loaded dependency
local log = nil  -- Log-Engine fallback

-- --- Helper Functions ---

--- Deep copy a table
---@param t Table to copy
---@return table Deep copy
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local result = {}
    for k, v in pairs(t) do
        result[k] = deepCopy(v)
    end
    return result
end

--- Read file contents
---@param path File path
---@return string|nil File contents or nil
local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

--- Write content to file
---@param path File path
---@param content Content to write
---@return boolean Success
local function writeFile(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

--- Log an error message
---@param msg Error message
local function logError(msg)
    if Logger then
        Logger.Log("Storage", msg, "error")
    elseif log then
        log.error(msg)
    end
end

--- Log an info message
---@param msg Info message
local function logInfo(msg)
    if Logger then
        Logger.Log("Storage", msg, "info")
    elseif log then
        log.info(msg)
    end
end

-- --- Public API ---

--- Initialize storage (idempotent)
---@param logger Optional Logger module reference
function M.init(logger)
    if initialized then
        return
    end
    initialized = true

    Logger = logger

    -- Resolve Log-Engine as fallback
    if not Logger then
        local ok, le = pcall(GetMod, "0-Engine-Log")
        if ok and le then
            local ok2, lgr = pcall(le.CreateLogger, "UI-Engine-Storage", { minLevel = "warn" })
            if ok2 and lgr then log = lgr end
        end
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
end

--- Save all data to disk (atomic write)
---@return boolean Success
function M.Save()
    local ok, err = pcall(function()
        -- Step 1: Write to temp file
        local encoded = json.encode(data)
        if not writeFile(TEMP_FILE, encoded) then
            error("Failed to write temp file")
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
        logError("Save failed: " .. tostring(err))
        return false
    end

    return true
end

--- Set a value for a mod
---@param modName Module name
---@param key Key name
---@param value Value to store
function M.Set(modName, key, value)
    if not data[modName] then
        data[modName] = {}
    end
    data[modName][key] = value
    dirty = true
end

--- Get a value for a mod
---@param modName Module name
---@param key Key name
---@param defaultValue Default value if key doesn't exist
---@return any The stored value or default
function M.Get(modName, key, defaultValue)
    if data[modName] and data[modName][key] ~= nil then
        return data[modName][key]
    end
    return defaultValue
end

--- Clear all data for a mod
---@param modName Module name
function M.Clear(modName)
    if data[modName] then
        data[modName] = nil
        dirty = true
    end
end

--- Check if there are unsaved changes
---@return boolean True if dirty
function M.IsDirty()
    return dirty
end

return M