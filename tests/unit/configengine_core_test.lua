--[[
    Config-Engine Core Tests

    Tests for engines/Config-Engine/core.lua
]]

local assert = require("tests.assert")
local Core = require("engines.0-Mod-Engine.cfg.core")

local M = {}

function M.testInit()
    Core.reset()
    Core.init()
    -- Should be idempotent
    Core.init()
    assert.assert_true(true, "init should not error")
end

function M.testModState()
    Core.reset()
    Core.init()

    -- No mods initially
    assert.assert_nil(Core.getMod("test-mod"), "should have no mods initially")

    -- Add a mod
    Core.setMod("test-mod", {
        spec = { name = "Test Mod", version = "1.0" },
        enabled = true,
    })

    local mod = Core.getMod("test-mod")
    assert.assert_not_nil(mod, "mod should exist")
    assert.assert_equal(mod.spec.name, "Test Mod", "mod name should match")
    assert.assert_true(mod.enabled, "mod should be enabled")
end

function M.testModRemoval()
    Core.reset()
    Core.init()

    Core.setMod("test-mod", { spec = { name = "Test" } })
    assert.assert_not_nil(Core.getMod("test-mod"), "mod should exist")

    Core.removeMod("test-mod")
    assert.assert_nil(Core.getMod("test-mod"), "mod should be removed")
end

function M.testModIds()
    Core.reset()
    Core.init()

    Core.setMod("mod-a", { spec = { name = "A" } })
    Core.setMod("mod-b", { spec = { name = "B" } })

    local ids = Core.getModIds()
    assert.assert_equal(#ids, 2, "should have 2 mod IDs")
end

function M.testSelection()
    Core.reset()
    Core.init()

    assert.assert_nil(Core.getSelectedMod(), "no mod selected initially")

    Core.setSelectedMod("my-mod")
    assert.assert_equal(Core.getSelectedMod(), "my-mod", "selected mod should be set")

    Core.setSelectedMod(nil)
    assert.assert_nil(Core.getSelectedMod(), "selected mod should be cleared")
end

function M.testCategory()
    Core.reset()
    Core.init()

    assert.assert_nil(Core.getModCategory("test-mod"), "no category initially")

    Core.setModCategory("test-mod", "Gameplay", "Combat")
    local cat = Core.getModCategory("test-mod")
    assert.assert_not_nil(cat, "category should exist")
    assert.assert_equal(cat.category, "Gameplay", "category should be Gameplay")
    assert.assert_equal(cat.subcategory, "Combat", "subcategory should be Combat")
end

function M.testCategoryExpansion()
    Core.reset()
    Core.init()

    assert.assert_false(Core.isCategoryExpanded("Gameplay"), "category should not be expanded")

    Core.toggleCategory("Gameplay")
    assert.assert_true(Core.isCategoryExpanded("Gameplay"), "category should be expanded")

    Core.toggleCategory("Gameplay")
    assert.assert_false(Core.isCategoryExpanded("Gameplay"), "category should be collapsed")
end

function M.testSidebarWidth()
    Core.reset()
    Core.init()

    assert.assert_equal(Core.getSidebarWidth(), 280, "default sidebar width should be 280")

    Core.setSidebarWidth(350)
    assert.assert_equal(Core.getSidebarWidth(), 350, "sidebar width should be updated")
end

function M.testCompactMode()
    Core.reset()
    Core.init()

    assert.assert_false(Core.isCompactMode(), "compact mode should be off")

    Core.toggleCompactMode()
    assert.assert_true(Core.isCompactMode(), "compact mode should be on")
end

function M.testSearchQuery()
    Core.reset()
    Core.init()

    assert.assert_equal(Core.getSearchQuery(), "", "search query should be empty")

    Core.setSearchQuery("test")
    assert.assert_equal(Core.getSearchQuery(), "test", "search query should be set")
end

function M.testSortMode()
    Core.reset()
    Core.init()

    local mode, asc = Core.getSortMode()
    assert.assert_equal(mode, "name", "default sort mode should be name")
    assert.assert_true(asc, "default sort should be ascending")

    Core.setSortMode("author", false)
    mode, asc = Core.getSortMode()
    assert.assert_equal(mode, "author", "sort mode should be author")
    assert.assert_false(asc, "sort should be descending")
end

function M.testDetachedMods()
    Core.reset()
    Core.init()

    assert.assert_false(Core.isDetached("test-mod"), "mod should not be detached")

    Core.detachMod("test-mod")
    assert.assert_true(Core.isDetached("test-mod"), "mod should be detached")

    Core.reattachMod("test-mod")
    assert.assert_false(Core.isDetached("test-mod"), "mod should be reattached")
end

function M.testDirty()
    Core.reset()
    Core.init()

    assert.assert_false(Core.isDirty(), "should not be dirty initially")

    Core.markDirty()
    assert.assert_true(Core.isDirty(), "should be dirty after mark")

    Core.clearDirty()
    assert.assert_false(Core.isDirty(), "should not be dirty after clear")
end

function M.testSerialization()
    Core.reset()
    Core.init()

    Core.setMod("test-mod", { spec = { name = "Test" } })
    Core.setSelectedMod("test-mod")
    Core.setSidebarWidth(300)

    local state = Core.getAllState()
    assert.assert_not_nil(state, "state should not be nil")
    assert.assert_not_nil(state.mods, "state should have mods")
    assert.assert_equal(state.selectedMod, "test-mod", "state should have selected mod")
    assert.assert_equal(state.sidebarWidth, 300, "state should have sidebar width")

    -- Restore state
    Core.reset()
    Core.init()
    Core.applyState(state)

    assert.assert_not_nil(Core.getMod("test-mod"), "mod should be restored")
    assert.assert_equal(Core.getSelectedMod(), "test-mod", "selection should be restored")
    assert.assert_equal(Core.getSidebarWidth(), 300, "sidebar width should be restored")
end

function M.testSortedModIds()
    Core.reset()
    Core.init()

    Core.setMod("c-mod", { spec = { name = "C Mod" }, pinned = false })
    Core.setMod("a-mod", { spec = { name = "A Mod" }, pinned = false })
    Core.setMod("b-mod", { spec = { name = "B Mod" }, pinned = true })

    local ids = Core.getSortedModIds()
    assert.assert_equal(#ids, 3, "should have 3 mods")
    -- Pinned first
    assert.assert_equal(ids[1], "b-mod", "pinned mod should be first")
end

function M.testEventEmission()
    Core.reset()
    Core.init()

    local events = {}
    Core.setEventEmitter(function(event, ...)
        table.insert(events, { event = event, args = { ... } })
    end)

    Core.setSelectedMod("test-mod")
    assert.assert_true(#events > 0, "should emit event on selection change")
    assert.assert_equal(events[1].event, "configengine:selectedModChanged", "event name should match")
end

-- ============================================================
-- Shared Panel Tests
-- ============================================================

function M.testSharedPanelEmpty()
    Core.reset()
    Core.init()

    local mods = Core.getSharedPanelMods()
    assert.assert_not_nil(mods, "shared panel mods should not be nil")
    assert.assert_equal(#mods, 0, "shared panel should start empty")
    assert.assert_equal(Core.getSharedPanelModCount(), 0, "shared panel count should be 0")
end

function M.testSharedPanelAdd()
    Core.reset()
    Core.init()

    Core.addSharedPanelMod("mod-a")
    local mods = Core.getSharedPanelMods()
    assert.assert_equal(#mods, 1, "should have 1 shared panel mod")
    assert.assert_equal(mods[1], "mod-a", "should contain mod-a")
    assert.assert_true(Core.isSharedPanelMod("mod-a"), "isSharedPanelMod should return true")
    assert.assert_equal(Core.getSharedPanelModCount(), 1, "count should be 1")
end

function M.testSharedPanelAddIdempotent()
    Core.reset()
    Core.init()

    Core.addSharedPanelMod("mod-a")
    Core.addSharedPanelMod("mod-a")  -- duplicate
    Core.addSharedPanelMod("mod-a")  -- duplicate
    local mods = Core.getSharedPanelMods()
    assert.assert_equal(#mods, 1, "should still have 1 shared panel mod (idempotent)")
end

function M.testSharedPanelRemove()
    Core.reset()
    Core.init()

    Core.addSharedPanelMod("mod-a")
    Core.addSharedPanelMod("mod-b")
    assert.assert_equal(Core.getSharedPanelModCount(), 2, "should have 2 mods")

    Core.removeSharedPanelMod("mod-a")
    local mods = Core.getSharedPanelMods()
    assert.assert_equal(#mods, 1, "should have 1 shared panel mod after removal")
    assert.assert_equal(mods[1], "mod-b", "remaining mod should be mod-b")
    assert.assert_false(Core.isSharedPanelMod("mod-a"), "mod-a should not be in shared panel")
    assert.assert_true(Core.isSharedPanelMod("mod-b"), "mod-b should still be in shared panel")
end

function M.testSharedPanelRemoveIdempotent()
    Core.reset()
    Core.init()

    Core.addSharedPanelMod("mod-a")
    Core.removeSharedPanelMod("mod-a")
    Core.removeSharedPanelMod("mod-a")  -- removing non-existent
    assert.assert_equal(Core.getSharedPanelModCount(), 0, "should still be empty")
end

function M.testSharedPanelNotInNormalList()
    Core.reset()
    Core.init()

    Core.setMod("mod-a", { spec = { name = "Mod A" } })
    Core.setMod("mod-b", { spec = { name = "Mod B" } })
    Core.setMod("mod-c", { spec = { name = "Mod C" } })
    Core.addSharedPanelMod("mod-b")

    -- getModIds should still include it (for data access)
    local allIds = Core.getModIds()
    assert.assert_equal(#allIds, 3, "getModIds should include all 3 mods")

    -- isSharedPanelMod should distinguish
    assert.assert_true(Core.isSharedPanelMod("mod-b"), "mod-b should be shared panel")
    assert.assert_false(Core.isSharedPanelMod("mod-a"), "mod-a should not be shared panel")
    assert.assert_false(Core.isSharedPanelMod("mod-c"), "mod-c should not be shared panel")
end

function M.testSharedPanelPersistence()
    Core.reset()
    Core.init()

    Core.addSharedPanelMod("mod-a")
    Core.addSharedPanelMod("mod-b")

    -- Serialize
    local state = Core.getAllState()
    assert.assert_not_nil(state.sharedPanelMods, "serialized state should have sharedPanelMods")
    assert.assert_equal(#state.sharedPanelMods, 2, "serialized should have 2 mods")

    -- Restore into fresh state
    Core.reset()
    Core.init()
    Core.applyState(state)

    assert.assert_equal(Core.getSharedPanelModCount(), 2, "restored should have 2 mods")
    assert.assert_true(Core.isSharedPanelMod("mod-a"), "mod-a should be restored")
    assert.assert_true(Core.isSharedPanelMod("mod-b"), "mod-b should be restored")
end

function M.testSharedPanelClearOnReset()
    Core.reset()
    Core.init()

    Core.addSharedPanelMod("mod-a")
    assert.assert_equal(Core.getSharedPanelModCount(), 1, "should have 1 mod")

    Core.reset()
    assert.assert_equal(Core.getSharedPanelModCount(), 0, "should be empty after reset")
end

return M
