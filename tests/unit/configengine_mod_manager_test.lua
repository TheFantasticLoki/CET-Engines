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

return M
