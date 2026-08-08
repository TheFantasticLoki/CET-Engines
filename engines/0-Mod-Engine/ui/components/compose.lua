--[[
    Compose — UI-Engine Component Library

    Composition primitives for layout and error handling.
    Includes Row, Column, Stack, Flex, Box, Padded, Centered,
    Spacer, Divider, ErrorBoundary, GetLastBounds, GetAvailableSpace.

    Dependencies: ui/utils.lua, ui/tokens.lua, modules/logger.lua
]]

---@class Compose
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- Lazy-loaded Logger
local _logger = nil

--- Initialize compose module
---@param logger Logger module reference
function M.init(logger)
    _logger = logger

    if not _logger then
        _logger = Utils.ResolveLogger("UI-Engine-Compose")
    end
end

-- Note: Row, Column, Stack, Flex, and Box were removed as no-ops.
-- Use ImGui's layout primitives (SameLine, Columns, BeginGroup) directly.


-- --- Padded ---

--- Padded layout
---@param padding Padding size in pixels or {x, y}
---@param buildFn Function that builds padded content
---@return nil
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
---@param buildFn Function that builds centered content
---@return nil
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
---@param width Spacer width (0 for horizontal, -1 for auto)
---@param height Spacer height (0 for vertical, -1 for auto)
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
---@param buildFn Function to wrap
---@param fallback Optional fallback UI function (called on error)
---@return nil
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

--- Get the total available space for the current window (used by tests).
---@return number, number width, height (both >= 0)
function M.GetAvailableSpace()
    local w, h = ImGui.GetWindowSize()
    return math.max(0, w), math.max(0, h)
end

return M
