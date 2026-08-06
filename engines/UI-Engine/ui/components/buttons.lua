--- ButtonComponents — Button widgets for user interaction.
--- Includes themed Button, ToggleButton (ON/OFF with color), and IconButton.
---
--- Dependencies: ui/utils.lua, ui/tokens.lua
---@class ButtonComponents
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- --- Button ---

--- Themed button
---@param label Button text
---@param options Optional: {width, height, tooltip}
---@return boolean clicked
function M.Button(label, options)
    label = label or ""
    options = options or {}

    local width = options.width or Tokens.SIZING.button.width
    local height = options.height or Tokens.SIZING.button.height
    local tooltip = options.tooltip

    local clicked = Utils.SafeImGuiCall(ImGui.Button, label, width, height)

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return clicked
end

-- --- ToggleButton ---

--- ON/OFF toggle with color-coded state
---@param label Button text
---@param value Current ON/OFF state
---@param options Optional: {tooltip}
---@return boolean newValue, boolean changed
function M.ToggleButton(label, value, options)
    label = label or ""
    value = value or false
    options = options or {}
    local tooltip = options.tooltip

    -- Get themed colors
    local primaryColor = Tokens.color4n("primary")
    local mutedColor = Tokens.color4n("muted")

    -- Push button style based on state
    if value then
        -- ON: primary color
        ImGui.PushStyleColor(ImGuiCol.Button, primaryColor.r * 0.38, primaryColor.g * 0.38, primaryColor.b * 0.38, 0.96)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, primaryColor.r * 0.82, primaryColor.g * 0.82, primaryColor.b * 0.82, 1.0)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, primaryColor.r, primaryColor.g, primaryColor.b, 1.0)
    else
        -- OFF: muted color
        ImGui.PushStyleColor(ImGuiCol.Button, mutedColor.r * 0.38, mutedColor.g * 0.38, mutedColor.b * 0.38, 0.96)
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, mutedColor.r * 0.82, mutedColor.g * 0.82, mutedColor.b * 0.82, 1.0)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, mutedColor.r, mutedColor.g, mutedColor.b, 1.0)
    end

    local clicked = Utils.SafeImGuiCall(ImGui.Button, label, Tokens.SIZING.toggle.width, Tokens.SIZING.toggle.height)

    -- Pop 3 style colors
    Utils.SafeImGuiCall(ImGui.PopStyleColor, 3)

    local newValue = value
    local changed = false

    if clicked then
        newValue = not value
        changed = true
    end

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return newValue, changed
end

-- --- IconButton ---

--- Icon-only button
---@param icon Icon text/glyph
---@param options Optional: {size, tooltip}
---@return boolean clicked
function M.IconButton(icon, options)
    icon = icon or ""
    options = options or {}

    local size = options.size or Tokens.SIZING.button.height
    local tooltip = options.tooltip

    local clicked = Utils.SafeImGuiCall(ImGui.Button, icon, size, size)

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return clicked
end

return M
