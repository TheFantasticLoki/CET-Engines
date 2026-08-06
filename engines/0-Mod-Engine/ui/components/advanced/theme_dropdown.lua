--[[
    Theme Dropdown — UI-Engine Component Library

    Theme selection dropdown using ImGui Combo.
    Provides live theme switching with callback support.

    Dependencies: ImGui (CET binding)
]]

---@class ThemeDropdown
local M = {}

-- Lazy-loaded theme reference
local _theme = nil

--- Initialize with theme dependency
---@param theme Theme module reference
---@return nil
function M.init(theme)
    _theme = theme
end

--- Theme selection dropdown
---@param label Label text
---@param currentTheme Current theme name
---@param themes Array of available theme names
---@param onChange Callback function(themeName)
---@return string newTheme, boolean changed
function M.ThemeDropdown(label, currentTheme, themes, onChange)
    label = label or ""
    currentTheme = currentTheme or "Dark"
    themes = themes or {}

    local changed = false
    local newTheme = currentTheme

    if ImGui.BeginCombo(label, currentTheme) then
        for _, themeName in ipairs(themes) do
            local isSelected = (themeName == currentTheme)
            if ImGui.Selectable(themeName, isSelected) then
                newTheme = themeName
                changed = true

                if _theme and _theme.SetTheme then
                    _theme.SetTheme(themeName)
                end

                if onChange and type(onChange) == "function" then
                    onChange(themeName)
                end
            end
        end
        ImGui.EndCombo()
    end

    return newTheme, changed
end

return M
