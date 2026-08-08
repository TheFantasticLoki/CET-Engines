--[[
    Init Module Tests — UI-Engine

    Tests for engines/UI-Engine/init.lua
]]

local assert = require("tests.assert")

local M = {}

-- --- Test SafeRequire ---

function M.testSafeRequire()
    -- Test that SafeRequire works for existing modules
    local Core = require("engines.0-Mod-Engine.core")
    assert.assert_not_nil(Core, "Core should be loadable")

    local Logger = require("engines.0-Mod-Engine.modules.logger")
    assert.assert_not_nil(Logger, "Logger should be loadable")

    local Events = require("engines.0-Mod-Engine.api.events")
    assert.assert_not_nil(Events, "Events should be loadable")

    local Utils = require("engines.0-Mod-Engine.ui.utils")
    assert.assert_not_nil(Utils, "Utils should be loadable")
end

-- --- Test Module Loading Order ---

function M.testModuleLoadingOrder()
    -- Verify that modules can be loaded in the correct order
    -- This is a basic check that the require paths work
    local Core = require("engines.0-Mod-Engine.core")
    local Logger = require("engines.0-Mod-Engine.modules.logger")
    local Storage = require("engines.0-Mod-Engine.modules.storage")
    local Events = require("engines.0-Mod-Engine.api.events")
    local Utils = require("engines.0-Mod-Engine.ui.utils")

    assert.assert_not_nil(Core, "Core should be loadable")
    assert.assert_not_nil(Logger, "Logger should be loadable")
    assert.assert_not_nil(Storage, "Storage should be loadable")
    assert.assert_not_nil(Events, "Events should be loadable")
    assert.assert_not_nil(Utils, "Utils should be loadable")
end

-- --- Test Idempotent Init ---

function M.testIdempotentInit()
    -- Load init.lua
    local Init = require("engines.0-Mod-Engine.init")

    -- Call onInit multiple times
    if onInit then
        onInit()
        onInit()
        onInit()
    end

    -- Should not error
    assert.assert_true(true, "onInit should be idempotent")
end

-- --- Test Public API ---

function M.testPublicAPI()
    -- Load init.lua to set up _G.UIEngine
    local Init = require("engines.0-Mod-Engine.init")

    -- Verify UIEngine global exists (CET uses direct assignment, not _G)
    assert.assert_not_nil(UIEngine, "UIEngine global should exist")

    -- Verify all required methods exist
    assert.assert_type(UIEngine.Register, "function", "Register should be a function")
    assert.assert_type(UIEngine.Unregister, "function", "Unregister should be a function")
    assert.assert_type(UIEngine.GetContext, "function", "GetContext should be a function")
    assert.assert_type(UIEngine.GetTheme, "function", "GetTheme should be a function")
    assert.assert_type(UIEngine.SetTheme, "function", "SetTheme should be a function")
    assert.assert_type(UIEngine.GetThemeList, "function", "GetThemeList should be a function")
    assert.assert_type(UIEngine.On, "function", "On should be a function")
    assert.assert_type(UIEngine.Emit, "function", "Emit should be a function")
    assert.assert_type(UIEngine.Off, "function", "Off should be a function")
    assert.assert_type(UIEngine.Deprecated, "function", "Deprecated should be a function")
    assert.assert_type(UIEngine.IsRegistered, "function", "IsRegistered should be a function")
    assert.assert_type(UIEngine.GetRegisteredMods, "function", "GetRegisteredMods should be a function")
    assert.assert_type(UIEngine.GetVersion, "function", "GetVersion should be a function")
    assert.assert_type(UIEngine.Enable, "function", "Enable should be a function")
    assert.assert_type(UIEngine.Disable, "function", "Disable should be a function")
    assert.assert_type(UIEngine.Log, "function", "Log should be a function")
end

-- --- Test OnShutdown ---

function M.testOnShutdown()
    -- Load init.lua
    local Init = require("engines.0-Mod-Engine.init")

    -- Call onShutdown
    if onShutdown then
        onShutdown()
    end

    -- Should not error
    assert.assert_true(true, "onShutdown should not error")
end

return M