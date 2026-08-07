--[[
    Events — 0-Mod-Engine

    Pub/sub event system for the unified CET engine. Allows modules to communicate
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

---@class EventSystem
---@field init fun(logger: any|nil, core: any|nil): nil
---@field on fun(event: string, handler: EventHandler, source: string|nil): fun()
---@field emit fun(event: string, ...: any): nil
---@field off fun(event: string, handler: fun(...: any)): nil
---@field once fun(event: string, handler: EventHandler, source: string|nil): fun()
---@field cleanup fun(modId: string): nil
---@field getListenerCount fun(event: string): number
---@field _reset fun(): nil

---@alias EventHandler fun(...: any): nil

local M = {}

-- --- Internal State ---

---@type table<string, {handler: EventHandler, source: string}[]> Event listeners keyed by event name
local listeners = {}
---@type boolean Initialization guard
local initialized = false
---@type any|nil Lazy-loaded Logger module reference
local Logger = nil
---@type Logger? Log-Engine logger instance
local log = nil

-- --- Public API ---

--- Initialize the events module (idempotent)
---@param logger any|nil Optional Logger module reference
---@param core any|nil Optional Core module reference
function M.init(logger, core)
    if initialized then
        return
    end
    initialized = true

    Logger = logger

    -- Resolve a Log-Engine logger instance for debug/trace calls.
    -- NOTE: `Logger` may be the modules/logger module (has .Log, not .debug).
    -- ResolveLogger returns a Log-Engine logger instance (has .debug, .info, etc.)
    log = require("ui/utils").ResolveLogger("0-Mod-Engine-Events")

    if log then log.debug("Events module initialized") end

    -- Late-bind to Core's event emitter
    if core and core.setEventEmitter then
        core.setEventEmitter(M.emit)
    end
end

--- Subscribe to an event
---@param event string Event name
---@param handler EventHandler Handler function
---@param source string|nil Source label (e.g., "core", "theme", "registry")
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

    if log then log.debug("Listener added for '" .. event .. "' from '" .. entry.source .. "'") end

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
        log.trace("Emitting '" .. event .. "' to " .. #listeners[event] .. " handler(s)")
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
---@param handler fun(...: any) Handler function to remove
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

    if log then log.debug("Listener removed for '" .. event .. "'") end
end

--- One-shot subscription (fires once, then auto-unsubscribes)
---@param event string Event name
---@param handler EventHandler Handler function
---@param source string|nil Source label
---@return fun() Unsubscribe function
function M.once(event, handler, source)
    local wrapper
    wrapper = function(...)
        M.off(event, wrapper)
        handler(...)
    end
    if log then log.debug("Once-listener added for '" .. event .. "'") end
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
---@return number Listener count
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