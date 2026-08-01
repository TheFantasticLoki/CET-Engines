--[[
    Display — UI-Engine Component Library

    Display widgets for showing information.
    Includes Text, TextColored, TextWrapped, TextDisabled, StatusBadge,
    InfoRow, Banner, ProgressBar, Plot, Histogram, Notification.

    Dependencies: ui/utils.lua, ui/tokens.lua
]]

local M = {}

local Utils = require("engines.UI-Engine.ui.utils")
local Tokens = require("engines.UI-Engine.ui.tokens")

-- --- Text Widgets ---

--- Basic text
-- @param text Text to display
function M.Text(text)
    text = text or ""
    Utils.SafeImGuiCall(ImGui.Text, tostring(text))
end

--- Colored text
-- @param color Color table {r, g, b} (0-1 range)
-- @param text Text to display
function M.TextColored(color, text)
    color = color or { r = 1, g = 1, b = 1 }
    text = text or ""
    Utils.SafeImGuiCall(ImGui.TextColored, color.r or 1, color.g or 1, color.b or 1, 1, tostring(text))
end

--- Wrapped text
-- @param text Text to display
function M.TextWrapped(text)
    text = text or ""
    Utils.SafeImGuiCall(ImGui.TextWrapped, tostring(text))
end

--- Disabled text
-- @param text Text to display
function M.TextDisabled(text)
    text = text or ""
    Utils.SafeImGuiCall(ImGui.TextDisabled, tostring(text))
end

-- --- Status Widgets ---

--- Colored status indicator badge
-- @param label Badge text
-- @param color Background color {r, g, b} (0-1 range)
function M.StatusBadge(label, color)
    label = label or ""
    color = color or Tokens.color4n("primary")

    -- Push colored frame
    ImGui.PushStyleColor(ImGuiCol.FrameBg, color.r * 0.55, color.g * 0.55, color.b * 0.55, 0.90)
    ImGui.PushStyleColor(ImGuiCol.Text, 1, 1, 1, 1.0)

    -- Render as colored button (no interaction)
    Utils.SafeImGuiCall(ImGui.Button, label, Tokens.SIZING.badge.minWidth, Tokens.SIZING.badge.height)

    -- Pop 2 colors
    Utils.SafeImGuiCall(ImGui.PopStyleColor, 2)
end

--- Label:value pair row
-- @param label Label text
-- @param value Value text
function M.InfoRow(label, value)
    label = label or ""
    value = value or ""

    -- Render label (disabled color)
    Utils.SafeImGuiCall(ImGui.TextDisabled, tostring(label))
    ImGui.SameLine()
    -- Render value
    Utils.SafeImGuiCall(ImGui.Text, tostring(value))
end

--- Full-width notification banner
-- @param text Banner text
-- @param color Optional banner color {r, g, b} (defaults to primary)
function M.Banner(text, color)
    text = text or ""
    color = color or Tokens.color4n("primary")

    -- Push banner style
    ImGui.PushStyleColor(ImGuiCol.ChildBg, color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.90)
    ImGui.PushStyleColor(ImGuiCol.Border, color.r, color.g, color.b, 0.80)

    -- Render banner
    ImGui.BeginChild("##banner_" .. text, -1, 28, true, ImGui.WindowFlags.NoScrollbar)
    Utils.SafeImGuiCall(ImGui.Text, tostring(text))
    ImGui.EndChild()

    -- Pop 2 colors
    Utils.SafeImGuiCall(ImGui.PopStyleColor, 2)
end

-- --- Progress Widgets ---

--- Progress bar
-- @param value Progress value (0.0 - 1.0)
-- @param options Optional: {label, width, height}
function M.ProgressBar(value, options)
    value = value or 0
    options = options or {}
    local label = options.label
    local width = options.width or -1
    local height = options.height or 0

    -- Clamp value
    value = math.max(0, math.min(1, value))

    -- Format overlay text
    local overlay = label or string.format("%d%%", math.floor(value * 100))

    Utils.SafeImGuiCall(ImGui.ProgressBar, value, width, overlay)
end

-- --- Chart Widgets ---

--- Simple line plot
-- @param label Plot label
-- @param data Array of numeric values
-- @param options Optional: {min, max, width, height, tooltip}
function M.Plot(label, data, options)
    label = label or ""
    data = data or {}
    options = options or {}
    local width = options.width or -1
    local height = options.height or 100
    local tooltip = options.tooltip

    if #data == 0 then
        Utils.SafeImGuiCall(ImGui.Text, "(no data)")
        return
    end

    -- Calculate min/max if not provided
    local min = options.min
    local max = options.max
    if not min then
        min = data[1]
        for _, v in ipairs(data) do
            if v < min then min = v end
        end
    end
    if not max then
        max = data[1]
        for _, v in ipairs(data) do
            if v > max then max = v end
        end
    end
    if min == max then max = min + 1 end

    Utils.SafeImGuiCall(ImGui.PlotLines, label, data, #data, 0, nil, min, max, width, height)

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end
end

--- Histogram
-- @param label Histogram label
-- @param data Array of numeric values
-- @param options Optional: {min, max, width, height, tooltip}
function M.Histogram(label, data, options)
    label = label or ""
    data = data or {}
    options = options or {}
    local width = options.width or -1
    local height = options.height or 100
    local tooltip = options.tooltip

    if #data == 0 then
        Utils.SafeImGuiCall(ImGui.Text, "(no data)")
        return
    end

    -- Calculate min/max if not provided
    local min = options.min
    local max = options.max
    if not min then
        min = data[1]
        for _, v in ipairs(data) do
            if v < min then min = v end
        end
    end
    if not max then
        max = data[1]
        for _, v in ipairs(data) do
            if v > max then max = v end
        end
    end
    if min == max then max = min + 1 end

    Utils.SafeImGuiCall(ImGui.PlotHistogram, label, data, #data, 0, nil, min, max, width, height)

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end
end

-- --- Notification ---

-- Internal notification state
local notifications = {}

--- Popup notification system
-- @param text Notification text
-- @param type Notification type: "info", "success", "warn", "error"
-- @param duration Duration in seconds (default: 3)
function M.Notification(text, type, duration)
    text = text or ""
    type = type or "info"
    duration = duration or 3

    -- Get color based on type
    local color
    if type == "success" then
        color = Tokens.color4n("success")
    elseif type == "warn" then
        color = Tokens.color4n("favorite")
    elseif type == "error" then
        color = Tokens.color4n("secondary")
    else
        color = Tokens.color4n("primary")
    end

    -- Add to notifications list
    table.insert(notifications, {
        text = text,
        type = type,
        color = color,
        time = os.time(),
        duration = duration,
    })
end

--- Render active notifications (call once per frame)
function M.RenderNotifications()
    local now = os.time()

    -- Render and clean up expired notifications
    for i = #notifications, 1, -1 do
        local n = notifications[i]
        if (now - n.time) < n.duration then
            -- Push style
            ImGui.PushStyleColor(ImGuiCol.WindowBg, n.color.r * 0.15, n.color.g * 0.15, n.color.b * 0.15, 0.90)
            ImGui.PushStyleColor(ImGuiCol.Border, n.color.r, n.color.g, n.color.b, 0.80)

            -- Render notification
            ImGui.SetNextWindowPos(ImGui.GetIO().DisplaySize.x - 320, 60 + (i - 1) * 40, ImGuiCond.Always)
            ImGui.SetNextWindowSize(300, 36, ImGuiCond.Always)
            if ImGui.Begin("##notification_" .. i, nil,
                ImGui.WindowFlags.NoDecoration + ImGui.WindowFlags.NoFocusOnAppearing + ImGui.WindowFlags.NoNav) then
                Utils.SafeImGuiCall(ImGui.Text, n.text)
                ImGui.End()
            end

            -- Pop style
            Utils.SafeImGuiCall(ImGui.PopStyleColor, 2)
        else
            -- Remove expired notification
            table.remove(notifications, i)
        end
    end
end

return M
