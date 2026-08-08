--[[
    Config-Engine Settings Schema Tests

    Tests for engines/Config-Engine/modules/settings_schema.lua
]]

local assert = require("tests.assert")
local Schema = require("engines.0-Mod-Engine.cfg.settings_schema")

local M = {}

function M.testValidateSchemaValid()
    local ok, errors = Schema.validateSchema({
        settings = {
            enabled = {
                type = "toggle",
                default = true,
                label = "Enable",
            },
        },
    })
    assert.assert_true(ok, "valid schema should pass")
    assert.assert_nil(errors, "no errors for valid schema")
end

function M.testValidateSchemaMissingSettings()
    local ok, errors = Schema.validateSchema({})
    assert.assert_false(ok, "schema without settings should fail")
    assert.assert_not_nil(errors, "should have errors")
end

function M.testValidateSchemaNotTable()
    local ok, errors = Schema.validateSchema("invalid")
    assert.assert_false(ok, "non-table schema should fail")
end

function M.testValidateToggle()
    local ok, errors = Schema.validateSetting("test", {
        type = "toggle",
        default = true,
    })
    assert.assert_true(ok, "valid toggle should pass")
end

function M.testValidateToggleMissingDefault()
    local ok, errors = Schema.validateSetting("test", {
        type = "toggle",
    })
    assert.assert_false(ok, "toggle without default should fail")
end

function M.testValidateSlider()
    local ok, errors = Schema.validateSetting("test", {
        type = "slider",
        min = 0,
        max = 100,
        default = 50,
    })
    assert.assert_true(ok, "valid slider should pass")
end

function M.testValidateSliderMinMax()
    local ok, errors = Schema.validateSetting("test", {
        type = "slider",
        min = 100,
        max = 0,
        default = 50,
    })
    assert.assert_false(ok, "slider with min >= max should fail")
end

function M.testValidateSliderMissingMinMax()
    local ok, errors = Schema.validateSetting("test", {
        type = "slider",
        default = 50,
    })
    assert.assert_false(ok, "slider without min/max should fail")
end

function M.testValidateCombo()
    local ok, errors = Schema.validateSetting("test", {
        type = "combo",
        options = { "a", "b", "c" },
        default = "a",
    })
    assert.assert_true(ok, "valid combo should pass")
end

function M.testValidateComboMissingOptions()
    local ok, errors = Schema.validateSetting("test", {
        type = "combo",
        default = "a",
    })
    assert.assert_false(ok, "combo without options should fail")
end

function M.testValidateColor()
    local ok, errors = Schema.validateSetting("test", {
        type = "color",
        default = { r = 1, g = 1, b = 1 },
    })
    assert.assert_true(ok, "valid color should pass")
end

function M.testValidateColorInvalidDefault()
    local ok, errors = Schema.validateSetting("test", {
        type = "color",
        default = "red",
    })
    assert.assert_false(ok, "color with string default should fail")
end

function M.testValidateGroup()
    local ok, errors = Schema.validateSetting("test", {
        type = "group",
        settings = {
            debug = { type = "toggle", default = false },
        },
    })
    assert.assert_true(ok, "valid group should pass")
end

function M.testValidateGroupMissingSettings()
    local ok, errors = Schema.validateSetting("test", {
        type = "group",
    })
    assert.assert_false(ok, "group without settings should fail")
end

function M.testValidateCustomType()
    local ok, errors = Schema.validateSetting("test", {
        type = "custom",
        render = function() end,
    })
    assert.assert_true(ok, "valid custom should pass")
end

function M.testValidateCustomMissingRender()
    local ok, errors = Schema.validateSetting("test", {
        type = "custom",
    })
    assert.assert_false(ok, "custom without render should fail")
end

function M.testValidateUnknownType()
    local ok, errors = Schema.validateSetting("test", {
        type = "unknown",
    })
    assert.assert_false(ok, "unknown type should fail")
end

function M.testGetDefault()
    assert.assert_equal(Schema.getDefault({ type = "toggle", default = true }), true)
    assert.assert_equal(Schema.getDefault({ type = "slider", default = 50 }), 50)
    assert.assert_equal(Schema.getDefault({ type = "text", default = "hello" }), "hello")
end

function M.testGetDefaultColor()
    local color = Schema.getDefault({ type = "color", default = { r = 1, g = 0, b = 0 } })
    assert.assert_equal(color.r, 1)
    assert.assert_equal(color.g, 0)
    assert.assert_equal(color.b, 0)
end

function M.testGetDefaultMultiCombo()
    local list = Schema.getDefault({ type = "multi_combo", default = { "a", "b" } })
    assert.assert_equal(#list, 2)
end

function M.testBuildIndex()
    local index = Schema.buildIndex({
        enabled = { type = "toggle", label = "Enable" },
        advanced = {
            type = "group",
            settings = {
                debug = { type = "toggle", label = "Debug" },
            },
        },
    })
    assert.assert_equal(#index, 3, "should have 3 entries (2 top-level + 1 nested)")
end

function M.testFlattenSettings()
    local flat = Schema.flattenSettings({
        enabled = { type = "toggle", default = true },
        advanced = {
            type = "group",
            settings = {
                debug = { type = "toggle", default = false },
            },
        },
    })
    assert.assert_not_nil(flat["enabled"], "should have enabled key")
    assert.assert_not_nil(flat["advanced.debug"], "should have nested key")
end

function M.testNestedGroupValidation()
    local ok, errors = Schema.validateSchema({
        settings = {
            advanced = {
                type = "group",
                settings = {
                    debug = { type = "toggle", default = false },
                    volume = { type = "slider", min = 0, max = 100, default = 50 },
                },
            },
        },
    })
    assert.assert_true(ok, "nested group should pass validation")
end

return M
