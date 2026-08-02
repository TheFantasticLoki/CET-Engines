--[[
    Context — UI-Engine

    Provides a `ctx` proxy object that consumer mods use to access
    UI-Engine components safely. The context object is created per-mod
    and includes:

    - Component access (proxied through SafeImGuiCall)
    - State helpers (per-mod, persisted via Storage)
    - Theme access (read-only via Tokens)

    Depends on Core for state, Events for notifications,
    and Components for the component library.
]]

local M = {}

-- --- Internal State ---

local initialized = false
local Core = nil
local Events = nil
local Components = nil
local Tokens = nil
local Utils = nil

-- Per-mod state storage
local modStates = {}

-- --- Public API ---

--- Initialize the context module (idempotent)
-- @param deps table Dependencies { Core, Events, Components, Tokens, Utils }
function M.init(deps)
    if initialized then
        return
    end
    initialized = true

    Core = deps and deps.Core
    Events = deps and deps.Events
    Components = deps and deps.Components
    Tokens = deps and deps.Tokens
    Utils = deps and deps.Utils
end

--- Create a context object for a mod
-- @param id string Mod identifier
-- @param spec table Mod specification
-- @return table Context object with component methods
function M.create(id, spec)
    local ctx = { modId = id, spec = spec }

    -- Initialize state for this mod if not exists
    if not modStates[id] then
        modStates[id] = {}
    end

    -- Proxy all components from the Components module
    if Components then
        for name, fn in pairs(Components) do
            if type(fn) == "function" then
                -- Wrap component calls through SafeImGuiCall if Utils available
                if Utils and Utils.SafeImGuiCall then
                    ctx[name] = function(...)
                        return Utils.SafeImGuiCall(fn, ...)
                    end
                else
                    ctx[name] = fn
                end
            end
        end
    end

    -- State helpers (per-mod, always looks up from modStates table)
    -- This ensures clearState works correctly with existing context objects
    function ctx.getState(key, default)
        local modState = modStates[id]
        if not modState then
            return default
        end
        local val = modState[key]
        if val == nil then return default end
        return val
    end

    function ctx.setState(key, value)
        -- Ensure mod state table exists
        if not modStates[id] then
            modStates[id] = {}
        end
        modStates[id][key] = value
        -- Mark dirty for auto-save via Core
        if Core and Core.markDirty then
            Core.markDirty()
        end
        -- Emit state changed event
        if Events then
            Events.emit("context:stateChanged", id, key, value)
        end
    end

    -- Theme access (read-only)
    function ctx.getThemeColor(role)
        if Tokens and Tokens.color4n then
            return Tokens.color4n(role)
        end
        -- Fallback: return white
        return { r = 1, g = 1, b = 1, a = 1 }
    end

    -- Mod info accessors
    function ctx.getModId()
        return id
    end

    function ctx.getModSpec()
        return spec
    end

    return ctx
end

--- Get state for a mod (external access)
-- @param id string Mod identifier
-- @param key string State key
-- @param default any Default value
-- @return any State value
function M.getState(id, key, default)
    if not modStates[id] then
        return default
    end
    local val = modStates[id][key]
    if val == nil then return default end
    return val
end

--- Set state for a mod (external access)
-- @param id string Mod identifier
-- @param key string State key
-- @param value any State value
function M.setState(id, key, value)
    if not modStates[id] then
        modStates[id] = {}
    end
    modStates[id][key] = value
end

--- Clear state for a mod
-- @param id string Mod identifier
function M.clearState(id)
    modStates[id] = nil
end

return M
