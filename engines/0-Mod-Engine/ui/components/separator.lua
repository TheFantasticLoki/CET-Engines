--[[
    Separator — UI-Engine Component Library

    Rich, configurable separator with theme compliance.
    Supports both ImGui widget mode and DrawList rendering (for tooltips).

    Features:
    - Plain line separator
    - Labeled separator (text with lines on both sides)
    - Icon separator (icon centered between lines)
    - Gradient separator (color transition)
    - Dotted/dashed separator
    - Thickness, height, padding, color all configurable
    - Theme-aware (resolves colors from Tokens)

    Dependencies: ui/utils.lua, ui/tokens.lua
    CET Constraints: No pcall on ImGui calls, Lua 5.1 only
]]

---@class Separator
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- ============================================================================
-- Default Styling
-- ============================================================================

local DEFAULTS = {
    -- Line
    thickness = 1,
    color = "panel",          -- Token role name
    alpha = 0.4,
    width = -1,              -- -1 = full available width

    -- Labeled
    labelColor = "muted",
    labelAlpha = 0.6,
    labelPadding = 8,        -- Horizontal padding around label text
    labelGap = 8,            -- Gap between label and lines
    fontSize = 0,            -- 0 = default font size

    -- Icon
    iconSize = 16,
    iconColor = "primary",
    iconAlpha = 0.7,

    -- Spacing
    paddingBefore = 0,       -- Vertical space before separator
    paddingAfter = 0,        -- Vertical space after separator

    -- Gradient (optional)
    gradientStart = nil,     -- {r, g, b} or role string
    gradientEnd = nil,       -- {r, g, b} or role string
    gradientAlpha = 0.5,
}

-- ============================================================================
-- Color Helpers
-- ============================================================================

--- Resolve a color option (string role, {r,g,b} table, or nil fallback)
---@param colorOpt string|table|nil Color option
---@param defaultRole string Default token role
---@param defaultAlpha number Default alpha
---@return number, number, number, number r, g, b, a (0-1)
local function resolveColor(colorOpt, defaultRole, defaultAlpha)
    if colorOpt == nil then
        local c = Tokens.color4n(defaultRole)
        return c.r, c.g, c.b, defaultAlpha
    end
    if type(colorOpt) == "string" then
        local c = Tokens.color4n(colorOpt)
        return c.r, c.g, c.b, defaultAlpha
    end
    if type(colorOpt) == "table" then
        return colorOpt.r or 0.5, colorOpt.g or 0.5, colorOpt.b or 0.5, defaultAlpha
    end
    return 0.5, 0.5, 0.5, defaultAlpha
end

--- Pack RGBA into ImGui uint32
---@return number Packed color
local function packRGBA(r, g, b, a)
    r = math.max(0, math.min(1, r or 0.5))
    g = math.max(0, math.min(1, g or 0.5))
    b = math.max(0, math.min(1, b or 0.5))
    a = math.max(0, math.min(1, a or 1))
    local ri = math.floor(r * 255 + 0.5)
    local gi = math.floor(g * 255 + 0.5)
    local bi = math.floor(b * 255 + 0.5)
    local ai = math.floor(a * 255 + 0.5)
    return ai * 16777216 + bi * 65536 + gi * 256 + ri
end

--- Interpolate two colors
---@return number, number, number r, g, b
local function lerpColor(r1, g1, b1, r2, g2, b2, t)
    return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t
end

-- ============================================================================
-- ImGui Widget Separator
-- ============================================================================

--- Draw a separator as an ImGui widget (inside a BeginChild/Begin group)
---@param opts table|nil Options:
---   label: string (text label between lines)
---   icon: string (icon name between lines)
---   thickness: number (line thickness, default 1)
---   color: string|table (token role or {r,g,b}, default "panel")
---   alpha: number (0-1, default 0.4)
---   width: number (-1 for full width)
---   labelColor: string (token role for label, default "muted")
---   labelAlpha: number (label alpha, default 0.6)
---   labelPadding: number (horizontal padding around label, default 8)
---   labelGap: number (gap between label and lines, default 8)
---   iconSize: number (icon size, default 16)
---   iconColor: string (token role for icon, default "primary")
---   iconAlpha: number (icon alpha, default 0.7)
---   paddingBefore: number (space before, default 0)
---   paddingAfter: number (space after, default 0)
---   gradientStart: string|table (left color, default = color)
---   gradientEnd: string|table (right color, default = color)
---   gradientAlpha: number (gradient alpha, default 0.5)
function M.Separator(opts)
    opts = opts or {}

    -- Merge with defaults
    local thickness = opts.thickness or DEFAULTS.thickness
    local colorR, colorG, colorB, colorA = resolveColor(opts.color, DEFAULTS.color, opts.alpha or DEFAULTS.alpha)
    local label = opts.label
    local icon = opts.icon

    -- Spacing
    if opts.paddingBefore and opts.paddingBefore > 0 then
        ImGui.Spacing(opts.paddingBefore)
    end

    if label and label ~= "" then
        -- Labeled separator: line — text — line
        local labelR, labelG, labelB, labelA = resolveColor(opts.labelColor, DEFAULTS.labelColor, opts.labelAlpha or DEFAULTS.labelAlpha)
        local labelPadding = opts.labelPadding or DEFAULTS.labelPadding
        local labelGap = opts.labelGap or DEFAULTS.labelGap

        -- Calculate available width
        local availW = ImGui.GetContentRegionAvail()
        local textW = ImGui.CalcTextSize(label)
        local totalNeeded = textW + labelPadding * 2 + labelGap * 2
        local lineW = math.max(0, (availW - totalNeeded) / 2)

        -- Left line
        ImGui.SameLine(0, 0)
        local lx = ImGui.GetCursorScreenPos()
        local drawList = ImGui.GetWindowDrawList()
        if drawList then
            local packed = packRGBA(colorR, colorG, colorB, colorA)
            ImGui.ImDrawListAddLine(drawList, lx, lx + 0.5, lx + lineW, lx + 0.5, packed, thickness)
        end

        -- Label
        ImGui.SameLine(0, labelGap)
        ImGui.TextColored(labelR, labelG, labelB, labelA, label)

        -- Right line
        ImGui.SameLine(0, labelGap)
        local rx = ImGui.GetCursorScreenPos()
        if drawList then
            local packed = packRGBA(colorR, colorG, colorB, colorA)
            ImGui.ImDrawListAddLine(drawList, rx, rx + 0.5, rx + lineW, rx + 0.5, packed, thickness)
        end

        ImGui.Spacing()

    elseif icon and icon ~= "" then
        -- Icon separator: line — icon — line
        local iconR, iconG, iconB, iconA = resolveColor(opts.iconColor, DEFAULTS.iconColor, opts.iconAlpha or DEFAULTS.iconAlpha)
        local iconSize = opts.iconSize or DEFAULTS.iconSize
        local iconGap = opts.labelGap or DEFAULTS.labelGap

        local availW = ImGui.GetContentRegionAvail()
        local iconW = iconSize
        local totalNeeded = iconW + iconGap * 2
        local lineW = math.max(0, (availW - totalNeeded) / 2)

        -- Left line
        ImGui.SameLine(0, 0)
        local lx = ImGui.GetCursorScreenPos()
        local drawList = ImGui.GetWindowDrawList()
        if drawList then
            local packed = packRGBA(colorR, colorG, colorB, colorA)
            ImGui.ImDrawListAddLine(drawList, lx, lx + 0.5, lx + lineW, lx + 0.5, packed, thickness)
        end

        -- Icon
        ImGui.SameLine(0, iconGap)
        ImGui.TextColored(iconR, iconG, iconB, iconA, icon)

        -- Right line
        ImGui.SameLine(0, iconGap)
        local rx = ImGui.GetCursorScreenPos()
        if drawList then
            local packed = packRGBA(colorR, colorG, colorB, colorA)
            ImGui.ImDrawListAddLine(drawList, rx, rx + 0.5, rx + lineW, rx + 0.5, packed, thickness)
        end

        ImGui.Spacing()

    else
        -- Plain separator (full width line)
        ImGui.Separator()
    end

    -- Spacing
    if opts.paddingAfter and opts.paddingAfter > 0 then
        ImGui.Spacing(opts.paddingAfter)
    end
end

-- ============================================================================
-- DrawList Separator (for tooltips and custom rendering)
-- ============================================================================

--- Draw a separator via DrawList at specified position
---@param drawList DrawList userdata
---@param x number Start X
---@param y number Center Y
---@param width number Line width
---@param opts table|nil Options (same as M.Separator plus):
---   gradientStart: string|table (left color)
---   gradientEnd: string|table (right color)
---   gradientAlpha: number (default 0.5)
function M.DrawListSeparator(drawList, x, y, width, opts)
    if not drawList then return end
    opts = opts or {}

    local thickness = opts.thickness or DEFAULTS.thickness
    local colorR, colorG, colorB, colorA = resolveColor(opts.color, DEFAULTS.color, opts.alpha or DEFAULTS.alpha)
    local halfH = thickness / 2

    -- Check for gradient
    local gradStart = opts.gradientStart
    local gradEnd = opts.gradientEnd

    if gradStart or gradEnd then
        -- Gradient separator
        local startR, startG, startB = resolveColor(gradStart or opts.color, DEFAULTS.color, opts.gradientAlpha or DEFAULTS.alpha)
        local endR, endG, endB = resolveColor(gradEnd or opts.color, DEFAULTS.color, opts.gradientAlpha or DEFAULTS.alpha)
        local segments = math.max(1, math.floor(width / 4)) -- 4px per segment
        local segW = width / segments
        for i = 0, segments - 1 do
            local t = i / segments
            local r, g, b = lerpColor(startR, startG, startB, endR, endG, endB, t)
            local packed = packRGBA(r, g, b, colorA)
            ImGui.ImDrawListAddLine(drawList, x + i * segW, y, x + (i + 1) * segW, y, packed, thickness)
        end
    else
        -- Solid color separator
        local packed = packRGBA(colorR, colorG, colorB, colorA)
        ImGui.ImDrawListAddLine(drawList, x, y, x + width, y, packed, thickness)
    end
end

--- Draw a labeled separator via DrawList
---@param drawList DrawList userdata
---@param x number Start X
---@param y number Center Y
---@param width number Total width
---@param label string Label text
---@param opts table|nil Options
function M.DrawListLabeledSeparator(drawList, x, y, width, label, opts)
    if not drawList then return end
    opts = opts or {}

    local thickness = opts.thickness or DEFAULTS.thickness
    local colorR, colorG, colorB, colorA = resolveColor(opts.color, DEFAULTS.color, opts.alpha or DEFAULTS.alpha)
    local labelR, labelG, labelB, labelA = resolveColor(opts.labelColor, DEFAULTS.labelColor, opts.labelAlpha or DEFAULTS.labelAlpha)
    local labelPadding = opts.labelPadding or DEFAULTS.labelPadding
    local labelGap = opts.labelGap or DEFAULTS.labelGap

    local textW = ImGui.CalcTextSize(label)
    local totalNeeded = textW + labelPadding * 2 + labelGap * 2
    local lineW = math.max(0, (width - totalNeeded) / 2)

    -- Left line
    local packed = packRGBA(colorR, colorG, colorB, colorA)
    ImGui.ImDrawListAddLine(drawList, x, y, x + lineW, y, packed, thickness)

    -- Label
    local labelX = x + lineW + labelGap + labelPadding
    local labelPacked = packRGBA(labelR, labelG, labelB, labelA)
    ImGui.ImDrawListAddText(drawList, labelX, y - 6, labelPacked, label) -- -6 for vertical centering

    -- Right line
    local rightX = labelX + textW + labelPadding + labelGap
    ImGui.ImDrawListAddLine(drawList, rightX, y, x + width, y, packed, thickness)
end

-- ============================================================================
-- Tooltip Separator Helper
-- ============================================================================

--- Draw a separator line suitable for tooltip content.
--- Automatically sizes to tooltip width and uses theme colors.
---@param drawList DrawList userdata
---@param x number Left edge X
---@param y number Center Y
---@param width number Tooltip content width
---@param opts table|nil Options
function M.TooltipSeparator(drawList, x, y, width, opts)
    M.DrawListSeparator(drawList, x, y, width, opts or {
        color = "panel",
        alpha = 0.3,
        thickness = 1,
    })
end

-- ============================================================================
-- Module API
-- ============================================================================

--- Get default separator options
---@return table defaults
function M.getDefaults()
    local copy = {}
    for k, v in pairs(DEFAULTS) do
        copy[k] = v
    end
    return copy
end

return M
