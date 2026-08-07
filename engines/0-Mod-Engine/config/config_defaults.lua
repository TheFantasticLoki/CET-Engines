-- Config-Engine Default Configuration
-- These values are used when no saved state exists.

local M = {}

M.DEFAULT_THEME = "Dark"
M.DEFAULT_ACCENT = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 }
M.DEFAULT_SIDEBAR_WIDTH = 280
M.DEFAULT_SORT_MODE = "name"
M.DEFAULT_COMPACT_MODE = false

-- Auto-save: seconds between last change and persist
M.AUTO_SAVE_DELAY_SECS = 5.0

-- Undo/Redo
M.MAX_UNDO_STEPS = 50
M.MAX_REDO_STEPS = 50
M.CHECKPOINT_INTERVAL = 10

-- Storage paths (relative to CET mods directory)
M.STORAGE_DIR = "configengine"
M.MODS_DIR = "mods"
M.PRESETS_DIR = "presets"
M.COLLECTIONS_DIR = "collections"
M.UI_STATE_FILE = "ui.json"
M.CATEGORIES_FILE = "categories.json"
M.VERSION_FILE = "version.json"

-- Schema
M.CURRENT_SCHEMA_VERSION = 1

-- UI
M.MIN_SIDEBAR_WIDTH = 200
M.MAX_SIDEBAR_WIDTH = 500
M.DEFAULT_WINDOW_WIDTH = 900
M.DEFAULT_WINDOW_HEIGHT = 600

return M
