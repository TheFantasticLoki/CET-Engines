--[[
    Utils Auto-Save Tests — UI-Engine

    Tests for the auto-save debounce utilities in ui/utils.lua
]]

local assert = require("tests.assert")
local Utils = require("engines.0-Mod-Engine.ui.utils")

local M = {}

-- --- Test Setup ---

local function setup()
    -- Reset state by clearing pending save and setting frame to 0
    Utils.clearPendingSave()
    Utils.updateFrame(0)
end

-- --- Test MarkDirty Sets Pending Save ---

function M.testMarkDirtySetsPendingSave()
    setup()

    Utils.markDirty()

    -- Should be dirty but not yet pending (frame 0 < delay)
    assert.assert_true(Utils.isDirty(), "Should be dirty after markDirty")
    assert.assert_false(Utils.isSavePending(), "Should not be save pending yet")
end

-- --- Test Save Pending After Delay ---

function M.testSavePendingAfterDelay()
    setup()

    Utils.markDirty()

    -- Advance frames to trigger pending save (30 frames = SAVE_DELAY_FRAMES)
    Utils.updateFrame(30)

    assert.assert_true(Utils.isSavePending(), "Should be save pending after delay")
end

-- --- Test Save Not Pending Before Delay ---

function M.testSaveNotPendingBeforeDelay()
    setup()

    Utils.markDirty()

    -- Advance frames but not enough (29 < 30)
    Utils.updateFrame(29)

    assert.assert_false(Utils.isSavePending(), "Should not be save pending before delay")
end

-- --- Test ClearPendingSave ---

function M.testClearPendingSave()
    setup()

    Utils.markDirty()
    Utils.updateFrame(30)

    assert.assert_true(Utils.isSavePending(), "Should be save pending")

    Utils.clearPendingSave()

    assert.assert_false(Utils.isSavePending(), "Should not be save pending after clear")
    assert.assert_false(Utils.isDirty(), "Should not be dirty after clear")
end

-- --- Test IsDirty ---

function M.testIsDirty()
    setup()

    assert.assert_false(Utils.isDirty(), "Should not be dirty initially")

    Utils.markDirty()

    assert.assert_true(Utils.isDirty(), "Should be dirty after markDirty")

    Utils.clearPendingSave()

    assert.assert_false(Utils.isDirty(), "Should not be dirty after clear")
end

-- --- Test UpdateFrame ---

function M.testUpdateFrame()
    setup()

    Utils.markDirty()

    -- Frame 0: not pending
    assert.assert_false(Utils.isSavePending(), "Frame 0: not pending")

    -- Frame 15: still not pending (15 < 30)
    Utils.updateFrame(15)
    assert.assert_false(Utils.isSavePending(), "Frame 15: not pending")

    -- Frame 30: pending (30 >= 30)
    Utils.updateFrame(30)
    assert.assert_true(Utils.isSavePending(), "Frame 30: pending")

    -- Frame 60: still pending
    Utils.updateFrame(60)
    assert.assert_true(Utils.isSavePending(), "Frame 60: still pending")
end

-- --- Test Multiple MarkDirty Calls ---

function M.testMultipleMarkDirtyCalls()
    setup()

    -- First mark at frame 0
    Utils.markDirty()

    -- Advance to frame 10
    Utils.updateFrame(10)

    -- Mark again (should reset to frame 10 + 30 = 40)
    Utils.markDirty()

    -- Frame 30: should NOT be pending (needs frame 40)
    Utils.updateFrame(30)
    assert.assert_false(Utils.isSavePending(), "Frame 30: not pending after re-mark")

    -- Frame 40: should be pending
    Utils.updateFrame(40)
    assert.assert_true(Utils.isSavePending(), "Frame 40: pending after re-mark")
end

-- --- Test No Dirty Without Mark ---

function M.testNoDirtyWithoutMark()
    setup()

    Utils.updateFrame(100)

    assert.assert_false(Utils.isDirty(), "Should not be dirty without markDirty")
    assert.assert_false(Utils.isSavePending(), "Should not be pending without markDirty")
end

-- --- Test Constants ---

function M.testConstants()
    -- SAVE_DELAY_FRAMES is 30 (local, but we can verify behavior)
    setup()

    Utils.markDirty()

    -- Exactly at delay: should be pending
    Utils.updateFrame(30)
    assert.assert_true(Utils.isSavePending(), "Should be pending at exactly 30 frames")
end

return M
