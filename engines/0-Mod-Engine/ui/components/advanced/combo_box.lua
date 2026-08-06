--[[
    ComboBox — UI-Engine Component Library

    Generic dropdown combo box using ImGui Combo.
    Provides selection from a list of items with callback support.

    Dependencies: ImGui (CET binding)
]]

---@class ComboBox
local M = {}

--- Generic dropdown combo box
---@param label Label text
---@param items Array of display strings
---@param selectedIndex Current selected index
---@param onChange Callback function(newIndex, newLabel)
---@return number newIndex, boolean changed
function M.ComboBox(label, items, selectedIndex, onChange)
    label = label or ""
    items = items or {}
    selectedIndex = selectedIndex or 1

    local preview = items[selectedIndex] or ""
    local changed = false
    local newIndex = selectedIndex

    if ImGui.BeginCombo(label, preview) then
        for i, item in ipairs(items) do
            local isSelected = (i == selectedIndex)
            if ImGui.Selectable(item, isSelected) then
                newIndex = i
                changed = true

                if onChange and type(onChange) == "function" then
                    onChange(i, item)
                end
            end
        end
        ImGui.EndCombo()
    end

    return newIndex, changed
end

return M
