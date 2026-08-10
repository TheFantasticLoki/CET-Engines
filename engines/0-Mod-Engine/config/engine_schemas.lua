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

    -- Tests for this engine (run via diagnostics panel)
    tests = {
        full = function(ctx)
            local Core = ctx.core
            local assert = {
                equal = function(actual, expected, msg)
                    if actual ~= expected then
                        error((msg or "assert.equal") ..
                            " expected " .. tostring(expected) ..
                            " got " .. tostring(actual))
                    end
                end,
                not_nil = function(val, msg)
                    if val == nil then
                        error((msg or "assert.not_nil") .. " expected not nil")
                    end
                end,
                true_ = function(val, msg)
                    if not val then
                        error((msg or "assert.true_") .. " expected truthy, got " .. tostring(val))
                    end
                end,
                false_ = function(val, msg)
                    if val then
                        error((msg or "assert.false_") .. " expected falsy, got " .. tostring(val))
                    end
                end,
            }

            local passed = 0
            local failed = 0
            local testResults = {}

            local function test(name, fn)
                local ok, err = pcall(fn)
                if ok then
                    passed = passed + 1
                    table.insert(testResults, { name = name, passed = true, error = nil })
                else
                    failed = failed + 1
                    table.insert(testResults, { name = name, passed = false, error = tostring(err) })
                    -- Log error to spdlog (always available, no dependencies)
                    if spdlog then
                        spdlog.error("[UI-Engine Test] " .. name .. ": " .. tostring(err))
                    end
                end
            end

            -- SAVE STATE before tests (CRITICAL - don't destroy mods!)
            local snapshot = Core.snapshot()

            -- Test: UI-Engine Core functions exist
            test("core: getCurrentTheme exists", function()
                assert.not_nil(Core.getCurrentTheme)
            end)

            test("core: setCurrentTheme exists", function()
                assert.not_nil(Core.setCurrentTheme)
            end)

            test("core: getContrastLevel exists", function()
                assert.not_nil(Core.getContrastLevel)
            end)

            test("core: setContrastLevel exists", function()
                assert.not_nil(Core.setContrastLevel)
            end)

            test("core: getSelectedMod exists", function()
                assert.not_nil(Core.getSelectedMod)
            end)

            test("core: setSelectedMod exists", function()
                assert.not_nil(Core.setSelectedMod)
            end)

            test("core: getPanel exists", function()
                assert.not_nil(Core.getPanel)
            end)

            test("core: setPanel exists", function()
                assert.not_nil(Core.setPanel)
            end)

            test("core: removePanel exists", function()
                assert.not_nil(Core.removePanel)
            end)

            test("core: getPanelIds exists", function()
                assert.not_nil(Core.getPanelIds)
            end)

            test("core: snapshot/restore round-trip", function()
                local snap = Core.snapshot()
                assert.not_nil(snap)
                Core.restore(snap)
            end)

            -- RESTORE STATE after all tests (safety net)
            Core.restore(snapshot)

            return {
                passed = passed,
                failed = failed,
                warnings = 0,
                details = testResults,
            }
        end,
    },

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
        animation_section = {
            type = "section",
            label = "ANIMATION",
            settings = {
                animationsEnabled = {
                    type = "toggle",
                    label = "Enable Animations",
                    tooltip = "Master switch for all UI animations (accessibility)",
                    default = true,
                },
                animationSpeedScale = {
                    type = "slider",
                    label = "Animation Speed",
                    tooltip = "Scale factor for animation speed (0.25x to 2x)",
                    min = 0.25,
                    max = 2.0,
                    step = 0.25,
                    default = 1.0,
                    format = "%.2fx",
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

    -- Tests for this engine (run via diagnostics panel)
    tests = {
        full = function(ctx)
            local Core = ctx.core
            local assert = {
                equal = function(actual, expected, msg)
                    if actual ~= expected then
                        error((msg or "assert.equal") ..
                            " expected " .. tostring(expected) ..
                            " got " .. tostring(actual))
                    end
                end,
                not_nil = function(val, msg)
                    if val == nil then
                        error((msg or "assert.not_nil") .. " expected not nil")
                    end
                end,
            }

            local passed = 0
            local failed = 0
            local testResults = {}

            local function test(name, fn)
                local ok, err = pcall(fn)
                if ok then
                    passed = passed + 1
                    table.insert(testResults, { name = name, passed = true, error = nil })
                else
                    failed = failed + 1
                    table.insert(testResults, { name = name, passed = false, error = tostring(err) })
                    print("[Log-Engine Test] " .. name .. ": " .. tostring(err))
                end
            end

            -- SAVE STATE before tests
            local snapshot = Core.snapshot()

            -- Test: Logger functions exist on ModEngine
            test("logger: ModEngine global exists", function()
                assert.not_nil(ModEngine)
            end)

            test("logger: CreateLogger function exists", function()
                if ModEngine then
                    assert.not_nil(ModEngine.CreateLogger)
                end
            end)

            test("logger: GetLogger function exists", function()
                if ModEngine then
                    assert.not_nil(ModEngine.GetLogger)
                end
            end)

            test("logger: GetLoggerNames function exists", function()
                if ModEngine then
                    assert.not_nil(ModEngine.GetLoggerNames)
                end
            end)

            test("logger: GetStats function exists", function()
                if ModEngine then
                    assert.not_nil(ModEngine.GetStats)
                end
            end)

            test("logger: SetGlobalLevel function exists", function()
                if ModEngine then
                    assert.not_nil(ModEngine.SetGlobalLevel)
                end
            end)

            test("logger: FlushAll function exists", function()
                if ModEngine then
                    assert.not_nil(ModEngine.FlushAll)
                end
            end)

            -- RESTORE STATE after all tests
            Core.restore(snapshot)

            return {
                passed = passed,
                failed = failed,
                warnings = 0,
                details = testResults,
            }
        end,
    },

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

    -- Tests for this engine (run via diagnostics panel)
    tests = {
        full = function(ctx)
            local Core = ctx.core
            local assert = {
                equal = function(actual, expected, msg)
                    if actual ~= expected then
                        error((msg or "assert.equal") ..
                            " expected " .. tostring(expected) ..
                            " got " .. tostring(actual))
                    end
                end,
                not_nil = function(val, msg)
                    if val == nil then
                        error((msg or "assert.not_nil") .. " expected not nil")
                    end
                end,
            }

            local passed = 0
            local failed = 0
            local testResults = {}

            local function test(name, fn)
                local ok, err = pcall(fn)
                if ok then
                    passed = passed + 1
                    table.insert(testResults, { name = name, passed = true, error = nil })
                else
                    failed = failed + 1
                    table.insert(testResults, { name = name, passed = false, error = tostring(err) })
                    print("[Config-Engine Test] " .. name .. ": " .. tostring(err))
                end
            end

            -- SAVE STATE before tests
            local snapshot = Core.snapshot()

            -- Test: Core functions exist
            test("core: getContentMode exists", function()
                assert.not_nil(Core.getContentMode)
            end)

            test("core: setContentMode exists", function()
                assert.not_nil(Core.setContentMode)
            end)

            test("core: getSidebarWidth exists", function()
                assert.not_nil(Core.getSidebarWidth)
            end)

            test("core: setSidebarWidth exists", function()
                assert.not_nil(Core.setSidebarWidth)
            end)

            test("core: getSortMode exists", function()
                assert.not_nil(Core.getSortMode)
            end)

            test("core: setSortMode exists", function()
                assert.not_nil(Core.setSortMode)
            end)

            test("core: getSearchQuery exists", function()
                assert.not_nil(Core.getSearchQuery)
            end)

            test("core: setSearchQuery exists", function()
                assert.not_nil(Core.setSearchQuery)
            end)

            test("core: getSelectedMod exists", function()
                assert.not_nil(Core.getSelectedMod)
            end)

            test("core: setSelectedMod exists", function()
                assert.not_nil(Core.setSelectedMod)
            end)

            test("core: snapshot/restore round-trip", function()
                local snap = Core.snapshot()
                assert.not_nil(snap)
                Core.restore(snap)
            end)

            -- RESTORE STATE after all tests
            Core.restore(snapshot)

            return {
                passed = passed,
                failed = failed,
                warnings = 0,
                details = testResults,
            }
        end,
    },

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
