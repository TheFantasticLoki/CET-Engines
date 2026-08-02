--[[
    Inputs — UI-Engine Component Library

    Input widgets for user data entry.
    Includes Checkbox, RadioButton, InputText, InputInt, InputFloat, KeyBind.

    Dependencies: ui/utils.lua, ui/tokens.lua
]]

local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- --- Checkbox ---

--- Checkbox
-- @param label Label text
-- @param value Current boolean value
-- @param options Optional: {tooltip}
-- @return boolean newValue, boolean changed
function M.Checkbox(label, value, options)
    label = label or ""
    value = value or false
    options = options or {}

    local clicked, newVal = Utils.SafeImGuiCall(ImGui.Checkbox, label, value)
    local changed = clicked and (newVal ~= value)

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newVal, changed
end

-- --- RadioButton ---

--- Radio button
-- @param label Label text
-- @param active Whether this radio is currently active
-- @param options Optional: {tooltip}
-- @return boolean clicked, boolean active
function M.RadioButton(label, active, options)
    label = label or ""
    active = active or false
    options = options or {}

    local clicked, isActive = Utils.SafeImGuiCall(ImGui.RadioButton, label, active)

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return clicked, isActive
end

-- --- InputText ---

--- Text input
-- @param label Label text
-- @param value Current string value
-- @param options Optional: {placeholder, tooltip, flags, width}
-- @return string newValue, boolean changed
function M.InputText(label, value, options)
    label = label or ""
    value = value or ""
    options = options or {}
    local placeholder = options.placeholder
    local tooltip = options.tooltip
    local flags = options.flags or 0
    local width = options.width or Tokens.SIZING.input.width

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    -- Use hint variant if placeholder provided
    local changed, newValue
    if placeholder and placeholder ~= "" then
        changed, newValue = Utils.SafeImGuiCall(ImGui.InputTextWithHint, label, placeholder, value, flags, nil, nil)
    else
        changed, newValue = Utils.SafeImGuiCall(ImGui.InputText, label, value, flags, nil, nil)
    end

    if not changed then
        newValue = value
    end

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return newValue, changed
end

-- --- InputInt ---

--- Integer input
-- @param label Label text
-- @param value Current integer value
-- @param options Optional: {tooltip, step, stepFast, width}
-- @return number newValue, boolean changed
function M.InputInt(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local tooltip = options.tooltip
    local step = options.step or 1
    local stepFast = options.stepFast or 10
    local width = options.width or Tokens.SIZING.input.width

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    local changed, newValue = Utils.SafeImGuiCall(ImGui.InputInt, label, value, step, stepFast, options.flags or 0)

    if not changed then
        newValue = value
    end

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return newValue, changed
end

-- --- InputFloat ---

--- Float input
-- @param label Label text
-- @param value Current float value
-- @param options Optional: {tooltip, step, stepFast, format, width}
-- @return number newValue, boolean changed
function M.InputFloat(label, value, options)
    label = label or ""
    value = value or 0
    options = options or {}
    local tooltip = options.tooltip
    local step = options.step or 0.1
    local stepFast = options.stepFast or 1.0
    local format = options.format or "%.3f"
    local width = options.width or Tokens.SIZING.input.width

    -- Set width if specified
    if width > 0 then
        ImGui.SetNextItemWidth(width)
    end

    local changed, newValue = Utils.SafeImGuiCall(ImGui.InputFloat, label, value, step, stepFast, format, options.flags or 0)

    if not changed then
        newValue = value
    end

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return newValue, changed
end

-- --- KeyBind ---

--- Key binding
-- @param label Label text
-- @param key Current key name
-- @param options Optional: {tooltip}
-- @return string newKey, boolean changed
function M.KeyBind(label, key, options)
    label = label or ""
    key = key or "None"
    options = options or {}

    -- Render as selectable that captures key
    local display = label .. ": " .. key
    local clicked = Utils.SafeImGuiCall(ImGui.Button, display)

    local newKey = key
    local changed = false

    if clicked then
        -- In a real implementation, this would open a key capture dialog
        -- For now, we just toggle to a placeholder
        if key == "None" then
            newKey = "F1"
        else
            newKey = "None"
        end
        changed = true
    end

    if options.tooltip and options.tooltip ~= "" then
        Utils.Tooltip(options.tooltip)
    end

    return newKey, changed
end

return M
