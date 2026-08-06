-- Config-Engine State Sync
-- Synchronizes Config-Engine state with UI-Engine Storage.
-- Handles auto-save with debounce and load on init.

---@class StateSync
---Persistence layer: load/save state to Storage, auto-save with debounce.
local M = {}

-- Storage keys
local STORAGE_KEYS = {
    MODS = "configengine_mods",
    CATEGORIES = "configengine_categories",
    UI_STATE = "configengine_ui",
    PRESETS = "configengine_presets",
    COLLECTIONS = "configengine_collections",
}

-- Dependencies (late-bound)
---@type table?
local Core = nil
---@type table?
local Storage = nil
---@type table?
local Logger = nil
---@type table?
local Config = nil
---@type Logger?
local log = nil

-- Auto-save state
local AUTO_SAVE_DELAY = 30 -- frames

--- Initialize state sync.
---@param deps table { core: CfgCore, storage: StorageModule, logger: LoggerModule?, config: table? }
---@return nil
function M.init(deps)
    Core = deps.core
    Storage = deps.storage
    Logger = deps.logger
    Config = deps.config or {}
    AUTO_SAVE_DELAY = Config.AUTO_SAVE_DELAY_FRAMES or 30

    if Logger then
        log = Logger
    end
end

--- Load all persisted state from storage.
---@return boolean success
function M.loadAll()
    if not Storage then
        if log then
            log.warn("Storage not available, using defaults")
        elseif Logger then
            Logger.warn("ConfigEngine", "Storage not available, using defaults")
        end
        return false
    end

    -- Load UI state
    local uiState = Storage.Get("configengine", STORAGE_KEYS.UI_STATE)
    if uiState then
        Core.applyState(uiState)
        if log then
            log.info("Loaded UI state")
        elseif Logger then
            Logger.info("ConfigEngine", "Loaded UI state")
        end
    end

    -- Load mod assignments
    local categories = Storage.Get("configengine", STORAGE_KEYS.CATEGORIES)
    if categories then
        if categories.modAssignments then
            for modId, assignment in pairs(categories.modAssignments) do
                Core.setModCategory(modId, assignment.category, assignment.subcategory)
            end
        end
        if log then
            log.info("Loaded category assignments")
        elseif Logger then
            Logger.info("ConfigEngine", "Loaded category assignments")
        end
    end

    -- Load mod settings
    local modData = Storage.Get("configengine", STORAGE_KEYS.MODS)
    if modData and type(modData) == "table" then
        for modId, modState in pairs(modData) do
            local existing = Core.getMod(modId)
            if existing then
                -- Merge saved settings into existing mod state
                if modState.settings then
                    existing.settings = modState.settings
                end
                if modState.pinned ~= nil then existing.pinned = modState.pinned end
                if modState.favorite ~= nil then existing.favorite = modState.favorite end
                Core.setMod(modId, existing)
            end
        end
        if log then
            log.info("Loaded mod settings")
        elseif Logger then
            Logger.info("ConfigEngine", "Loaded mod settings")
        end
    end

    return true
end

--- Save all state to storage.
---@return boolean success
function M.saveAll()
    if not Storage then return false end

    -- Save UI state
    local uiState = Core.getAllState()
    Storage.Set("configengine", STORAGE_KEYS.UI_STATE, uiState)

    -- Save category assignments
    local allMods = Core.getAllMods()
    local modAssignments = {}
    for modId in pairs(allMods) do
        local assignment = Core.getModCategory(modId)
        if assignment then
            modAssignments[modId] = assignment
        end
    end
    Storage.Set("configengine", STORAGE_KEYS.CATEGORIES, {
        modAssignments = modAssignments,
    })

    -- Save mod settings (only settings, not full state)
    local modSettings = {}
    for modId, mod in pairs(allMods) do
        modSettings[modId] = {
            settings = mod.settings,
            pinned = mod.pinned,
            favorite = mod.favorite,
        }
    end
    Storage.Set("configengine", STORAGE_KEYS.MODS, modSettings)

    Core.clearDirty()

    if log then
        log.debug("State saved")
    elseif Logger then
        Logger.debug("ConfigEngine", "State saved")
    end

    return true
end

--- Check if auto-save is needed and perform it.
--- Should be called every frame.
---@param currentFrame number The current frame number
---@return nil
function M.autoSave(currentFrame)
    if not Core.isDirty() then return end

    local elapsed = currentFrame - Core.getLastSaveFrame()
    if elapsed >= AUTO_SAVE_DELAY then
        M.saveAll()
        Core.setLastSaveFrame(currentFrame)
    end
end

--- Flush save immediately (for overlay close, shutdown).
---@return nil
function M.flush()
    if Core.isDirty() then
        M.saveAll()
    end
end

return M
