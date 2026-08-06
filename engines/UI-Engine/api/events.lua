--[[
    Events — UI-Engine

    Pub/sub event system for UI-Engine. Allows modules to communicate
    without direct coupling.

    Features:
    - Source labels for debugging
    - Mod-scoped cleanup on Unregister
    - pcall-guarded dispatch with error logging
    - One-shot subscriptions (once)
    - Listener count tracking

    Depends on Core for state change emission.
    Late-binding: Core's _emitEvent is set by Events during init.
]]

---@alias EventHandler fun(...: any): nil

---@class EventSystem
---Pub/sub event system for UI-Engine.
---@field on fun(event: string, handler: EventHandler, source?: string): fun()
---@field emit fun(event: string, ...: any)
---@field off fun(event: string, handler: EventHandler)
---@field once fun(event: string, handler: EventHandler, source?: string): fun()
---@field cleanup fun(modId: string)
---@field getListenerCount fun(event: string): number
---@field init fun(logger?: table, core?: table)
---@field _reset fun()

local M = {}

-- --- Internal State ---

---@type table<string, {handler: EventHandler, source: string}[]>
local listeners = {}  -- { [event] = { {handler, source}, ... } }
local initialized = false
local Logger = nil  -- Lazy-loaded dependency
---@type Logger?
local log = nil  -- Log-Engine fallback

-- --- Public API ---

--- Initialize the events module (idempotent)
---@param logger Optional Logger module reference
---@param core Optional Core module reference
function M.init(logger, core)
    if initialized then
        return
    end
    initialized = true

    Logger = logger

    -- Resolve Log-Engine as fallback for error logging
    if not Logger then
        local ok, le = pcall(GetMod, "0-Engine-Log")
        if ok and le then
            local ok2, lgr = pcall(le.CreateLogger, "UI-Engine-Events", { minLevel = "warn" })
            if ok2 and lgr then log = lgr end
        end
    end

    -- Late-bind to Core's event emitter
    if core and core.setEventEmitter then
        core.setEventEmitter(M.emit)
    end
end

--- Subscribe to an event
---@param event string Event name
---@param handler EventHandler Handler function
---@param source? string Source label (e.g., "core", "theme", "registry")
---@return fun() Unsubscribe function
function M.on(event, handler, source)
    if not listeners[event] then
        listeners[event] = {}
    end

    local entry = {
        handler = handler,
        source = source or "unknown",
    }
    table.insert(listeners[event], entry)
    if log then log.debug("on(" .. event .. ") from " .. (source or "unknown")) end

    -- Return unsubscribe function
    return function()
        M.off(event, handler)
    end
end

--- Emit an event to all subscribers
---@param event string Event name
---@param ... any Event arguments
function M.emit(event, ...)
    if not listeners[event] then
        return
    end

    if log and #listeners[event] > 0 then
        log.trace("emit(" .. event .. ") to " .. #listeners[event] .. " handler(s)")
    end

    -- Copy list to avoid issues if handlers modify listeners
    local snapshot = {}
    for _, entry in ipairs(listeners[event]) do
        table.insert(snapshot, entry)
    end

    for _, entry in ipairs(snapshot) do
        local ok, err = pcall(entry.handler, ...)
        if not ok then
            local msg = "Handler error for '" .. event .. "': " .. tostring(err)
            if Logger then
                Logger.Log("Events", msg, "error")
            elseif log then
                log.error(msg)
            end
        end
    end
end

--- Unsubscribe from an event
---@param event string Event name
---@param handler EventHandler Handler function to remove
function M.off(event, handler)
    if not listeners[event] then
        return
    end

    for i = #listeners[event], 1, -1 do
        if listeners[event][i].handler == handler then
            table.remove(listeners[event], i)
        end
    end

    -- Clean up empty event lists
    if #listeners[event] == 0 then
        listeners[event] = nil
    end
    if log then log.debug("off(" .. event .. ")") end
end

--- One-shot subscription (fires once, then auto-unsubscribes)
---@param event string Event name
---@param handler EventHandler Handler function
---@param source? string Source label
---@return fun() Unsubscribe function
function M.once(event, handler, source)
    local wrapper
    wrapper = function(...)
        M.off(event, wrapper)
        handler(...)
    end
    return M.on(event, wrapper, source)
end

--- Remove all subscriptions for a mod
---@param modId string Module identifier
function M.cleanup(modId)
    for event, entries in pairs(listeners) do
        for i = #entries, 1, -1 do
            if entries[i].source == modId then
                table.remove(entries, i)
            end
        end
        if #entries == 0 then
            listeners[event] = nil
        end
    end
end

--- Get the number of listeners for an event
---@param event string Event name
---@return number count Listener count
function M.getListenerCount(event)
    if not listeners[event] then
        return 0
    end
    return #listeners[event]
end

--- Reset module state (for testing only)
-- Clears all listeners and resets initialization flag.
function M._reset()
    listeners = {}
    initialized = false
    Logger = nil
    log = nil
end

return M