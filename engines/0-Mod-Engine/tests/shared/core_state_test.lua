--[[
    Core State — Shared Test
    
    Runs both in-game (via Config-Engine test panel) and out-of-game (via test runner).
    This file is DEPLOYED with the mod — keep it lightweight.
    
    How it works:
      - Test function receives ctx with dependencies injected
      - Uses ctx.assert for assertions (same API both environments)
      - Returns result table: { passed, failed, details }
    
    Out-of-game:
        local test = require("tests.shared.core_state_test")
        test.run({ Core = require("core"), assert = frameworkAssert })
    
    In-game (Config-Engine test panel):
        local test = require("tests.shared.core_state_test")
        test.run({ Core = ModEngine.Core, assert = frameworkAssert })
]]

local M = {}

--- Test module name (for display in test panel)
M.name = "Core State"

--- Run all tests in this module.
--- @param ctx table { Core: CoreState, assert: AssertLib }
--- @return table { passed: number, failed: number, details: table[] }
function M.run(ctx)
    local Core = ctx.Core
    local assert = ctx.assert
    local passed = 0
    local failed = 0
    local errors = {}

    local function test(name, fn)
        local ok, err = pcall(fn)
        if ok then
            passed = passed + 1
        else
            failed = failed + 1
            table.insert(errors, name .. ": " .. tostring(err))
        end
    end

    -- SAVE STATE before tests (CRITICAL - don't destroy mods!)
    local snapshot = Core.snapshot()

    -- Test: Default values
    test("defaultValues: currentTheme is Dark", function()
        assert.equal(Core.getCurrentTheme(), "Dark")
    end)

    test("defaultValues: contrastLevel is 1", function()
        assert.equal(Core.getContrastLevel(), 1)
    end)

    test("defaultValues: sidebarOpen is true", function()
        assert.equal(Core.getSidebarOpen(), true)
    end)

    test("defaultValues: selectedMod is nil", function()
        assert.equal(Core.getSelectedMod(), nil)
    end)

    -- Test: Setter/Getter round-trip (each test restores state)
    test("setterGetter: setCurrentTheme", function()
        Core.setCurrentTheme("Red")
        assert.equal(Core.getCurrentTheme(), "Red")
        Core.restore(snapshot)
    end)

    test("setterGetter: setContrastLevel", function()
        Core.setContrastLevel(3)
        assert.equal(Core.getContrastLevel(), 3)
        Core.restore(snapshot)
    end)

    test("setterGetter: setSelectedMod", function()
        Core.setSelectedMod("test-mod")
        assert.equal(Core.getSelectedMod(), "test-mod")
        Core.restore(snapshot)
    end)

    test("setterGetter: setSearchQuery", function()
        Core.setSearchQuery("hello world")
        assert.equal(Core.getSearchQuery(), "hello world")
        Core.restore(snapshot)
    end)

    -- Test: Panel registration (uses test panels, restores after)
    test("panels: setPanel and getPanel", function()
        Core.setPanel("__test_mod", { name = "Test Mod", version = "1.0" })
        local panel = Core.getPanel("__test_mod")
        assert.not_nil(panel)
        assert.equal(panel.name, "Test Mod")
        Core.restore(snapshot)
    end)

    test("panels: removePanel", function()
        Core.setPanel("__test_mod", { name = "Test" })
        Core.removePanel("__test_mod")
        assert.equal(Core.getPanel("__test_mod"), nil)
        Core.restore(snapshot)
    end)

    test("panels: getPanelIds", function()
        local beforeCount = #Core.getPanelIds()
        Core.setPanel("__test_a", { name = "A" })
        Core.setPanel("__test_b", { name = "B" })
        local ids = Core.getPanelIds()
        assert.equal(#ids, beforeCount + 2)
        Core.restore(snapshot)
    end)

    -- RESTORE STATE after all tests (safety net)
    Core.restore(snapshot)

    -- Convert errors to details format for diagnostics panel
    local details = {}
    for _, err in ipairs(errors) do
        local name, msg = err:match("^(.-): (.*)$")
        table.insert(details, {
            name = name or err,
            passed = false,
            error = msg or err,
        })
    end

    return {
        passed = passed,
        failed = failed,
        warnings = 0,
        details = details,
    }
end

return M
