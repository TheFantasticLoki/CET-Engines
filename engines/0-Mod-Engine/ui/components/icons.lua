--[[
    Icons — UI-Engine Component Library

    Icon system for icon glyphs and centered text.
    Includes GetIcon, DrawCenteredText.

    Dependencies: ui/utils.lua, ui/tokens.lua
]]

---@class IconComponents
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- --- Icon Registry ---

-- Common icon mappings (can be extended)
local ICONS = {
    -- Navigation
    left_arrow = "←",
    right_arrow = "→",
    up_arrow = "↑",
    down_arrow = "↓",
    check = "✓",
    cross = "✗",
    plus = "+",
    minus = "-",

    -- Status
    info = "ℹ",
    warning = "⚠",
    error = "✗",
    success = "✓",

    -- UI
    menu = "☰",
    search = "🔍",
    settings = "⚙",
    star = "★",
    star_outline = "☆",
    heart = "♥",
    eye = "👁",

    -- Misc
    copy = "📋",
    paste = "📋",
    save = "💾",
    load = "📂",
    delete = "🗑",
    edit = "✏",
    refresh = "↻",
}

-- --- Get Icon ---

--- Get icon glyph by name
---@param name Icon name
---@return string Icon glyph or empty string
function M.GetIcon(name)
    if not name or type(name) ~= "string" then
        return ""
    end

    return ICONS[name] or ""
end

--- Register a custom icon
---@param name Icon name
---@param glyph Icon glyph
---@return nil
function M.RegisterIcon(name, glyph)
    if name and glyph then
        ICONS[name] = glyph
    end
end

--- Get all registered icon names
---@return table Array of icon names
function M.GetIconNames()
    local names = {}
    for name, _ in pairs(ICONS) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- --- Draw Centered Text ---

--- Centered text helper
---@param text Text to display
---@param size Optional font size (not directly supported by ImGui, used for calculation)
---@param color Optional color table {r, g, b}
function M.DrawCenteredText(text, size, color)
    text = text or ""
    color = color or { r = 1, g = 1, b = 1 }

    -- Get available width and text width
    local availableWidth = ImGui.GetContentRegionAvail()
    local textWidth = ImGui.CalcTextSize(text)
    local padding = (availableWidth - textWidth) / 2

    if padding > 0 then
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + padding)
    end

    Utils.SafeImGuiCall(ImGui.TextColored, color.r, color.g, color.b, 1, tostring(text))
end

return M
