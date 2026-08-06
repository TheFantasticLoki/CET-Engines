-- Config-Engine Core State Store
-- Manages all Config-Engine state with event emission.

---@class CfgCore
---Central state store for Config-Engine: mod registry, categories, UI state, dirty tracking.
local M = {}

-- Internal state
---@type table
local state = {
    -- Mod registry
    mods = {},              -- { [modId] = { spec, settings, category, subcategory, wiki, pinned, favorite, renderMode, enabled } }

    -- Category state
    categories = {},        -- { [categoryName] = { subcategories, expanded } }
    categoryOrder = {},
    modAssignments = {},    -- { [modId] = { category, subcategory } }

    -- UI state (persisted)
    sidebarWidth = 280,
    selectedMod = nil,
    compactMode = false,
    settingsPanelOpen = false,
    wikiViewerOpen = false,
    wikiModId = nil,
    detachedMods = {},      -- { [modId] = { x, y, width, height } }
    expandedCategories = {},
    sortMode = "name",
    sortAscending = true,
    searchQuery = "",

    -- Auto-save
    dirty = false,
    lastSaveFrame = 0,
    initialized = false,
}

-- Event emitter (late-bound to avoid circular dependency)
---@type function?
local _emitEvent = nil
---@type Logger?
local log = nil

--- Set the event emitter function (called by Events module).
---@param fn function The emit function
function M.setEventEmitter(fn)
    _emitEvent = fn
end

--- Set the logger instance (called during init).
---@param logger Logger? The logger to use
function M.setLogger(logger)
    log = logger
end

--- Emit an event if emitter is available.
---@param event string Event name
---@param ... any Event arguments
local function emit(event, ...)
    if _emitEvent then
        _emitEvent(event, ...)
    end
end

--- Initialize the state store.
---@return nil
function M.init()
    if state.initialized then return end
    state.initialized = true
end

--- Reset state (for testing).
---@return nil
function M.reset()
    state = {
        mods = {},
        categories = {},
        categoryOrder = {},
        modAssignments = {},
        sidebarWidth = 280,
        selectedMod = nil,
        compactMode = false,
        settingsPanelOpen = false,
        wikiViewerOpen = false,
        wikiModId = nil,
        detachedMods = {},
        expandedCategories = {},
        sortMode = "name",
        sortAscending = true,
        searchQuery = "",
        dirty = false,
        lastSaveFrame = 0,
        initialized = false,
    }
end

-- ============================================================
-- Mod State
-- ============================================================

--- Get a mod's full state.
---@param modId string The mod identifier
---@return table? modState The mod state, or nil if not found
function M.getMod(modId)
    return state.mods[modId]
end

--- Set/update a mod's state.
---@param modId string The mod identifier
---@param data table<string, any> Table of fields to set
---@return nil
function M.setMod(modId, data)
    if not state.mods[modId] then
        state.mods[modId] = {}
    end
    local mod = state.mods[modId]
    for k, v in pairs(data) do
        mod[k] = v
    end
    state.dirty = true
    if log then log.debug("setMod: " .. modId) end
    emit("configengine:modUpdated", modId)
end

--- Remove a mod from state.
---@param modId string The mod identifier
---@return nil
function M.removeMod(modId)
    state.mods[modId] = nil
    state.modAssignments[modId] = nil
    state.detachedMods[modId] = nil
    state.dirty = true
    if log then log.debug("removeMod: " .. modId) end
    emit("configengine:modRemoved", modId)
end

--- Get all registered mods.
---@return table<string, table> Map of modId -> mod state
function M.getAllMods()
    return state.mods
end

--- Get mod IDs as an array.
---@return string[] Array of mod ID strings
function M.getModIds()
    local ids = {}
    for id in pairs(state.mods) do
        table.insert(ids, id)
    end
    return ids
end

--- Get mods filtered by category.
---@param category string The category name
---@return string[] Array of modId strings
function M.getModsByCategory(category)
    local result = {}
    for modId, mod in pairs(state.mods) do
        local assignment = state.modAssignments[modId]
        if assignment and assignment.category == category then
            table.insert(result, modId)
        end
    end
    return result
end

--- Get sorted mod IDs.
---@return string[] Array of mod ID strings
function M.getSortedModIds()
    local ids = M.getModIds()

    table.sort(ids, function(a, b)
        local modA = state.mods[a]
        local modB = state.mods[b]
        if not modA or not modB then return false end

        -- Pinned mods first
        if modA.pinned and not modB.pinned then return true end
        if not modA.pinned and modB.pinned then return false end

        -- Favorites second
        if modA.favorite and not modB.favorite then return true end
        if not modA.favorite and modB.favorite then return false end

        -- Then by sort mode
        local keyA, keyB
        if state.sortMode == "name" then
            keyA = (modA.spec and modA.spec.name) or a
            keyB = (modB.spec and modB.spec.name) or b
        elseif state.sortMode == "author" then
            keyA = (modA.spec and modA.spec.author) or ""
            keyB = (modB.spec and modB.spec.author) or ""
        elseif state.sortMode == "version" then
            keyA = (modA.spec and modA.spec.version) or ""
            keyB = (modB.spec and modB.spec.version) or ""
        else
            keyA = a
            keyB = b
        end

        if state.sortAscending then
            return keyA < keyB
        else
            return keyA > keyB
        end
    end)

    return ids
end

-- ============================================================
-- Selection
-- ============================================================

--- Get the currently selected mod.
---@return string? modId The selected mod identifier, or nil
function M.getSelectedMod()
    return state.selectedMod
end

--- Set the selected mod.
---@param modId string The mod identifier
---@return nil
function M.setSelectedMod(modId)
    if state.selectedMod ~= modId then
        state.selectedMod = modId
        state.dirty = true
        emit("configengine:selectedModChanged", modId)
    end
end

-- ============================================================
-- Category State
-- ============================================================

--- Get a mod's category assignment.
---@param modId string The mod identifier
---@return table? assignment { category: string, subcategory?: string }, or nil
function M.getModCategory(modId)
    return state.modAssignments[modId]
end

--- Set a mod's category assignment.
---@param modId string The mod identifier
---@param category string The category name
---@param subcategory? string Optional subcategory name
---@return nil
function M.setModCategory(modId, category, subcategory)
    state.modAssignments[modId] = {
        category = category,
        subcategory = subcategory,
    }
    state.dirty = true
    emit("configengine:categoryChanged", modId, category, subcategory)
end

--- Check if a category is expanded in the sidebar.
---@param category string The category name
---@return boolean expanded
function M.isCategoryExpanded(category)
    return state.expandedCategories[category] == true
end

--- Toggle a category's expanded state.
---@param category string The category name
---@return nil
function M.toggleCategory(category)
    state.expandedCategories[category] = not state.expandedCategories[category]
    state.dirty = true
end

-- ============================================================
-- UI State
-- ============================================================

--- Get sidebar width.
---@return number width Sidebar width in pixels
function M.getSidebarWidth()
    return state.sidebarWidth
end

--- Set sidebar width.
---@param width number The new width
---@return nil
function M.setSidebarWidth(width)
    state.sidebarWidth = width
    state.dirty = true
end

--- Check if compact mode is enabled.
---@return boolean isCompact
function M.isCompactMode()
    return state.compactMode
end

--- Toggle compact mode.
---@return nil
function M.toggleCompactMode()
    state.compactMode = not state.compactMode
    state.dirty = true
    emit("configengine:compactModeChanged", state.compactMode)
end

--- Check if settings panel is open.
---@return boolean isOpen
function M.isSettingsPanelOpen()
    return state.settingsPanelOpen
end

--- Toggle settings panel.
---@return nil
function M.toggleSettingsPanel()
    state.settingsPanelOpen = not state.settingsPanelOpen
    state.dirty = true
end

--- Check if wiki viewer is open.
---@return boolean isOpen
function M.isWikiViewerOpen()
    return state.wikiViewerOpen
end

--- Open wiki viewer for a mod.
---@param modId string The mod identifier
---@return nil
function M.openWikiViewer(modId)
    state.wikiViewerOpen = true
    state.wikiModId = modId
    emit("configengine:wikiOpened", modId)
end

--- Close wiki viewer.
---@return nil
function M.closeWikiViewer()
    state.wikiViewerOpen = false
    state.wikiModId = nil
end

--- Get search query.
---@return string query Current search query
function M.getSearchQuery()
    return state.searchQuery
end

--- Set search query.
---@param query string The search string
---@return nil
function M.setSearchQuery(query)
    state.searchQuery = query
    state.dirty = true
    emit("configengine:searchChanged", query)
end

--- Get sort mode.
---@return string mode Sort mode ("name", "author", "version")
---@return boolean ascending Sort direction
function M.getSortMode()
    return state.sortMode, state.sortAscending
end

--- Set sort mode.
---@param mode? string The sort mode ("name", "author", "version")
---@param ascending? boolean Sort direction, defaults to true
---@return nil
function M.setSortMode(mode, ascending)
    state.sortMode = mode or "name"
    state.sortAscending = ascending ~= false
    state.dirty = true
end

-- ============================================================
-- Detached Windows
-- ============================================================

--- Check if a mod is detached.
---@param modId string The mod identifier
---@return boolean isDetached
function M.isDetached(modId)
    return state.detachedMods[modId] ~= nil
end

--- Detach a mod to its own window.
---@param modId string The mod identifier
---@param x? number Optional x position
---@param y? number Optional y position
---@return nil
function M.detachMod(modId, x, y)
    state.detachedMods[modId] = {
        x = x or 100,
        y = y or 100,
        width = 400,
        height = 300,
    }
    state.dirty = true
    emit("configengine:modDetached", modId)
end

--- Reattach a detached mod.
---@param modId string The mod identifier
---@return nil
function M.reattachMod(modId)
    state.detachedMods[modId] = nil
    state.dirty = true
    emit("configengine:modReattached", modId)
end

--- Get all detached mods.
---@return table<string, table> Map of modId -> { x: number, y: number, width: number, height: number }
function M.getDetachedMods()
    return state.detachedMods
end

-- ============================================================
-- Dirty / Persistence
-- ============================================================

--- Check if state needs saving.
---@return boolean dirty
function M.isDirty()
    return state.dirty
end

--- Mark state as dirty.
---@return nil
function M.markDirty()
    state.dirty = true
end

--- Clear dirty flag (called after save).
---@return nil
function M.clearDirty()
    state.dirty = false
end

--- Get the last save frame.
---@return number frame The frame number
function M.getLastSaveFrame()
    return state.lastSaveFrame
end

--- Set the last save frame.
---@param frame number The frame number
---@return nil
function M.setLastSaveFrame(frame)
    state.lastSaveFrame = frame
end

-- ============================================================
-- Serialization
-- ============================================================

--- Serialize all state for persistence.
---@return table<string, any> Serializable state
function M.getAllState()
    return {
        mods = state.mods,
        modAssignments = state.modAssignments,
        sidebarWidth = state.sidebarWidth,
        selectedMod = state.selectedMod,
        compactMode = state.compactMode,
        expandedCategories = state.expandedCategories,
        sortMode = state.sortMode,
        sortAscending = state.sortAscending,
        detachedMods = state.detachedMods,
    }
end

--- Restore state from persisted data.
---@param data table<string, any> The persisted state table
---@return nil
function M.applyState(data)
    if not data or type(data) ~= "table" then return end

    if data.mods then state.mods = data.mods end
    if data.modAssignments then state.modAssignments = data.modAssignments end
    if data.sidebarWidth then state.sidebarWidth = data.sidebarWidth end
    if data.selectedMod then state.selectedMod = data.selectedMod end
    if data.compactMode ~= nil then state.compactMode = data.compactMode end
    if data.expandedCategories then state.expandedCategories = data.expandedCategories end
    if data.sortMode then state.sortMode = data.sortMode end
    if data.sortAscending ~= nil then state.sortAscending = data.sortAscending end
    if data.detachedMods then state.detachedMods = data.detachedMods end

    state.initialized = true
end

return M
