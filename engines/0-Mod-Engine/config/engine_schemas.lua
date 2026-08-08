--[[
    Engine Schemas — Config-Engine

    Configuration schemas for UI-Engine, Log-Engine, and Config-Engine itself.
    These schemas define what settings are available for each engine.

    Supported types:
    - Basic: toggle, slider, int_slider, combo, text, number, color, keybind, header, group, info, button
    - Layout: section (wraps settings in a SectionCard), divider, spacer
    - Custom: custom (calls a render function for full ImGui control)

    Section type groups settings into styled cards with titles.
    Custom type allows full ImGui control while staying in the schema system.
]]

---@class EngineSchemas
local M = {}

-- ============================================================================
-- UI-Engine Schema
-- ============================================================================

M["0-Engine-UI"] = {
    name = "UI-Engine",
    version = "v0.3.2",
    author = "The Fantastic loki",
    description = "UI framework providing components, theming, events, and mod registration.",
    category = "Framework",
    subcategory = "Engine",

    settings = {
        theme_section = {
            type = "section",
            label = "THEME",
            settings = {
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
                contrastLevel = {
                    type = "int_slider",
                    label = "Contrast Level",
                    tooltip = "Adjusts contrast for accessibility (1=normal, 2=high, 3=very high)",
                    min = 1,
                    max = 3,
                    step = 1,
                    default = 1,
                },
            },
        },
    },
}

-- ============================================================================
-- Log-Engine Schema
-- ============================================================================

M["0-Engine-Log"] = {
    name = "Log-Engine",
    version = "v0.2.0", -- Update in log/init.lua as well
    author = "The Fantastic loki",
    description = "File-based logging system with ring buffers, deduplication, and rotation.",
    category = "Framework",
    subcategory = "Engine",

    settings = {
        global_section = {
            type = "section",
            label = "GLOBAL",
            settings = {
                globalMinLevel = {
                    type = "combo",
                    label = "Minimum Log Level",
                    tooltip = "Minimum log level for all loggers",
                    options = { "debug", "info", "warn", "error" },
                    default = "debug",
                },
            },
        },
        buffer_section = {
            type = "section",
            label = "RING BUFFER",
            settings = {
                ringSize = {
                    type = "int_slider",
                    label = "Buffer Size",
                    tooltip = "Number of entries per mod logger",
                    min = 256,
                    max = 4096,
                    step = 256,
                    default = 1024,
                },
                maxDebugPerFrame = {
                    type = "int_slider",
                    label = "Max Debug Messages / Frame",
                    tooltip = "Maximum debug messages per frame per logger",
                    min = 1,
                    max = 20,
                    step = 1,
                    default = 1,
                },
            },
        },
        file_section = {
            type = "section",
            label = "FILE OUTPUT",
            settings = {
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
            },
        },
        dedup_section = {
            type = "section",
            label = "DEDUPLICATION",
            settings = {
                dedupEnabled = {
                    type = "toggle",
                    label = "Enable Deduplication",
                    tooltip = "Suppress repeated identical log messages",
                    default = true,
                },
                dedupMaxEntries = {
                    type = "int_slider",
                    label = "Max Tracked Entries",
                    tooltip = "Maximum unique messages tracked for deduplication",
                    min = 64,
                    max = 1024,
                    step = 64,
                    default = 256,
                },
            },
        },
    },
}

-- ============================================================================
-- Config-Engine Schema (self-configuration)
-- ============================================================================

M["0-Engine-Config"] = {
    name = "Config-Engine",
    version = "v0.3.0",
    author = "The Fantastic loki",
    description = "Unified mod configuration manager with settings schemas, undo/redo, and presets.",
    category = "Framework",
    subcategory = "Engine",

    settings = {
        behavior_section = {
            type = "section",
            label = "BEHAVIOR",
            settings = {
                showSidebar = {
                    type = "toggle",
                    label = "Show Sidebar",
                    tooltip = "Show the mod list sidebar on startup",
                    default = true,
                },
                autoSave = {
                    type = "toggle",
                    label = "Auto-Save Settings",
                    tooltip = "Automatically save settings after changes",
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
            },
        },
        window_section = {
            type = "section",
            label = "WINDOW",
            settings = {
                sidebarWidth = {
                    type = "int_slider",
                    label = "Sidebar Width",
                    tooltip = "Width of the mod list sidebar in pixels",
                    min = 200,
                    max = 500,
                    step = 10,
                    default = 280,
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
        },
    },
}

return M
