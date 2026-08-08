--[[
    Config-Engine Settings Resolver Tests

    Tests for engines/Config-Engine/modules/settings_resolver.lua
]]

local assert = require("tests.assert")
local Resolver = require("engines.0-Mod-Engine.cfg.settings_resolver")

local M = {}

function M.testResolveWithDefaults()
    local schema = {
        settings = {
            enabled = { type = "toggle", default = true },
            volume = { type = "slider", min = 0, max = 100, default = 50 },
        },
    }

    local resolved, warnings = Resolver.resolveSettings(schema, nil)
    assert.assert_equal(resolved.enabled, true, "should use default for enabled")
    assert.assert_equal(resolved.volume, 50, "should use default for volume")
    assert.assert_equal(#warnings, 0, "no warnings for defaults")
end

function M.testResolveWithSaved()
    local schema = {
        settings = {
            enabled = { type = "toggle", default = true },
            volume = { type = "slider", min = 0, max = 100, default = 50 },
        },
    }

    local resolved, warnings = Resolver.resolveSettings(schema, {
        enabled = false,
        volume = 75,
    })
    assert.assert_equal(resolved.enabled, false, "should use saved value")
    assert.assert_equal(resolved.volume, 75, "should use saved value")
end

function M.testResolveWithInvalidSaved()
    local schema = {
        settings = {
            enabled = { type = "toggle", default = true },
        },
    }

    local resolved, warnings = Resolver.resolveSettings(schema, {
        enabled = "not-a-boolean",
    })
    -- Invalid value should fall back to default
    assert.assert_equal(resolved.enabled, true, "should fall back to default")
    assert.assert_true(#warnings > 0, "should have warning for invalid value")
end

function M.testValidateBoolean()
    assert.assert_true(Resolver.validateValue({ type = "toggle" }, true))
    assert.assert_true(Resolver.validateValue({ type = "toggle" }, false))
    assert.assert_false(Resolver.validateValue({ type = "toggle" }, "true"))
end

function M.testValidateSlider()
    assert.assert_true(Resolver.validateValue({ type = "slider", min = 0, max = 100 }, 50))
    assert.assert_false(Resolver.validateValue({ type = "slider", min = 0, max = 100 }, 150))
    assert.assert_false(Resolver.validateValue({ type = "slider", min = 0, max = 100 }, -10))
    assert.assert_false(Resolver.validateValue({ type = "slider" }, "50"))
end

function M.testValidateIntSlider()
    assert.assert_true(Resolver.validateValue({ type = "int_slider", min = 0, max = 10 }, 5))
    assert.assert_false(Resolver.validateValue({ type = "int_slider", min = 0, max = 10 }, 5.5))
end

function M.testValidateCombo()
    local setting = {
        type = "combo",
        options = { "a", "b", "c" },
    }
    assert.assert_true(Resolver.validateValue(setting, "a"))
    assert.assert_true(Resolver.validateValue(setting, "c"))
    assert.assert_false(Resolver.validateValue(setting, "d"))
end

function M.testValidateComboLabeledOptions()
    local setting = {
        type = "combo",
        options = {
            { label = "Option A", value = "a" },
            { label = "Option B", value = "b" },
        },
    }
    assert.assert_true(Resolver.validateValue(setting, "a"))
    assert.assert_false(Resolver.validateValue(setting, "c"))
end

function M.testValidateText()
    assert.assert_true(Resolver.validateValue({ type = "text" }, "hello"))
    assert.assert_false(Resolver.validateValue({ type = "text" }, 123))
end

function M.testValidateColor()
    assert.assert_true(Resolver.validateValue({ type = "color" }, { r = 1, g = 1, b = 1 }))
    assert.assert_false(Resolver.validateValue({ type = "color" }, "red"))
    assert.assert_false(Resolver.validateValue({ type = "color" }, { r = 1 }))
end

function M.testValidateMultiCombo()
    assert.assert_true(Resolver.validateValue({ type = "multi_combo" }, {}))
    assert.assert_true(Resolver.validateValue({ type = "multi_combo" }, { "a", "b" }))
    assert.assert_false(Resolver.validateValue({ type = "multi_combo" }, "not-a-table"))
end

function M.testGetValue()
    local settings = {
        advanced = {
            debug = true,
        },
    }
    assert.assert_true(Resolver.getValue(settings, "advanced.debug"))
    assert.assert_nil(Resolver.getValue(settings, "nonexistent"))
end

function M.testSetValue()
    local settings = {}
    Resolver.setValue(settings, "key", "value")
    assert.assert_equal(settings.key, "value")

    -- Nested
    Resolver.setValue(settings, "nested.key", 42)
    assert.assert_equal(settings.nested.key, 42)
end

function M.testResolveGroup()
    local schema = {
        settings = {
            advanced = {
                type = "group",
                settings = {
                    debug = { type = "toggle", default = false },
                },
            },
        },
    }

    local resolved = Resolver.resolveSettings(schema, nil)
    assert.assert_equal(resolved.advanced.debug, false, "group setting should resolve")
end

return M
