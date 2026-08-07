--[[
    Engine Schemas — Config-Engine

    Configuration schemas for UI-Engine, Log-Engine, and Config-Engine itself.
    These schemas define what settings are available for each engine.
]]

---@class EngineSchemas
local M = {}

-- ============================================================================
-- UI-Engine Schema
-- ============================================================================

M["0-Engine-UI"] = {
    name = "UI-Engine",
    version = "v0.5.0-phase4",
    author = "0-Loki",
    description = "UI framework providing components, theming, events, and mod registration.",
    category = "Framework",
    subcategory = "UI-Engine",

    settings = {
        -- Theme
        theme_header = {
            type = "header",
            label = "Theme Settings",
        },
        currentTheme = {
            type = "combo",
            label = "Theme",
            tooltip = "Select the global UI theme",
            options = {
                "Dark", "Red", "Cyan", "Blue", "Green", "Amber",
                "Purple", "Rose", "Teal", "Midnight", "Orange",
                "Gold", "Pink", "White", "Arasaka", "Light",
            },
            default = "Dark",
        },
        accentColor = {
            type = "color",
            label = "Accent Color",
            tooltip = "Global accent color used across all UI elements",
            default = { r = 0.4, g = 0.6, b = 1.0, a = 1.0 },
            alpha = true,
        },
        contrastLevel = {
            type = "int_slider",
            label = "Contrast Level",
            tooltip = "Adjusts contrast for accessibility (1=normal, 2=high, 3=very high)",
            min = 1,
            max = 3,
            step = 1,
            default = 1,
        },

        -- Settings
        settings_header = {
            type = "header",
            label = "Settings",
        },
        autoSave = {
            type = "toggle",
            label = "Auto-Save",
            tooltip = "Automatically save settings after changes",
            default = true,
        },

        -- UI
        ui_header = {
            type = "header",
            label = "Interface",
        },
        showSidebar = {
            type = "toggle",
            label = "Show Sidebar",
            tooltip = "Show the mod list sidebar on startup",
            default = true,
        },

        -- Debug
        debug_header = {
            type = "header",
            label = "Debug",
        },
        showLoggerOverlay = {
            type = "toggle",
            label = "Show Logger Overlay",
            tooltip = "Display the logger overlay on screen",
            default = false,
        },
        maxDebugPerFrame = {
            type = "int_slider",
            label = "Max Debug Messages/Frame",
            tooltip = "Maximum debug log messages per frame",
            min = 1,
            max = 20,
            step = 1,
            default = 5,
        },
    },
}

-- ============================================================================
-- Log-Engine Schema
-- ============================================================================

M["0-Engine-Log"] = {
    name = "Log-Engine",
    version = "v1.1.0",
    author = "0-Loki",
    description = "File-based logging system with ring buffers, deduplication, and rotation.",
    category = "Framework",
    subcategory = "Log-Engine",

    settings = {
        -- Global
        global_header = {
            type = "header",
            label = "Global Settings",
        },
        globalMinLevel = {
            type = "combo",
            label = "Global Min Level",
            tooltip = "Minimum log level for all loggers",
            options = { "debug", "info", "warn", "error" },
            default = "debug",
        },

        -- Ring Buffer
        buffer_header = {
            type = "header",
            label = "Ring Buffer",
        },
        ringSize = {
            type = "int_slider",
            label = "Ring Buffer Size",
            tooltip = "Number of entries per mod logger",
            min = 256,
            max = 4096,
            step = 256,
            default = 1024,
        },

        -- File Output
        file_header = {
            type = "header",
            label = "File Output",
        },
        logDir = {
            type = "text",
            label = "Log Directory",
            tooltip = "Subdirectory for log files (relative to CET mods folder)",
            default = "logs",
        },
        maxFileSize = {
            type = "combo",
            label = "Max File Size",
            tooltip = "Maximum log file size before rotation",
            options = {
                { label = "512 KB", value = 512 * 1024 },
                { label = "1 MB", value = 1024 * 1024 },
                { label = "2 MB", value = 2 * 1024 * 1024 },
                { label = "4 MB", value = 4 * 1024 * 1024 },
            },
            default = 2 * 1024 * 1024,
        },
        maxFiles = {
            type = "int_slider",
            label = "Max Rotated Files",
            tooltip = "Number of rotated log files to keep",
            min = 1,
            max = 20,
            step = 1,
            default = 5,
        },

        -- Rate Limiting
        rate_header = {
            type = "header",
            label = "Rate Limiting",
        },
        maxDebugPerFrame = {
            type = "int_slider",
            label = "Max Debug/Frame",
            tooltip = "Maximum debug messages per frame per logger",
            min = 1,
            max = 20,
            step = 1,
            default = 1,
        },

        -- Deduplication
        dedup_header = {
            type = "header",
            label = "Deduplication",
        },
        dedupEnabled = {
            type = "toggle",
            label = "Enable Deduplication",
            tooltip = "Suppress repeated identical log messages",
            default = true,
        },
        dedupMaxEntries = {
            type = "int_slider",
            label = "Max Dedup Entries",
            tooltip = "Maximum unique messages tracked for deduplication",
            min = 64,
            max = 1024,
            step = 64,
            default = 256,
        },
    },
}

-- ============================================================================
-- Config-Engine Schema (self-configuration)
-- ============================================================================

M["0-Engine-Config"] = {
    name = "Config-Engine",
    version = "v0.1.0",
    author = "0-Loki",
    description = "Unified mod configuration manager with settings schemas, undo/redo, and presets.",
    category = "Framework",
    subcategory = "Config-Engine",

    settings = {
        -- Appearance
        appearance_header = {
            type = "header",
            label = "Appearance",
        },
        sidebarWidth = {
            type = "int_slider",
            label = "Sidebar Width",
            tooltip = "Width of the mod list sidebar in pixels",
            min = 200,
            max = 500,
            step = 10,
            default = 280,
        },
        compactMode = {
            type = "toggle",
            label = "Compact Mode",
            tooltip = "Use smaller UI elements to save space",
            default = false,
        },

        -- Behavior
        behavior_header = {
            type = "header",
            label = "Behavior",
        },
        sortMode = {
            type = "combo",
            label = "Sort Mode",
            tooltip = "How mods are sorted in the sidebar",
            options = { "name", "author", "version" },
            default = "name",
        },
        sortAscending = {
            type = "toggle",
            label = "Sort Ascending",
            tooltip = "Sort in ascending order (A→Z, oldest first)",
            default = true,
        },
        autoSaveDelay = {
            type = "slider",
            label = "Auto-Save Delay (seconds)",
            tooltip = "Seconds to wait after last change before saving",
            min = 0.5,
            max = 15.0,
            step = 0.5,
            default = 5.0,
            format = "%.1f",
        },

        -- Undo/Redo
        undo_header = {
            type = "header",
            label = "Undo/Redo",
        },
        maxUndoSteps = {
            type = "int_slider",
            label = "Max Undo Steps",
            tooltip = "Maximum number of undoable changes",
            min = 10,
            max = 200,
            step = 10,
            default = 50,
        },
        maxRedoSteps = {
            type = "int_slider",
            label = "Max Redo Steps",
            tooltip = "Maximum number of redoable changes",
            min = 10,
            max = 200,
            step = 10,
            default = 50,
        },

        -- Window
        window_header = {
            type = "header",
            label = "Window",
        },
        defaultWindowWidth = {
            type = "int_slider",
            label = "Default Window Width",
            tooltip = "Initial width of the Config-Engine window in pixels",
            min = 600,
            max = 1920,
            step = 50,
            default = 900,
        },
        defaultWindowHeight = {
            type = "int_slider",
            label = "Default Window Height",
            tooltip = "Initial height of the Config-Engine window in pixels",
            min = 400,
            max = 1080,
            step = 50,
            default = 600,
        },
    },
}

return M
