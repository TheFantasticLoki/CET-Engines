--[[
    Compose — UI-Engine Component Library

    Composition primitives for layout and error handling.
    Includes Row, Column, Stack, Flex, Box, Padded, Centered,
    Spacer, Divider, ErrorBoundary, GetLastBounds, GetAvailableSpace.

    Dependencies: ui/utils.lua, ui/tokens.lua, modules/logger.lua
]]

local M = {}

local Utils = require("ui.utils")
local Tokens = require("ui.tokens")

-- Lazy-loaded Logger
local _logger = nil

--- Initialize compose module
-- @param logger Logger module reference
function M.init(logger)
    _logger = logger
end

-- --- Row ---

--- Row layout (horizontal)
-- @param buildFn Function that builds row content
-- @return nil
function M.Row(buildFn)
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end
end

-- --- Column ---

--- Column layout (vertical)
-- @param buildFn Function that builds column content
-- @return nil
function M.Column(buildFn)
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end
end

-- --- Stack ---

--- Stack layout (overlapping)
-- @param buildFn Function that builds stack content
-- @return nil
function M.Stack(buildFn)
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end
end

-- --- Flex ---

--- Flex layout
-- @param direction Direction string: "horizontal" or "vertical"
-- @param buildFn Function that builds flex content
-- @return nil
function M.Flex(direction, buildFn)
    direction = direction or "horizontal"

    -- For horizontal, add SameLine between items
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end
end

-- --- Box ---

--- Box layout
-- @param buildFn Function that builds box content
-- @return nil
function M.Box(buildFn)
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end
end

-- --- Padded ---

--- Padded layout
-- @param padding Padding size in pixels or {x, y}
-- @param buildFn Function that builds padded content
-- @return nil
function M.Padded(padding, buildFn)
    padding = padding or Tokens.SPACING.md

    local paddingX, paddingY
    if type(padding) == "table" then
        paddingX = padding.x or padding[1] or 8
        paddingY = padding.y or padding[2] or 8
    else
        paddingX = padding
        paddingY = padding
    end

    -- Push style vars for padding
    Utils.SafeImGuiCall(ImGui.PushStyleVar, ImGuiStyleVar.WindowPadding, paddingX, paddingY)
    Utils.SafeImGuiCall(ImGui.PushStyleVar, ImGuiStyleVar.FramePadding, paddingX / 2, paddingY / 2)

    -- Build content
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end

    -- Pop 2 style vars
    Utils.SafeImGuiCall(ImGui.PopStyleVar, 2)
end

-- --- Centered ---

--- Centered layout
-- @param buildFn Function that builds centered content
-- @return nil
function M.Centered(buildFn)
    -- Calculate centering offset
    local windowWidth = ImGui.GetWindowSize()
    if windowWidth > 0 then
        ImGui.SetCursorPosX(windowWidth / 2)
    end

    -- Build content
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end
end

-- --- Spacer ---

--- Spacer element
-- @param width Spacer width (0 for horizontal, -1 for auto)
-- @param height Spacer height (0 for vertical, -1 for auto)
function M.Spacer(width, height)
    width = width or 0
    height = height or 0

    Utils.SafeImGuiCall(ImGui.Dummy, width, height)
end

-- --- Divider ---

--- Divider line
function M.Divider()
    Utils.SafeImGuiCall(ImGui.Separator)
end

-- --- Error Boundary ---

--- Catches errors per-mod without crashing frame
-- @param buildFn Function to wrap
-- @param fallback Optional fallback UI function (called on error)
-- @return nil
function M.ErrorBoundary(buildFn, fallback)
    if not buildFn or type(buildFn) ~= "function" then
        return
    end

    local ok, err = pcall(buildFn)

    if not ok then
        -- Log error
        if _logger and _logger.Log then
            _logger.Log("ErrorBoundary", "Component error: " .. tostring(err), "error")
        end

        -- Render fallback UI
        if fallback and type(fallback) == "function" then
            local fallbackOk, fallbackErr = pcall(fallback)
            if not fallbackOk then
                Utils.SafeImGuiCall(ImGui.TextColored, 1, 0.2, 0.2, 1, "[Error]")
            end
        else
            Utils.SafeImGuiCall(ImGui.TextColored, 1, 0.2, 0.2, 1, "[Error]")
        end
    end
end

-- --- Bounds Tracking ---

-- Internal bounds state
local _lastBounds = { x = 0, y = 0, w = 0, h = 0 }

--- Get the last rendered bounds
-- @return table {x, y, w, h}
function M.GetLastBounds()
    return _lastBounds
end

--- Update last bounds (called internally after rendering)
function M.UpdateLastBounds()
    _lastBounds = {
        x = ImGui.GetCursorScreenPos().x,
        y = ImGui.GetCursorScreenPos().y,
        w = ImGui.GetContentRegionAvail().x,
        h = ImGui.GetContentRegionAvail().y,
    }
end

-- --- Available Space ---

--- Get available space in current region
-- @return number, number width, height
function M.GetAvailableSpace()
    local w, h = ImGui.GetContentRegionAvail()
    return w, h
end

return M
