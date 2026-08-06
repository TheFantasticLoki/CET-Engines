-- Config-Engine Built-in Category Definitions
-- Categories organize mods in the sidebar.

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

-- Icons for categories (optional, uses UI-Engine icons)
M.icons = {
    Gameplay = "settings",
    Graphics = "eye",
    Audio = "info",
    ["Quality of Life"] = "star",
    Framework = "edit",
    Uncategorized = "menu",
}

-- Default category for newly registered mods
M.defaultCategory = "Uncategorized"

return M
