--[[
    Tables Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/tables.lua
]]

local assert = require("tests.assert")
local tables = require("engines.0-Mod-Engine.ui.components.tables")

local M = {}

-- --- Test BeginTable ---

function M.testBeginTable()
    local isOpen = tables.BeginTable("test_table", 3)
    -- In mock, BeginTable is not mocked, so it will return nil
    -- We just verify it doesn't throw
    assert.assert_true(true, "BeginTable should not throw")
end

function M.testBeginTableWithOptions()
    local isOpen = tables.BeginTable("test_table", 2, {
        flags = ImGui.TableFlags.Borders,
        outerSize = { x = 300, y = 200 },
        innerWidth = 280,
    })
    assert.assert_true(true, "BeginTable with options should not throw")
end

-- --- Test EndTable ---

function M.testEndTable()
    tables.EndTable()
    assert.assert_true(true, "EndTable should not throw")
end

-- --- Test TableRow ---

function M.testTableRow()
    tables.TableRow({ "A", "B", "C" })
    assert.assert_true(true, "TableRow should not throw")
end

function M.testTableRowEmpty()
    tables.TableRow({})
    assert.assert_true(true, "TableRow with empty cells should not throw")
end

return M
