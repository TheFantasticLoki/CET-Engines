--[[
    Advanced — UI-Engine Component Library

    Advanced widgets for complex interactions.
    Includes AdvancedSlider, ThemeDropdown, ComboBox.

    Dependencies: ui/utils.lua, ui/tokens.lua, ui/theme.lua (for theme switching)
]]

local M = {}

local Utils = require("engines.UI-Engine.ui.utils")
local Tokens = require("engines.UI-Engine.ui.tokens")

-- Lazy-loaded Theme for theme switching
local _theme = nil

--- Initialize advanced module
-- @param theme Theme module reference
function M.init(theme)
    _theme = theme
end

-- --- Advanced Slider ---

--- DrawList custom slider with +/- buttons, modifier keys, tick marks, inline input
-- @param spec Slider specification table:
--   { label, value, min, max, step, format, tooltip, width, onChange }
-- @return number newValue, boolean changed
function M.AdvancedSlider(spec)
    spec = spec or {}
    local label = spec.label or ""
    local value = spec.value or 0
    local min = spec.min or 0
    local max = spec.max or 100
    local step = spec.step or 1
    local format = spec.format or "%.2f"
    local tooltip = spec.tooltip
    local width = spec.width or Tokens.SIZING.slider.width
    local onChange = spec.onChange

    -- Clamp value
    value = math.max(min, math.min(max, value))

    local changed = false
    local newValue = value

    -- Set width for the group
    ImGui.SetNextItemWidth(width)

    -- Minus button
    if ImGui.Button("-##" .. label, 24, 0) then
        newValue = math.max(min, value - step)
        changed = true
    end
    ImGui.SameLine()

    -- Display current value as text
    local display = string.format(format, value)
    Utils.SafeImGuiCall(ImGui.Text, display)
    ImGui.SameLine()

    -- Plus button
    if ImGui.Button("+##" .. label, 24, 0) then
        newValue = math.min(max, value + step)
        changed = true
    end

    -- Callback
    if changed and onChange and type(onChange) == "function" then
        onChange(newValue)
    end

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return newValue, changed
end

-- --- Theme Dropdown ---

--- Theme selector dropdown
-- @param label Label text
-- @param currentTheme Current theme name
-- @param themes Array of theme name strings
-- @param onChange Callback function(newTheme)
-- @return string newTheme, boolean changed
function M.ThemeDropdown(label, currentTheme, themes, onChange)
    label = label or ""
    currentTheme = currentTheme or "Dark"
    themes = themes or {}

    local changed = false
    local newTheme = currentTheme

    -- Begin combo
    if ImGui.BeginCombo(label, currentTheme) then
        for _, themeName in ipairs(themes) do
            local isSelected = (themeName == currentTheme)
            if ImGui.Selectable(themeName, isSelected) then
                newTheme = themeName
                changed = true

                -- Apply theme if Theme module available
                if _theme and _theme.SetTheme then
                    _theme.SetTheme(themeName)
                end

                -- Callback
                if onChange and type(onChange) == "function" then
                    onChange(themeName)
                end
            end
        end
        ImGui.EndCombo()
    end

    return newTheme, changed
end

-- --- ComboBox ---

--- Generic dropdown combo box
-- @param label Label text
-- @param items Array of display strings
-- @param selectedIndex Current selected index
-- @param onChange Callback function(newIndex, newLabel)
-- @return number newIndex, boolean changed
function M.ComboBox(label, items, selectedIndex, onChange)
    label = label or ""
    items = items or {}
    selectedIndex = selectedIndex or 1

    -- Get preview value
    local preview = items[selectedIndex] or ""

    local changed = false
    local newIndex = selectedIndex

    -- Begin combo
    if ImGui.BeginCombo(label, preview) then
        for i, item in ipairs(items) do
            local isSelected = (i == selectedIndex)
            if ImGui.Selectable(item, isSelected) then
                newIndex = i
                changed = true

                -- Callback
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
