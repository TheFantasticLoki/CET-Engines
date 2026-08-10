-- Test: ConfigEngine ModManager
-- Stub smoke tests for cfg/mod_manager.lua

local M = {}

function M.testModuleLoads()
    local ModManager = require("cfg/mod_manager")
    assert(ModManager ~= nil, "ModManager should load")
    assert(type(ModManager.init) == "function", "should have init()")
    assert(type(ModManager.register) == "function", "should have register()")
    assert(type(ModManager.unregister) == "function", "should have unregister()")
    assert(type(ModManager.getModInfo) == "function", "should have getModInfo()")
    assert(type(ModManager.getModList) == "function", "should have getModList()")
end

function M.testRegisterRejectsNilModId()
    local ModManager = require("cfg/mod_manager")
    local ok, err = ModManager.register(nil, { name = "Test", version = "1.0" })
    assert(ok == false, "should reject nil modId")
    assert(err ~= nil, "should provide error message")
end

function M.testRegisterRejectsEmptySpec()
    local ModManager = require("cfg/mod_manager")
    local ok, err = ModManager.register("test", nil)
    assert(ok == false, "should reject nil spec")
end

-- ============================================================
-- Shared Panel Integration Tests
-- ============================================================

function M.testSharedPanelAutoRegister()
    local Core = require("cfg/core")
    local ModManager = require("cfg/mod_manager")
    local Events = require("api/events")

    Core.reset()
    Core.init()
    Events.init(nil, Core)
    ModManager.init({ core = Core, events = Events, categories = nil })

    -- Register a mod with sharedPanel = true
    local ok, err = ModManager.register("shared-mod", {
        name = "Shared Mod",
        version = "1.0.0",
        sharedPanel = true,
        settings = {
            masterToggle = { type = "toggle", label = "Enable", default = true },
        },
    })

    assert(ok == true, "registration should succeed: " .. tostring(err))
    assert(Core.isSharedPanelMod("shared-mod"), "mod should be auto-added to shared panel")
    assert(Core.getSharedPanelModCount() == 1, "shared panel should have 1 mod")
end

function M.testSharedPanelAutoRegisterNotAddedWhenFalse()
    local Core = require("cfg/core")
    local ModManager = require("cfg/mod_manager")
    local Events = require("api/events")

    Core.reset()
    Core.init()
    Events.init(nil, Core)
    ModManager.init({ core = Core, events = Events, categories = nil })

    -- Register a mod without sharedPanel flag
    local ok = ModManager.register("normal-mod", {
        name = "Normal Mod",
        version = "1.0.0",
        settings = {
            masterToggle = { type = "toggle", label = "Enable", default = true },
        },
    })

    assert(ok == true, "registration should succeed")
    assert(not Core.isSharedPanelMod("normal-mod"), "mod should NOT be in shared panel")
    assert(Core.getSharedPanelModCount() == 0, "shared panel should be empty")
end

function M.testSharedPanelUnregisterCleanup()
    local Core = require("cfg/core")
    local ModManager = require("cfg/mod_manager")
    local Events = require("api/events")

    Core.reset()
    Core.init()
    Events.init(nil, Core)
    ModManager.init({ core = Core, events = Events, categories = nil })

    -- Register and then unregister
    ModManager.register("shared-mod", {
        name = "Shared Mod",
        version = "1.0.0",
        sharedPanel = true,
    })
    assert(Core.isSharedPanelMod("shared-mod"), "should be in shared panel")

    ModManager.unregister("shared-mod")
    assert(not Core.isSharedPanelMod("shared-mod"), "should be removed from shared panel after unregister")
    assert(Core.getSharedPanelModCount() == 0, "shared panel should be empty")
end

function M.testSharedPanelMultipleMods()
    local Core = require("cfg/core")
    local ModManager = require("cfg/mod_manager")
    local Events = require("api/events")

    Core.reset()
    Core.init()
    Events.init(nil, Core)
    ModManager.init({ core = Core, events = Events, categories = nil })

    -- Register multiple shared panel mods
    ModManager.register("shared-1", { name = "Shared 1", version = "1.0", sharedPanel = true })
    ModManager.register("shared-2", { name = "Shared 2", version = "1.0", sharedPanel = true })
    ModManager.register("normal", { name = "Normal", version = "1.0" })

    assert(Core.getSharedPanelModCount() == 2, "should have 2 shared panel mods")
    assert(Core.isSharedPanelMod("shared-1"), "shared-1 should be in shared panel")
    assert(Core.isSharedPanelMod("shared-2"), "shared-2 should be in shared panel")
    assert(not Core.isSharedPanelMod("normal"), "normal should not be in shared panel")
end

return M
