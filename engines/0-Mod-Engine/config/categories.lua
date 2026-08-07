-- Config-Engine Built-in Category Definitions
-- Categories organize mods in the sidebar.

---@class Categories
local M = {}

-- Ordered list of top-level categories
M.order = {
    "Gameplay",
    "Graphics",
    "Audio",
    "Quality of Life",
    "Framework",
    "Uncategorized",
}

-- Subcategories per top-level category
M.subcategories = {
    Gameplay = { "Combat", "Movement", "Skills", "Economy", "AI" },
    Graphics = { "Post-Processing", "Lighting", "Textures", "UI/HUD", "Weather" },
    Audio = { "Music", "SFX", "Voice", "Ambience" },
    ["Quality of Life"] = { "Inventory", "Crafting", "Navigation", "Interface" },
    Framework = { "UI-Engine", "Config-Engine", "Libraries", "Utilities" },
    Uncategorized = {},
}

-- Icons for categories (IconGlyphs names from Material Design Icons)
-- Rendered via ImDrawListAddText to bypass font glyph limitations.
M.icons = {
    Gameplay = "GamepadVariant",
    Graphics = "Palette",
    Audio = "VolumeHigh",
    ["Quality of Life"] = "LightbulbOutline",
    Framework = "PuzzleOutline",
    Uncategorized = "DotsHorizontal",
    Development = "CodeTags",
    ["UI/HUD"] = "MonitorDashboard",
}

-- Default category for newly registered mods
M.defaultCategory = "Uncategorized"

return M
