--[[
    Compose Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/compose.lua
]]

local assert = require("tests.assert")
local compose = require("engines.UI-Engine.ui.components.compose")

local M = {}

-- --- Setup ---

-- Mock Logger
local mockLogger = {}
mockLogger.logs = {}
mockLogger.Log = function(_, mod, msg, level)
    table.insert(mockLogger.logs, { mod = mod, msg = msg, level = level })
end

-- --- Test Init ---

function M.testInit()
    compose.init(mockLogger)
    assert.assert_true(true, "Init should not throw")
end

-- --- Test Row ---

function M.testRow()
    local called = false
    compose.Row(function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

function M.testRowNil()
    compose.Row(nil)
    assert.assert_true(true, "Row with nil buildFn should not throw")
end

-- --- Test Column ---

function M.testColumn()
    local called = false
    compose.Column(function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

-- --- Test Stack ---

function M.testStack()
    local called = false
    compose.Stack(function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

-- --- Test Flex ---

function M.testFlex()
    local called = false
    compose.Flex("horizontal", function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

function M.testFlexVertical()
    local called = false
    compose.Flex("vertical", function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

-- --- Test Box ---

function M.testBox()
    local called = false
    compose.Box(function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

-- --- Test Padded ---

function M.testPadded()
    local called = false
    compose.Padded(16, function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

function M.testPaddedTable()
    local called = false
    compose.Padded({ x = 10, y = 5 }, function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

function M.testPaddedArray()
    local called = false
    compose.Padded({ 8, 4 }, function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

-- --- Test Centered ---

function M.testCentered()
    local called = false
    compose.Centered(function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

-- --- Test Spacer ---

function M.testSpacer()
    compose.Spacer(0, 0)
    assert.assert_true(true, "Spacer should not throw")
end

function M.testSpacerCustom()
    compose.Spacer(100, 20)
    assert.assert_true(true, "Spacer with custom size should not throw")
end

-- --- Test Divider ---

function M.testDivider()
    compose.Divider()
    assert.assert_true(true, "Divider should not throw")
end

-- --- Test ErrorBoundary ---

function M.testErrorBoundary()
    compose.init(mockLogger)
    local called = false
    compose.ErrorBoundary(function()
        called = true
    end)
    assert.assert_true(called, "Build function should be called")
end

function M.testErrorBoundaryWithError()
    compose.init(mockLogger)
    local fallbackCalled = false
    compose.ErrorBoundary(function()
        error("Test error")
    end, function()
        fallbackCalled = true
    end)
    assert.assert_true(fallbackCalled, "Fallback should be called on error")
    assert.assert_true(#mockLogger.logs > 0, "Error should be logged")
end

function M.testErrorBoundaryNoFallback()
    compose.init(mockLogger)
    compose.ErrorBoundary(function()
        error("Test error")
    end)
    assert.assert_true(true, "ErrorBoundary without fallback should not throw")
end

-- --- Test GetAvailableSpace ---

function M.testGetAvailableSpace()
    local w, h = compose.GetAvailableSpace()
    assert.assert_not_nil(w, "Width should not be nil")
    assert.assert_not_nil(h, "Height should not be nil")
    assert.assert_true(w >= 0, "Width should be non-negative (clamped from ImGui)")
    assert.assert_true(h >= 0, "Height should be non-negative (clamped from ImGui)")
end

return M
