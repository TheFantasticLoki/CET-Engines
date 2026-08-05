--[[
    CET Runtime Mock

    Provides stubs for CET (Cyber Engine Tweaks) API functions.
    Used in unit tests to run without the game.

    CET globals to mock:
    - GetMod() — resolve cross-mod dependencies
    - registerHotkey() — register keyboard shortcuts
    - registerInputEvent() — register input events
    - json — JSON encode/decode
    - Game — game entity access
    - Game.GetPlayer() — player entity
    - Game.GetUI() — UI system
    - Game.GetSystemsManager() — ECS systems
    - Cron — delayed/periodic execution
    - GameSession — session state
]]

-- Prevent loading real CET
if _G.CET_MOCK_LOADED then
    return
end
_G.CET_MOCK_LOADED = true

-- --- Mock GetMod() ---

local registeredMods = {}

--- Register a mock mod for GetMod() resolution
-- @param modId The mod identifier
-- @param modTable The mod's public API table
function _G._registerMockMod(modId, modTable)
    registeredMods[modId] = modTable
end

--- Mock GetMod() — returns registered mock mod or nil
-- @param modId The mod identifier to resolve
function _G.GetMod(modId)
    return registeredMods[modId] or nil
end

--- Clear all registered mock mods
function _G._clearMockMods()
    registeredMods = {}
end

-- --- Mock registerForEvent() ---

_G.registerForEventCallbacks = {}

--- Mock registerForEvent() — stores callback for later invocation
-- @param event Event name (onInit, onDraw, onShutdown, etc.)
-- @param callback Callback function
function _G.registerForEvent(event, callback)
    _G.registerForEventCallbacks[event] = callback
end

--- Mock registerHotkey() ---

_G.hotkeys = {}

--- Mock registerHotkey()
-- @param id Hotkey identifier
-- @param description Description string
-- @param callback Callback function
function _G.registerHotkey(id, description, callback)
    _G.hotkeys[id] = {
        description = description,
        callback = callback,
    }
end

-- --- Mock registerInputEvent() ---

_G.inputEvents = {}

--- Mock registerInputEvent()
-- @param id Event identifier
-- @param callback Callback function
function _G.registerInputEvent(id, callback)
    _G.inputEvents[id] = callback
end

-- --- Mock json ---

_G.json = {}

--- Mock json.encode()
-- @param value Value to encode
function _G.json.encode(value)
    -- Proper JSON encoder for testing
    if value == nil then
        return "null"
    elseif type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "number" then
        return tostring(value)
    elseif type(value) == "string" then
        -- Escape special characters
        local escaped = value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
        return '"' .. escaped .. '"'
    elseif type(value) == "table" then
        -- Check if it's an array (sequential integer keys starting at 1)
        local isArray = true
        local maxIndex = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                isArray = false
                break
            end
            if k > maxIndex then maxIndex = k end
        end
        if isArray and maxIndex == #value then
            -- Array
            local parts = {}
            for i = 1, #value do
                table.insert(parts, _G.json.encode(value[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            -- Object
            local parts = {}
            for k, v in pairs(value) do
                table.insert(parts, _G.json.encode(tostring(k)) .. ":" .. _G.json.encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return tostring(value)
    end
end

--- Mock json.decode()
-- @param str JSON string to decode
function _G.json.decode(str)
    -- Simple recursive JSON parser for testing
    if not str or str == "" then return nil end

    str = str:match("^%s*(.-)%s*$")  -- trim whitespace

    -- null
    if str == "null" then return nil end
    -- boolean
    if str == "true" then return true end
    if str == "false" then return false end
    -- number
    if tonumber(str) then return tonumber(str) end
    -- string
    if str:sub(1, 1) == '"' and str:sub(-1) == '"' then
        local s = str:sub(2, -2)
        -- Unescape
        s = s:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t'):gsub('\\\\', '\\')
        return s
    end
    -- array
    if str:sub(1, 1) == '[' and str:sub(-1) == ']' then
        local inner = str:sub(2, -2)
        local result = {}
        if inner ~= "" then
            -- Simple split by comma (not handling nested commas)
            local depth = 0
            local current = ""
            local inString = false
            for i = 1, #inner do
                local c = inner:sub(i, i)
                if c == '"' then
                    inString = not inString
                elseif not inString then
                    if c == '[' or c == '{' then depth = depth + 1
                    elseif c == ']' or c == '}' then depth = depth - 1
                    end
                end
                if c == ',' and depth == 0 and not inString then
                    table.insert(result, _G.json.decode(current))
                    current = ""
                else
                    current = current .. c
                end
            end
            if current ~= "" then
                table.insert(result, _G.json.decode(current))
            end
        end
        return result
    end
    -- object
    if str:sub(1, 1) == '{' and str:sub(-1) == '}' then
        local inner = str:sub(2, -2)
        local result = {}
        if inner ~= "" then
            local depth = 0
            local current = ""
            local inString = false
            for i = 1, #inner do
                local c = inner:sub(i, i)
                if c == '"' then
                    inString = not inString
                elseif not inString then
                    if c == '[' or c == '{' then depth = depth + 1
                    elseif c == ']' or c == '}' then depth = depth - 1
                    end
                end
                if c == ',' and depth == 0 and not inString then
                    local pair = current:match("^%s*(.-)%s*$")
                    local key, val = pair:match("^\"(.-)\"%s*:%s*(.*)$")
                    if key and val then
                        result[key] = _G.json.decode(val)
                    end
                    current = ""
                else
                    current = current .. c
                end
            end
            if current ~= "" then
                local pair = current:match("^%s*(.-)%s*$")
                local key, val = pair:match("^\"(.-)\"%s*:%s*(.*)$")
                if key and val then
                    result[key] = _G.json.decode(val)
                end
            end
        end
        return result
    end
    -- fallback
    return str
end

-- --- Mock Game ---

_G.Game = {}

--- Mock Game.GetPlayer()
function _G.Game.GetPlayer()
    return {
        GetWorldPosition = function() return { x = 0, y = 0, z = 0 } end,
        GetHealth = function() return 100 end,
        GetMaxHealth = function() return 100 end,
        GetStamina = function() return 100 end,
        GetMaxStamina = function() return 100 end,
    }
end

--- Mock Game.GetUI()
function _G.Game.GetUI()
    return {
        IsInputEnabled = function() return false end,
    }
end

--- Mock Game.GetSystemsManager()
function _G.Game.GetSystemsManager()
    return {}
end

-- --- Mock GameUI ---

_G.GameUI = {}

--- Mock GameUI.IsInputEnabled()
function _G.GameUI.IsInputEnabled()
    return false
end

-- --- Mock Cron ---

_G.Cron = {}

local cronJobs = {}
local nextCronId = 1

--- Mock Cron.After()
-- @param delay Delay in seconds
-- @param callback Callback function
function _G.Cron.After(delay, callback)
    local id = nextCronId
    nextCronId = nextCronId + 1
    cronJobs[id] = { delay = delay, callback = callback }
    return id
end

--- Mock Cron.Every()
-- @param interval Interval in seconds
-- @param callback Callback function
function _G.Cron.Every(interval, callback)
    local id = nextCronId
    nextCronId = nextCronId + 1
    cronJobs[id] = { interval = interval, callback = callback }
    return id
end

--- Mock Cron.Halt()
-- @param id Cron job id to halt
function _G.Cron.Halt(id)
    cronJobs[id] = nil
end

--- Get all pending cron jobs (for testing)
function _G._getCronJobs()
    return cronJobs
end

--- Clear all cron jobs (for testing)
function _G._clearCronJobs()
    cronJobs = {}
    nextCronId = 1
end

-- --- Mock GameSession ---

_G.GameSession = {}

--- Mock GameSession.OnStart()
function _G.GameSession.OnStart(callback)
    -- Store for manual triggering in tests
    _G._gameSessionStartCallback = callback
end

--- Mock GameSession.OnExit()
function _G.GameSession.OnExit(callback)
    _G._gameSessionExitCallback = callback
end

-- --- Mock Observe / Overload ---

_G.Observe = function(target, callback)
    -- Stub for observation hooks
end

_G.Overload = function(target, callback)
    -- Stub for function overloading
end

-- --- Mock ImGui global (minimal) ---

if not _G.ImGui then
    _G.ImGui = {}
end

-- --- Mock Timer ---

_G.Timer = {}

--- Mock Timer.after()
function _G.Timer.after(delay, callback)
    return { cancel = function() end }
end

-- --- Mock logging ---

if not _G.print then
    _G.print = function(...)
        -- no-op in test environment
    end
end