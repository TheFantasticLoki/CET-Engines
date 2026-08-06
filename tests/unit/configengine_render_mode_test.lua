--[[
    Config-Engine Render Mode Tests

    Tests for engines/Config-Engine/modules/render_mode.lua
]]

local assert = require("tests.assert")
local RenderMode = require("engines.Config-Engine.modules.render_mode")

local M = {}

function M.testDetectSchema()
    local mode = RenderMode.detectMode({
        settings = { enabled = { type = "toggle", default = true } },
    })
    assert.assert_equal(mode, "schema", "should detect schema mode")
end

function M.testDetectCustom()
    local mode = RenderMode.detectMode({
        draw = function() end,
    })
    assert.assert_equal(mode, "custom", "should detect custom mode")
end

function M.testDetectHybrid()
    local mode = RenderMode.detectMode({
        settings = { enabled = { type = "toggle", default = true } },
        draw = function() end,
    })
    assert.assert_equal(mode, "hybrid", "should detect hybrid mode")
end

function M.testDetectExternal()
    local mode = RenderMode.detectMode({})
    assert.assert_equal(mode, "external", "should detect external mode")
end

function M.testUsesSchema()
    assert.assert_true(RenderMode.usesSchema("schema"), "schema uses schema")
    assert.assert_true(RenderMode.usesSchema("hybrid"), "hybrid uses schema")
    assert.assert_false(RenderMode.usesSchema("custom"), "custom does not use schema")
    assert.assert_false(RenderMode.usesSchema("external"), "external does not use schema")
end

function M.testUsesCustom()
    assert.assert_true(RenderMode.usesCustom("custom"), "custom uses custom")
    assert.assert_true(RenderMode.usesCustom("hybrid"), "hybrid uses custom")
    assert.assert_false(RenderMode.usesCustom("schema"), "schema does not use custom")
    assert.assert_false(RenderMode.usesCustom("external"), "external does not use custom")
end

return M
