--[[
    Windows — UI-Engine

    Standalone window registration and management for UI-Engine.
    Consumer mods register windows with a draw callback,
    and UI-Engine renders them each frame.

    Depends on Core for state storage, Events for notifications,
    and Logger for error reporting.
]]

local M = {}

-- --- Internal State ---

local initialized = false
local Core = nil
local Events = nil
local Logger = nil
local log = nil  -- Log-Engine fallback

-- --- Schema Validation ---

--- Validate a window specification
-- @param id string Window identifier
-- @param spec table Window specification
-- @return boolean, string|nil success, error message
local function validateWindowSpec(id, spec)
    if type(id) ~= "string" or id == "" then
        return false, "Invalid window ID: must be non-empty string"
    end
    if type(spec) ~= "table" then
        return false, "Invalid window spec: must be table"
    end
    if type(spec.title) ~= "string" or spec.title == "" then
        return false, "Invalid spec.title: must be non-empty string"
    end
    if spec.draw_fn ~= nil and type(spec.draw_fn) ~= "function" then
        return false, "Invalid spec.draw_fn: must be function or nil"
    end
    if spec.width ~= nil and type(spec.width) ~= "number" then
        return false, "Invalid spec.width: must be number or nil"
    end
    if spec.height ~= nil and type(spec.height) ~= "number" then
        return false, "Invalid spec.height: must be number or nil"
    end
    if spec.flags ~= nil and type(spec.flags) ~= "number" then
        return false, "Invalid spec.flags: must be number or nil"
    end
    if spec.resizable ~= nil and type(spec.resizable) ~= "boolean" then
        return false, "Invalid spec.resizable: must be boolean or nil"
    end
    if spec.min_width ~= nil and type(spec.min_width) ~= "number" then
        return false, "Invalid spec.min_width: must be number or nil"
    end
    if spec.min_height ~= nil and type(spec.min_height) ~= "number" then
        return false, "Invalid spec.min_height: must be number or nil"
    end
    return true, nil
end

-- --- Public API ---

--- Initialize the windows module (idempotent)
-- @param deps table Dependencies { Core, Events, Logger }
function M.init(deps)
    if initialized then
        return
    end
    initialized = true

    Core = deps and deps.Core
    Events = deps and deps.Events
    Logger = deps and deps.Logger

    -- Resolve Log-Engine as fallback
    if not Logger then
        local ok, le = pcall(GetMod, "0-Engine-Log")
        if ok and le then
            local ok2, lgr = pcall(le.CreateLogger, "UI-Engine-Windows", { minLevel = "warn" })
            if ok2 and lgr then log = lgr end
        end
    end
end

--- Register a standalone window
-- @param id string Window identifier
-- @param spec table { title, width, height, draw_fn, flags }
-- @return boolean, string|nil success, error message
function M.register(id, spec)
    if not Core then
        return false, "Windows module not initialized"
    end

    local valid, err = validateWindowSpec(id, spec)
    if not valid then
        return false, err
    end

    -- Store the window spec
    Core.setWindow(id, spec)

    -- Emit registration event
    if Events then
        Events.emit("windows:registered", id, spec)
    end

    -- Log registration
    if Logger then
        Logger.Log("Windows", "Registered window: " .. spec.title, "info")
    end

    return true, nil
end

--- Unregister a standalone window
-- @param id string Window identifier
-- @return boolean success
function M.unregister(id)
    if not Core then
        return false
    end

    local spec = Core.getWindow(id)
    if not spec then
        return false
    end

    -- Remove from Core
    Core.removeWindow(id)

    -- Emit unregistration event
    if Events then
        Events.emit("windows:unregistered", id)
    end

    -- Log unregistration
    if Logger then
        Logger.Log("Windows", "Unregistered window: " .. id, "info")
    end

    return true
end

--- Get all registered window IDs
-- @return table Array of window ID strings
function M.getWindowIds()
    if not Core then
        return {}
    end
    return Core.getWindowIds()
end

--- Draw all registered standalone windows
-- (Called by init.lua each frame)
function M.drawAll()
    if not Core then
        return
    end

    local windowIds = Core.getWindowIds()
    for _, id in ipairs(windowIds) do
        local spec = Core.getWindow(id)
        if spec and spec.draw_fn then
            -- Draw the window with error boundary
            local windowOpen = true
            local ok, err = pcall(function()
                -- Set window size if specified
                if spec.width and spec.height then
                    ImGui.SetNextWindowSize(spec.width, spec.height, ImGui.Cond_FirstUseEver)
                end

                -- Begin window
                local visible = ImGui.Begin(spec.title, spec.flags or 0)

                if visible then
                    -- Call the draw function
                    spec.draw_fn()
                end

                ImGui.End()
            end)

            if not ok then
                local msg = "Error drawing window '" .. spec.title .. "': " .. tostring(err)
                if Logger then
                    Logger.Log("Windows", msg, "error")
                elseif log then
                    log.error(msg)
                end
            end
        end
    end
end

return M
