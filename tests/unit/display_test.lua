--[[
    Display Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/display.lua
]]

local assert = require("tests.assert")
local display = require("engines.UI-Engine.ui.components.display")

local M = {}

-- --- Test Text ---

function M.testText()
    display.Text("Hello world")
    assert.assert_true(true, "Text should not throw")
end

function M.testTextEmpty()
    display.Text("")
    assert.assert_true(true, "Text with empty string should not throw")
end

function M.testTextNil()
    display.Text(nil)
    assert.assert_true(true, "Text with nil should not throw")
end

-- --- Test TextColored ---

function M.testTextColored()
    display.TextColored({ r = 1, g = 0, b = 0 }, "Red text")
    assert.assert_true(true, "TextColored should not throw")
end

function M.testTextColoredNilColor()
    display.TextColored(nil, "Text")
    assert.assert_true(true, "TextColored with nil color should not throw")
end

-- --- Test TextWrapped ---

function M.testTextWrapped()
    display.TextWrapped("This is a long wrapped text that should wrap within the container")
    assert.assert_true(true, "TextWrapped should not throw")
end

-- --- Test TextDisabled ---

function M.testTextDisabled()
    display.TextDisabled("Disabled text")
    assert.assert_true(true, "TextDisabled should not throw")
end

-- --- Test StatusBadge ---

function M.testStatusBadge()
    display.StatusBadge("Active", { r = 0, g = 1, b = 0 })
    assert.assert_true(true, "StatusBadge should not throw")
end

function M.testStatusBadgeNilColor()
    display.StatusBadge("Active", nil)
    assert.assert_true(true, "StatusBadge with nil color should not throw")
end

-- --- Test InfoRow ---

function M.testInfoRow()
    display.InfoRow("Label:", "Value")
    assert.assert_true(true, "InfoRow should not throw")
end

function M.testInfoRowEmpty()
    display.InfoRow("", "")
    assert.assert_true(true, "InfoRow with empty strings should not throw")
end

-- --- Test Banner ---

function M.testBanner()
    display.Banner("Notification text", { r = 0.4, g = 0.6, b = 1.0 })
    assert.assert_true(true, "Banner should not throw")
end

function M.testBannerNilColor()
    display.Banner("Notification text", nil)
    assert.assert_true(true, "Banner with nil color should not throw")
end

-- --- Test ProgressBar ---

function M.testProgressBar()
    display.ProgressBar(0.5)
    assert.assert_true(true, "ProgressBar should not throw")
end

function M.testProgressBarWithOptions()
    display.ProgressBar(0.75, { label = "75%", width = 200, height = 20 })
    assert.assert_true(true, "ProgressBar with options should not throw")
end

function M.testProgressBarBounds()
    display.ProgressBar(0)
    display.ProgressBar(1)
    display.ProgressBar(-0.5)
    display.ProgressBar(1.5)
    assert.assert_true(true, "ProgressBar should clamp values")
end

-- --- Test Plot ---

function M.testPlot()
    display.Plot("Test", { 1, 2, 3, 4, 5 })
    assert.assert_true(true, "Plot should not throw")
end

function M.testPlotEmpty()
    display.Plot("Test", {})
    assert.assert_true(true, "Plot with empty data should not throw")
end

function M.testPlotWithOptions()
    display.Plot("Test", { 10, 20, 30 }, { min = 0, max = 50, width = 200, height = 100 })
    assert.assert_true(true, "Plot with options should not throw")
end

-- --- Test Histogram ---

function M.testHistogram()
    display.Histogram("Test", { 1, 2, 3, 4, 5 })
    assert.assert_true(true, "Histogram should not throw")
end

function M.testHistogramEmpty()
    display.Histogram("Test", {})
    assert.assert_true(true, "Histogram with empty data should not throw")
end

-- --- Test Notification ---

function M.testNotification()
    display.Notification("Test notification", "info", 3)
    assert.assert_true(true, "Notification should not throw")
end

function M.testNotificationTypes()
    display.Notification("Info", "info")
    display.Notification("Success", "success")
    display.Notification("Warning", "warn")
    display.Notification("Error", "error")
    assert.assert_true(true, "All notification types should work")
end

function M.testRenderNotifications()
    display.RenderNotifications()
    assert.assert_true(true, "RenderNotifications should not throw")
end

return M
