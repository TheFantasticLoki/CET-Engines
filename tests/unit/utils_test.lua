--[[
    Utils Module Tests — UI-Engine

    Tests for engines/UI-Engine/ui/utils.lua
]]

local assert = require("tests.assert")
local Utils = require("engines.0-Mod-Engine.ui.utils")

local M = {}

-- --- Test DeepCopy ---

function M.testDeepCopy()
    local original = {
        a = 1,
        b = "hello",
        c = {
            d = 2,
            e = {
                f = 3,
            },
        },
    }

    local copy = Utils.DeepCopy(original)

    -- Verify values match
    assert.assert_equal(copy.a, 1, "a should match")
    assert.assert_equal(copy.b, "hello", "b should match")
    assert.assert_equal(copy.c.d, 2, "c.d should match")
    assert.assert_equal(copy.c.e.f, 3, "c.e.f should match")

    -- Verify independence
    copy.a = 99
    copy.c.d = 100
    assert.assert_equal(original.a, 1, "Original a should be unchanged")
    assert.assert_equal(original.c.d, 2, "Original c.d should be unchanged")
end

-- --- Test MergeTables ---

function M.testMergeTables()
    local base = {
        a = 1,
        b = "hello",
        c = {
            d = 2,
            e = 3,
        },
    }

    local override = {
        b = "world",
        c = {
            d = 10,
            f = 4,
        },
        g = 5,
    }

    local merged = Utils.MergeTables(base, override)

    assert.assert_equal(merged.a, 1, "a should be from base")
    assert.assert_equal(merged.b, "world", "b should be from override")
    assert.assert_equal(merged.c.d, 10, "c.d should be from override")
    assert.assert_equal(merged.c.e, 3, "c.e should be from base")
    assert.assert_equal(merged.c.f, 4, "c.f should be from override")
    assert.assert_equal(merged.g, 5, "g should be from override")
end

-- --- Test FormatColor ---

function M.testFormatColor()
    -- Full color
    local r, g, b, a = Utils.FormatColor({ r = 0.5, g = 0.6, b = 0.7, a = 0.8 })
    assert.assert_equal(r, 0.5, "r should be 0.5")
    assert.assert_equal(g, 0.6, "g should be 0.6")
    assert.assert_equal(b, 0.7, "b should be 0.7")
    assert.assert_equal(a, 0.8, "a should be 0.8")

    -- Partial color (defaults)
    local r2, g2, b2, a2 = Utils.FormatColor({ r = 0.5 })
    assert.assert_equal(r2, 0.5, "r should be 0.5")
    assert.assert_equal(g2, 1, "g should default to 1")
    assert.assert_equal(b2, 1, "b should default to 1")
    assert.assert_equal(a2, 1, "a should default to 1")

    -- Nil color
    local r3, g3, b3, a3 = Utils.FormatColor(nil)
    assert.assert_equal(r3, 1, "r should default to 1")
    assert.assert_equal(g3, 1, "g should default to 1")
    assert.assert_equal(b3, 1, "b should default to 1")
    assert.assert_equal(a3, 1, "a should default to 1")
end

return M