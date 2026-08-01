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

-- --- Mock registerHotkey() ---

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
    -- Simple implementation for testing
    if type(value) == "table" then
        local parts = {}
        for k, v in pairs(value) do
            local vk = tostring(k)
            local vv
            if type(v) == "string" then
                vv = '"' .. v .. '"'
            elseif type(v) == "table" then
                vv = _G.json.encode(v)
            else
                vv = tostring(v)
            end
            table.insert(parts, '"' .. vk .. '": ' .. vv)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif type(value) == "string" then
        return '"' .. value .. '"'
    else
        return tostring(value)
    end
end

--- Mock json.decode()
-- @param str JSON string to decode
function _G.json.decode(str)
    -- Very simple parser for testing
    -- In real tests, use a proper JSON library
    if str == "null" then return nil end
    if str == "true" then return true end
    if str == "false" then return false end
    if tonumber(str) then return tonumber(str) end
    -- Return the string as-is for complex values
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