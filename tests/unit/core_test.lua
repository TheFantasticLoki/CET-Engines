--[[
    Core Module Tests — UI-Engine

    Tests for engines/UI-Engine/core.lua
]]

local assert = require("tests.assert")
local Core = require("engines.0-Mod-Engine.core")

local M = {}

-- --- Test Default Values ---

function M.testDefaultValues()
    Core.reset()

    -- UI sub-store
    assert.assert_nil(Core.getSelectedMod(), "selectedMod should default to nil")
    assert.assert_true(Core.getSidebarOpen(), "sidebarOpen should default to true")
    assert.assert_false(Core.getSettingsOpen(), "settingsOpen should default to false")

    -- Theme sub-store
    assert.assert_equal(Core.getCurrentTheme(), "Dark", "currentTheme should default to Dark")
    assert.assert_equal(Core.getContrastLevel(), 1, "contrastLevel should default to 1")

    -- Sidebar sub-store
    assert.assert_equal(Core.getSearchQuery(), "", "searchQuery should default to empty string")

    -- Settings sub-store
    assert.assert_equal(Core.getSettingsVersion(), 1, "settingsVersion should default to 1")
    assert.assert_true(Core.getAutoSave(), "autoSave should default to true")
end

-- --- Test Getter/Setter ---

function M.testGetterSetter()
    Core.reset()

    -- UI sub-store
    Core.setSelectedMod("my-mod")
    assert.assert_equal(Core.getSelectedMod(), "my-mod", "selectedMod should be set")

    Core.setSidebarOpen(false)
    assert.assert_false(Core.getSidebarOpen(), "sidebarOpen should be false")

    Core.setSettingsOpen(true)
    assert.assert_true(Core.getSettingsOpen(), "settingsOpen should be true")

    -- Theme sub-store
    Core.setCurrentTheme("Light")
    assert.assert_equal(Core.getCurrentTheme(), "Light", "currentTheme should be Light")

    Core.setContrastLevel(2)
    assert.assert_equal(Core.getContrastLevel(), 2, "contrastLevel should be 2")

    -- Sidebar sub-store
    Core.setSearchQuery("test query")
    assert.assert_equal(Core.getSearchQuery(), "test query", "searchQuery should be set")

    -- Settings sub-store
    Core.setSettingsVersion(2)
    assert.assert_equal(Core.getSettingsVersion(), 2, "settingsVersion should be 2")

    Core.setAutoSave(false)
    assert.assert_false(Core.getAutoSave(), "autoSave should be false")
end

-- --- Test Event Emission ---

function M.testEventEmission()
    Core.reset()

    local events = {}

    -- Set up event emitter
    Core.setEventEmitter(function(event, ...)
        table.insert(events, { event = event, args = { ... } })
    end)

    -- Trigger events
    Core.setSelectedMod("test-mod")
    Core.setSidebarOpen(false)
    Core.setCurrentTheme("Red")
    Core.setSearchQuery("hello")

    -- Verify events were emitted
    assert.assert_true(#events > 0, "Events should be emitted")

    -- Check specific events
    local found = false
    for _, e in ipairs(events) do
        if e.event == "core:selectedModChanged" then
            found = true
            break
        end
    end
    assert.assert_true(found, "selectedModChanged event should be emitted")

    -- Clean up
    Core.setEventEmitter(nil)
end

-- --- Test Bulk Get/Set ---

function M.testBulkGetSet()
    Core.reset()

    -- Set some values
    Core.setSelectedMod("bulk-test")
    Core.setSidebarOpen(false)
    Core.setCurrentTheme("Blue")
    Core.setSearchQuery("bulk query")
    Core.setSettingsVersion(3)
    Core.setAutoSave(false)

    -- Get all settings
    local all = Core.getAllSettings()
    assert.assert_not_nil(all, "getAllSettings should return a table")
    assert.assert_equal(all.ui.selectedMod, "bulk-test", "selectedMod should match")
    assert.assert_false(all.ui.sidebarOpen, "sidebarOpen should match")
    assert.assert_equal(all.theme.currentTheme, "Blue", "currentTheme should match")
    assert.assert_equal(all.sidebar.searchQuery, "bulk query", "searchQuery should match")
    assert.assert_equal(all.settings.settingsVersion, 3, "settingsVersion should match")
    assert.assert_false(all.settings.autoSave, "autoSave should match")

    -- Apply settings
    Core.applySettings({
        ui = { selectedMod = "applied", sidebarOpen = true },
        theme = { currentTheme = "Green" },
        settings = { settingsVersion = 5 },
    })

    assert.assert_equal(Core.getSelectedMod(), "applied", "selectedMod should be applied")
    assert.assert_true(Core.getSidebarOpen(), "sidebarOpen should be applied")
    assert.assert_equal(Core.getCurrentTheme(), "Green", "currentTheme should be applied")
    assert.assert_equal(Core.getSettingsVersion(), 5, "settingsVersion should be applied")
end

-- --- Test Sub-Store Isolation ---

function M.testSubStoreIsolation()
    Core.reset()

    -- Set values in different sub-stores
    Core.setSelectedMod("isolation-test")
    Core.setCurrentTheme("Purple")
    Core.setSearchQuery("isolation query")

    -- Verify they don't interfere
    assert.assert_equal(Core.getSelectedMod(), "isolation-test", "selectedMod should be independent")
    assert.assert_equal(Core.getCurrentTheme(), "Purple", "currentTheme should be independent")
    assert.assert_equal(Core.getSearchQuery(), "isolation query", "searchQuery should be independent")
end

-- --- Test Panel Management ---

function M.testPanelManagement()
    Core.reset()

    -- Set panels
    Core.setPanel("mod-a", { name = "Mod A", draw = function() end })
    Core.setPanel("mod-b", { name = "Mod B", draw = function() end })

    -- Get panels
    local panelA = Core.getPanel("mod-a")
    assert.assert_not_nil(panelA, "Panel A should exist")
    assert.assert_equal(panelA.name, "Mod A", "Panel A name should match")

    -- Get panel IDs
    local ids = Core.getPanelIds()
    assert.assert_true(#ids >= 2, "Should have at least 2 panels")

    -- Remove panel
    Core.removePanel("mod-a")
    assert.assert_nil(Core.getPanel("mod-a"), "Panel A should be removed")

    -- Clean up
    Core.removePanel("mod-b")
end

-- --- Test Window Management ---

function M.testWindowManagement()
    Core.reset()

    -- Set windows
    Core.setWindow("win-a", { title = "Window A" })
    Core.setWindow("win-b", { title = "Window B" })

    -- Get windows
    local winA = Core.getWindow("win-a")
    assert.assert_not_nil(winA, "Window A should exist")
    assert.assert_equal(winA.title, "Window A", "Window A title should match")

    -- Get window IDs
    local ids = Core.getWindowIds()
    assert.assert_true(#ids >= 2, "Should have at least 2 windows")

    -- Remove window
    Core.removeWindow("win-a")
    assert.assert_nil(Core.getWindow("win-a"), "Window A should be removed")

    -- Clean up
    Core.removeWindow("win-b")
end

-- --- Test Idempotent Init ---

function M.testIdempotentInit()
    Core.reset()

    -- Call init multiple times
    local events = {}
    Core.setEventEmitter(function(event, ...)
        table.insert(events, event)
    end)

    Core.init()
    Core.init()
    Core.init()

    -- Should only emit one initComplete event
    local initCount = 0
    for _, e in ipairs(events) do
        if e == "core:initComplete" then
            initCount = initCount + 1
        end
    end
    assert.assert_equal(initCount, 1, "initComplete should only be emitted once")

    -- Clean up
    Core.setEventEmitter(nil)
end

return M