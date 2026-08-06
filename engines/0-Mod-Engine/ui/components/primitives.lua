--[[
    Primitives — UI-Engine Component Library

    Foundational helpers used by all other components.
    Includes clipboard, selectable, context menu, and selectable entry.

    Dependencies: ui/utils.lua
]]

---@class PrimitiveComponents
local M = {}

local Utils = require("ui/utils")

-- --- Clipboard ---

--- Copy text to clipboard
---@param text Text to copy
---@return nil
function M.ClipboardCopy(text)
    if text and type(text) == "string" then
        Utils.SafeImGuiCall(ImGui.SetClipboardText, text)
    end
end

-- --- SafeSelectable ---

--- CET hover-state workaround for Selectable
---@param label Selectable label
---@param selected Whether the item is selected
---@return boolean, boolean clicked, selected
function M.SafeSelectable(label, selected)
    label = label or ""
    selected = selected or false

    local result = Utils.SafeImGuiCall(ImGui.Selectable, label, selected)
    if result then
        return result
    end
    return false, selected
end

-- --- Context Menu ---

--- Right-click context menu
---@param label Menu identifier
---@param buildFn Function that builds menu items (called while menu is open)
---@return nil
function M.ContextMenu(label, buildFn)
    label = label or "ContextMenu"
    local id = "##ctx_" .. label

    if ImGui.BeginPopupContextWindow(id) then
        if buildFn and type(buildFn) == "function" then
            buildFn()
        end
        ImGui.EndPopup()
    end
end

-- --- Selectable Entry ---

--- Selectable with tooltip
---@param label Display text
---@param selected Whether selected
---@param tooltip Tooltip text (optional)
---@return boolean clicked, boolean selected
function M.SelectableEntry(label, selected, tooltip)
    label = label or ""
    selected = selected or false

    local clicked, nowSelected = M.SafeSelectable(label, selected)

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return clicked, nowSelected
end

return M
