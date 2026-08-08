--[[
    Config-Engine Undo/Redo Tests

    Tests for engines/Config-Engine/modules/undo_redo.lua
]]

local assert = require("tests.assert")
local UndoRedo = require("engines.0-Mod-Engine.cfg.undo_redo")

local M = {}

function M.testInit()
    UndoRedo.init({ maxSteps = 10 })
    assert.assert_true(UndoRedo.canUndo() == false, "no undo initially")
    assert.assert_true(UndoRedo.canRedo() == false, "no redo initially")
end

function M.testExecute()
    UndoRedo.init()
    local applied = {}

    local cmd = UndoRedo.makeSettingCommand("mod1", "volume", 50, 75)
    local ok = UndoRedo.execute(cmd, function(c)
        table.insert(applied, c)
        return true
    end)

    assert.assert_true(ok, "execute should succeed")
    assert.assert_equal(#applied, 1, "command should be applied")
    assert.assert_true(UndoRedo.canUndo(), "should be able to undo")
    assert.assert_false(UndoRedo.canRedo(), "no redo after execute")
end

function M.testUndo()
    UndoRedo.init()
    local applied = {}
    local reversed = {}

    local cmd = UndoRedo.makeSettingCommand("mod1", "volume", 50, 75)
    UndoRedo.execute(cmd, function(c)
        table.insert(applied, c)
        return true
    end)

    local undone = UndoRedo.undo(function(c)
        table.insert(reversed, c)
        return true
    end)

    assert.assert_not_nil(undone, "undo should return command")
    assert.assert_equal(#reversed, 1, "undo should apply reverse")
    assert.assert_false(UndoRedo.canUndo(), "no more undo")
    assert.assert_true(UndoRedo.canRedo(), "should be able to redo")
end

function M.testRedo()
    UndoRedo.init()
    local applied = {}

    local cmd = UndoRedo.makeSettingCommand("mod1", "volume", 50, 75)
    UndoRedo.execute(cmd, function(c)
        table.insert(applied, c)
        return true
    end)

    UndoRedo.undo(function(c) return true end)
    UndoRedo.redo(function(c)
        table.insert(applied, c)
        return true
    end)

    assert.assert_equal(#applied, 2, "should have applied twice (execute + redo)")
    assert.assert_true(UndoRedo.canUndo(), "should be able to undo again")
end

function M.testRedoClearsOnNewAction()
    UndoRedo.init()

    UndoRedo.execute(
        UndoRedo.makeSettingCommand("mod1", "a", 1, 2),
        function() return true end
    )
    UndoRedo.undo(function() return true end)
    assert.assert_true(UndoRedo.canRedo(), "should have redo")

    UndoRedo.execute(
        UndoRedo.makeSettingCommand("mod1", "b", 3, 4),
        function() return true end
    )
    assert.assert_false(UndoRedo.canRedo(), "redo should be cleared")
end

function M.testBatchExecute()
    UndoRedo.init()
    local applied = {}

    UndoRedo.beginBatch("test batch")
    UndoRedo.execute(
        UndoRedo.makeSettingCommand("mod1", "a", 1, 2),
        function(c) table.insert(applied, c); return true end
    )
    UndoRedo.execute(
        UndoRedo.makeSettingCommand("mod1", "b", 3, 4),
        function(c) table.insert(applied, c); return true end
    )
    UndoRedo.endBatch(function(c) return true end)

    assert.assert_equal(#applied, 2, "both commands should be applied")
    -- One undo for the whole batch
    local undone = UndoRedo.undo(function() return true end)
    assert.assert_not_nil(undone, "batch undo should work")
    assert.assert_equal(undone.type, "batch", "should be batch command")
end

function M.testMaxSteps()
    UndoRedo.init({ maxSteps = 3 })

    for i = 1, 5 do
        UndoRedo.execute(
            UndoRedo.makeSettingCommand("mod1", "key", i - 1, i),
            function() return true end
        )
    end

    assert.assert_equal(UndoRedo.getUndoCount(), 3, "should be capped at maxSteps")
end

function M.testDescriptions()
    UndoRedo.init()

    UndoRedo.execute(
        UndoRedo.makeSettingCommand("mod1", "vol", 50, 75, "Change volume"),
        function() return true end
    )

    assert.assert_equal(UndoRedo.getUndoDescription(), "Change volume")
    assert.assert_nil(UndoRedo.getRedoDescription())
end

function M.testClear()
    UndoRedo.init()

    UndoRedo.execute(
        UndoRedo.makeSettingCommand("mod1", "a", 1, 2),
        function() return true end
    )
    UndoRedo.clear()

    assert.assert_false(UndoRedo.canUndo())
    assert.assert_false(UndoRedo.canRedo())
    assert.assert_equal(UndoRedo.getUndoCount(), 0)
end

function M.testReverseCommand()
    local cmd = UndoRedo.makeSettingCommand("mod1", "vol", 50, 75, "Change vol")
    local reversed = UndoRedo._reverseCommand(cmd)

    assert.assert_equal(reversed.oldValue, 75, "old should become new")
    assert.assert_equal(reversed.newValue, 50, "new should become old")
end

function M.testMakeBatchCommand()
    local cmds = {
        UndoRedo.makeSettingCommand("mod1", "a", 1, 2),
        UndoRedo.makeSettingCommand("mod1", "b", 3, 4),
    }
    local batch = UndoRedo.makeBatchCommand(cmds, "test")

    assert.assert_equal(batch.type, "batch")
    assert.assert_equal(#batch.commands, 2)
    assert.assert_equal(batch.description, "test")
end

function M.testMakePresetCommand()
    local cmd = UndoRedo.makePresetCommand("mod1", { a = 1 }, { a = 2 }, "MyPreset")

    assert.assert_equal(cmd.type, "preset")
    assert.assert_equal(cmd.description, "Apply preset: MyPreset")
end

return M
