--[[
    Card Tests — UI-Engine

    Tests for engines/UI-Engine/ui/components/containers.lua (Card)
]]

local assert = require("tests.assert")
local containers = require("engines.UI-Engine.ui.components.containers")

local M = {}

-- --- Test Basic Render ---

function M.testBasicRender()
    local clicked = containers.Card({
        title = "Test Card",
        body = function()
            ImGui.Text("Card content")
        end
    })
    assert.assert_false(clicked, "Card should not be clicked on render")
end

-- --- Test Header Content ---

function M.testHeaderContent()
    local clicked = containers.Card({
        title = "My Card",
        subtitle = "Subtitle text",
        icon = "📁",
        body = function()
            ImGui.Text("Body content")
        end
    })
    assert.assert_false(clicked, "Should render header correctly")
end

-- --- Test Body Content ---

function M.testBodyContent()
    local bodyCalled = false
    local clicked = containers.Card({
        title = "Card",
        body = function()
            bodyCalled = true
            ImGui.Text("Content")
        end
    })
    assert.assert_true(bodyCalled, "Body function should be called")
end

-- --- Test Footer Content ---

function M.testFooterContent()
    local footerCalled = false
    local clicked = containers.Card({
        title = "Card",
        body = function()
            ImGui.Text("Body")
        end,
        footer = function()
            footerCalled = true
            ImGui.Text("Footer")
        end
    })
    assert.assert_true(footerCalled, "Footer function should be called")
end

-- --- Test Click Handler ---

function M.testClickHandler()
    local clickCalled = false
    local clicked = containers.Card({
        title = "Clickable Card",
        onClick = function()
            clickCalled = true
        end
    })
    -- Mock ImGui.IsItemClicked returns false, so clicked should be false
    assert.assert_false(clicked, "Click handler should not fire without click")
end

-- --- Test Selected State ---

function M.testSelectedState()
    local clicked = containers.Card({
        title = "Selected Card",
        selected = true,
        body = function()
            ImGui.Text("Content")
        end
    })
    assert.assert_false(clicked, "Selected card should render without error")
end

-- --- Test Minimal Card ---

function M.testMinimalCard()
    local clicked = containers.Card({})
    assert.assert_false(clicked, "Minimal card should render without error")
end

-- --- Test Header Right ---

function M.testHeaderRight()
    local headerRightCalled = false
    local clicked = containers.Card({
        title = "Card with Right",
        headerRight = function()
            headerRightCalled = true
            ImGui.Text("Right")
        end,
        body = function()
            ImGui.Text("Body")
        end
    })
    assert.assert_true(headerRightCalled, "Header right function should be called")
end

return M
