--[[
    Tables — UI-Engine Component Library

    Table wrapper for tabular data.
    Includes BeginTable wrapper.

    Dependencies: ui/utils.lua
]]

local M = {}

local Utils = require("ui.utils")

-- --- Begin Table ---

--- Thin wrapper for ImGui.BeginTable
-- @param id Table identifier
-- @param columns Number of columns
-- @param options Optional: {flags, outerSize, innerWidth}
-- @return boolean isOpen
function M.BeginTable(id, columns, options)
    id = id or "##table"
    columns = columns or 2
    options = options or {}

    local flags = options.flags or 0
    local outerSize = options.outerSize or { 0, 0 }
    local innerWidth = options.innerWidth or 0

    return Utils.SafeImGuiCall(ImGui.BeginTable, id, columns, flags, outerSize.x or 0, innerSize or innerWidth)
end

--- End table
function M.EndTable()
    Utils.SafeImGuiCall(ImGui.EndTable)
end

--- Render a table row
-- @param cells Array of cell values
-- @param widths Optional array of column widths
function M.TableRow(cells, widths)
    cells = cells or {}
    widths = widths or {}

    for i, cell in ipairs(cells) do
        Utils.SafeImGuiCall(ImGui.TableNextColumn)
        Utils.SafeImGuiCall(ImGui.Text, tostring(cell))
    end
end

return M
