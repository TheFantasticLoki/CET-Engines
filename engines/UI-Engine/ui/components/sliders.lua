--- SliderComponents — Slider widgets for numeric value adjustment.
--- Includes SliderFloat, SliderInt, DragInt, DragFloat, StepSlider, ColorPicker.
---
--- Dependencies: ui/utils.lua, ui/tokens.lua
---@class SliderComponents
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- --- SliderFloat ---

--- Float slider
---@param label Label text
---@param value Current float value
---@param options Optional: {min, max, format, tooltip, width}
---@return number newValue, boolean changed
function M.SliderFloat(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local min = options.min or 0
    local max = options.max or 1
    local format = options.format or "%.2f"
    local width = options.width or Tokens.SIZING.slider.width

    -- Clamp value
    value = math.max(min, math.min(max, value))

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    local changed, newValue = Utils.SafeImGuiCall(ImGui.SliderFloat, label, value, min, max, format, options.flags or 0)

    if not changed then
        newValue = value
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newValue, changed
end

-- --- SliderInt ---

--- Integer slider
---@param label Label text
---@param value Current integer value
---@param options Optional: {min, max, format, tooltip, width}
---@return number newValue, boolean changed
function M.SliderInt(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local min = options.min or 0
    local max = options.max or 100
    local format = options.format or "%d"
    local width = options.width or Tokens.SIZING.slider.width

    -- Clamp value
    value = math.max(min, math.min(max, value))

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    local changed, newValue = Utils.SafeImGuiCall(ImGui.SliderInt, label, value, min, max, format, options.flags or 0)

    if not changed then
        newValue = value
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newValue, changed
end

-- --- DragInt ---

--- Integer drag
---@param label Label text
---@param value Current integer value
---@param options Optional: {min, max, speed, tooltip, width}
---@return number newValue, boolean changed
function M.DragInt(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local min = options.min or -1000
    local max = options.max or 1000
    local speed = options.speed or 1
    local width = options.width or Tokens.SIZING.slider.width

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    local changed, newValue = Utils.SafeImGuiCall(ImGui.DragInt, label, value, speed, min, max, options.format or "%d", options.flags or 0)

    if not changed then
        newValue = value
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newValue, changed
end

-- --- DragFloat ---

--- Float drag
---@param label Label text
---@param value Current float value
---@param options Optional: {min, max, speed, format, tooltip, width}
---@return number newValue, boolean changed
function M.DragFloat(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local min = options.min or -1000
    local max = options.max or 1000
    local speed = options.speed or 0.1
    local format = options.format or "%.3f"
    local width = options.width or Tokens.SIZING.slider.width

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    local changed, newValue = Utils.SafeImGuiCall(ImGui.DragFloat, label, value, speed, min, max, format, options.flags or 0)

    if not changed then
        newValue = value
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newValue, changed
end

-- --- StepSlider ---

--- Fixed-width slider with +/- buttons
---@param label Label text
---@param value Current value
---@param options Optional: {min, max, step, format, tooltip, width}
---@return number newValue, boolean changed
function M.StepSlider(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local min = options.min or 0
    local max = options.max or 100
    local step = options.step or 1
    local format = options.format or "%d"
    local width = options.width or Tokens.SIZING.slider.width

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

    -- Display current value
    local display = string.format(format, value)
    Utils.SafeImGuiCall(ImGui.Text, display)
    ImGui.SameLine()

    -- Plus button
    if ImGui.Button("+##" .. label, 24, 0) then
        newValue = math.min(max, value + step)
        changed = true
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newValue, changed
end

-- --- ColorPicker ---

--- Color picker
---@param label Label text
---@param color Current color {r, g, b, a} (0-1 range)
---@param options Optional: {tooltip, flags, width}
---@return table newColor, boolean changed
function M.ColorPicker(label, color, options)
    label = label or ""
    color = color or { r = 1, g = 1, b = 1, a = 1 }
    options = options or {}
    local width = options.width or Tokens.SIZING.slider.width

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    -- ImGui expects array-style color
    local colorArr = { color.r or 1, color.g or 1, color.b or 1, color.a or 1 }

    local changed, newColor = Utils.SafeImGuiCall(ImGui.ColorEdit4, label, colorArr, options.flags or 0)

    local result = { r = color.r, g = color.g, b = color.b, a = color.a }

    if changed and newColor then
        result = {
            r = newColor[1],
            g = newColor[2],
            b = newColor[3],
            a = newColor[4],
        }
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return result, changed
end

return M
