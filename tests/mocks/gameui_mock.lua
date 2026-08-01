--[[
    GameUI Mock

    Provides stubs for GameUI API functions used in CET.
    Used in unit tests to run without the game.

    GameUI is the Cyberpunk 2077 game UI system accessed via CET.
    This mock provides no-op implementations that return sensible defaults.
]]

if _G.GAMEUI_MOCK_LOADED then
    return
end
_G.GAMEUI_MOCK_LOADED = true

-- --- Mock GameUI ---

_G.GameUI = {}

-- Track calls for verification in tests
_G.GameUI._calls = {}

--- Reset call tracking (call in test setup)
function GameUI._resetCalls()
    _G.GameUI._calls = {}
end

--- Get all recorded calls (for test assertions)
function GameUI._getCalls()
    return _G.GameUI._calls
end

--- Check if a specific method was called
-- @param methodName The method name to check
function GameUI._wasCalled(methodName)
    for _, call in ipairs(_G.GameUI._calls) do
        if call.method == methodName then
            return true
        end
    end
    return false
end

--- Get call count for a specific method
-- @param methodName The method name to count
function GameUI._callCount(methodName)
    local count = 0
    for _, call in ipairs(_G.GameUI._calls) do
        if call.method == methodName then
            count = count + 1
        end
    end
    return count
end

--- Mock GameUI.IsInputEnabled()
-- @return boolean Whether input is enabled (overlay is open)
function GameUI.IsInputEnabled()
    table.insert(_G.GameUI._calls, { method = "IsInputEnabled" })
    return _G._mockInputEnabled or false
end

--- Set the mock return value for IsInputEnabled
-- @param enabled boolean
function GameUI._setInputEnabled(enabled)
    _G._mockInputEnabled = enabled
end

--- Mock GameUI.GetScreenResolution()
-- @return number, number Width and height
function GameUI.GetScreenResolution()
    table.insert(_G.GameUI._calls, { method = "GetScreenResolution" })
    return 1920, 1080
end

--- Mock GameUI.GetViewportSize()
-- @return number, number Width and height
function GameUI.GetViewportSize()
    table.insert(_G.GameUI._calls, { method = "GetViewportSize" })
    return 1920, 1080
end

--- Mock GameUI.GetDisplayScale()
-- @return number Scale factor
function GameUI.GetDisplayScale()
    table.insert(_G.GameUI._calls, { method = "GetDisplayScale" })
    return 1.0
end

--- Mock GameUI.GetHUDManager()
-- @return table Mock HUD manager
function GameUI.GetHUDManager()
    table.insert(_G.GameUI._calls, { method = "GetHUDManager" })
    return {
        GetPlayerMappin = function() return nil end,
        GetGameController = function() return nil end,
        GetCursorManager = function() return nil end,
    }
end

--- Mock GameUI.GetBlackboardDefs()
-- @return table Mock blackboard definitions
function GameUI.GetBlackboardDefs()
    table.insert(_G.GameUI._calls, { method = "GetBlackboardDefs" })
    return {}
end

--- Mock GameUI.GetModifications()
-- @return table Mock UI modifications
function GameUI.GetModifications()
    table.insert(_G.GameUI._calls, { method = "GetModifications" })
    return {}
end

--- Mock GameUI.GetWidgetManager()
-- @return table Mock widget manager
function GameUI.GetWidgetManager()
    table.insert(_G.GameUI._calls, { method = "GetWidgetManager" })
    return {
        CreateWidget = function() return nil end,
        DestroyWidget = function() end,
    }
end

--- Mock GameUI.GetAllWidgets()
-- @return table Empty widget list
function GameUI.GetAllWidgets()
    table.insert(_G.GameUI._calls, { method = "GetAllWidgets" })
    return {}
end

--- Mock GameUI.IsSystemMenu()
-- @return boolean
function GameUI.IsSystemMenu()
    table.insert(_G.GameUI._calls, { method = "IsSystemMenu" })
    return false
end

--- Mock GameUI.IsPhotoModeActive()
-- @return boolean
function GameUI.IsPhotoModeActive()
    table.insert(_G.GameUI._calls, { method = "IsPhotoModeActive" })
    return false
end

--- Mock GameUI.IsDialogActive()
-- @return boolean
function GameUI.IsDialogActive()
    table.insert(_G.GameUI._calls, { method = "IsDialogActive" })
    return false
end

--- Mock GameUI.IsBraindanceActive()
-- @return boolean
function GameUI.IsBraindanceActive()
    table.insert(_G.GameUI._calls, { method = "IsBraindanceActive" })
    return false
end

--- Mock GameUI.IsVehicleSceneActive()
-- @return boolean
function GameUI.IsVehicleSceneActive()
    table.insert(_G.GameUI._calls, { method = "IsVehicleSceneActive" })
    return false
end

--- Mock GameUI.IsWardrobeSceneActive()
-- @return boolean
function GameUI.IsWardrobeSceneActive()
    table.insert(_G.GameUI._calls, { method = "IsWardrobeSceneActive" })
    return false
end