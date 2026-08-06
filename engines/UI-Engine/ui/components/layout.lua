--- LayoutComponents — Layout helpers for organizing UI elements.
--- Includes RowLabel, Separator, Spacing, Indent, Unindent, Columns, ScrollableRegion.
---
--- Dependencies: ui/utils.lua
---@class LayoutComponents
local M = {}

local Utils = require("ui/utils")

-- --- Row Label ---

--- Label + value in a row
---@param label Label text
---@param value Value text
---@param options Optional: {labelWidth}
function M.RowLabel(label, value, options)
    label = label or ""
    value = value or ""
    options = options or {}

    local labelWidth = options.labelWidth or 120

    -- Render label with fixed width
    Utils.SafeImGuiCall(ImGui.Text, tostring(label))
    ImGui.SameLine(labelWidth)
    -- Render value
    Utils.SafeImGuiCall(ImGui.Text, tostring(value))
end

-- --- Separator ---

--- Optional labeled separator
---@param label Label text (nil for plain separator)
function M.Separator(label)
    if label and label ~= "" then
        Utils.SafeImGuiCall(ImGui.SeparatorText, tostring(label))
    else
        Utils.SafeImGuiCall(ImGui.Separator)
    end
end

-- --- Spacing ---

--- Vertical spacing
---@param size Optional spacing size in pixels (default: 4)
function M.Spacing(size)
    if size and size > 0 then
        Utils.SafeImGuiCall(ImGui.Dummy, 0, size)
    else
        Utils.SafeImGuiCall(ImGui.Spacing)
    end
end

-- --- Indent ---

--- Indentation
---@param depth Indentation depth in pixels (default: 16)
function M.Indent(depth)
    depth = depth or 16
    Utils.SafeImGuiCall(ImGui.Indent, depth)
end

--- Unindent
---@param depth Indentation depth in pixels (default: 16)
function M.Unindent(depth)
    depth = depth or 16
    Utils.SafeImGuiCall(ImGui.Unindent, depth)
end

-- --- Columns ---

--- Columns layout
---@param count Number of columns
---@param widths Optional array of column widths
---@param buildFn Function that builds column content
function M.Columns(count, widths, buildFn)
    count = count or 2
    widths = widths or {}

    -- Push column setup
    Utils.SafeImGuiCall(ImGui.Columns, count, nil, false)

    -- Set column widths if provided
    for i, width in ipairs(widths) do
        if i <= count then
            Utils.SafeImGuiCall(ImGui.SetColumnWidth, i - 1, width)
        end
    end

    -- Build content
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end

    -- Reset columns
    Utils.SafeImGuiCall(ImGui.Columns, 1, nil, false)
end

-- --- Scrollable Region ---

--- Scrollable region
---@param height Region height in pixels
---@param buildFn Function that builds region content
---@param options Optional: {flags}
function M.ScrollableRegion(height, buildFn, options)
    height = height or 200
    options = options or {}
    local flags = options.flags or 0

    -- Begin scrollable child
    Utils.SafeImGuiCall(ImGui.BeginChild, "##scroll_region", -1, height, false, flags)

    -- Build content
    if buildFn and type(buildFn) == "function" then
        buildFn()
    end

    -- End scrollable child
    Utils.SafeImGuiCall(ImGui.EndChild)
end

return M
