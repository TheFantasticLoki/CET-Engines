-- Config-Engine Setting Applier
-- Bridges saved engine settings to actual engine subsystems at startup.
-- Also handles live setting application for UI changes.

---@class SettingApplier
local M = {}

-- Dependencies (late-bound)
---@type table|nil CfgCore module reference
local _cfgCore = nil
---@type table|nil Core module reference (UI-Engine core)
local _core = nil
---@type table|nil Theme module reference
local _theme = nil
---@type table|nil LogEngine module reference
local _logEngine = nil
---@type table|nil CfgStateSync module reference
local _stateSync = nil
---@type table|nil Animation module reference
local _animation = nil
---@type table|nil Logger instance
local _log = nil

--- Initialize the setting applier module.
---@param deps table { cfgCore, core, theme, logEngine, stateSync, animation, log }
---@return nil
function M.init(deps)
    _cfgCore = deps.cfgCore
    _core = deps.core
    _theme = deps.theme
    _logEngine = deps.logEngine
    _stateSync = deps.stateSync
    _animation = deps.animation
    _log = deps.log
end

--- Apply saved engine settings to actual engine subsystems at startup.
--- Called after all modules are initialized so saved settings override hardcoded defaults.
---@return nil
function M.bridgeEngineSettings()
    if not _cfgCore then return end

    -- UI-Engine settings
    local uiMod = _cfgCore.getMod("0-Engine-UI")
    if uiMod and uiMod.settings then
        local s = uiMod.settings
        if s.currentTheme and _theme and _theme.SetTheme then
            _theme.SetTheme(s.currentTheme)
        end
        if s.contrastLevel and _theme and _theme.SetHighContrast then
            _theme.SetHighContrast(s.contrastLevel)
        end
        if s.accentColor and _core and _core.setAccentColor then
            _core.setAccentColor(s.accentColor)
        end
        if s.autoSave ~= nil and _core and _core.setAutoSave then
            _core.setAutoSave(s.autoSave)
        end
        if s.showSidebar ~= nil and _core and _core.setSidebarOpen then
            _core.setSidebarOpen(s.showSidebar)
        end
        -- Animation settings
        if s.animationsEnabled ~= nil and _animation and _animation.setConfig then
            _animation.setConfig({ enabled = s.animationsEnabled })
        end
        if s.animationSpeedScale and _animation and _animation.setConfig then
            _animation.setConfig({ speedScale = s.animationSpeedScale })
        end
    end

    -- Log-Engine settings
    local logMod = _cfgCore.getMod("0-Engine-Log")
    if logMod and logMod.settings and _logEngine then
        local s = logMod.settings
        if s.globalMinLevel then _logEngine.SetGlobalLevel(s.globalMinLevel) end
        if s.logDir then _logEngine.setLogDir(s.logDir) end
        if s.maxFileSize then _logEngine.setMaxFileSize(s.maxFileSize) end
        if s.maxFiles then _logEngine.setMaxFiles(s.maxFiles) end
        if s.maxDebugPerFrame then _logEngine.setMaxDebugPerFrame(s.maxDebugPerFrame) end
        if s.dedupEnabled ~= nil then _logEngine.setDedupEnabled(s.dedupEnabled) end
        if s.dedupMaxEntries then _logEngine.setDedupMaxEntries(s.dedupMaxEntries) end
        if s.ringSize then _logEngine.setRingSize(s.ringSize) end
    end

    -- Config-Engine settings
    local cfgMod = _cfgCore.getMod("0-Engine-Config")
    if cfgMod and cfgMod.settings then
        local s = cfgMod.settings
        if s.sidebarWidth and _core and _core.setSidebarWidth then
            _cfgCore.setSidebarWidth(s.sidebarWidth)
        end
    end
end

--- Apply a single setting change to the live engine (e.g., theme changes).
---@param modId string The mod identifier
---@param key string The setting key
---@param value any The new value
---@return nil
function M.applySettingLive(modId, key, value)
    -- UI-Engine live settings
    if modId == "0-Engine-UI" then
        if key == "currentTheme" and _theme and _theme.SetTheme then
            _theme.SetTheme(value)
        elseif key == "contrastLevel" and _theme and _theme.SetHighContrast then
            _theme.SetHighContrast(value)
        elseif key == "accentColor" and _core and _core.setAccentColor then
            _core.setAccentColor(value)
        elseif key == "autoSave" then
            -- Sync auto-save toggle to both CfgCore and Core
            if _core and _core.setAutoSave then _core.setAutoSave(value) end
            if _cfgCore and _cfgCore.setAutoSave then _cfgCore.setAutoSave(value) end
        elseif key == "showSidebar" and _core and _core.setSidebarOpen then
            _core.setSidebarOpen(value)
        -- Animation settings
        elseif key == "animationsEnabled" and _animation and _animation.setConfig then
            _animation.setConfig({ enabled = value })
        elseif key == "animationSpeedScale" and _animation and _animation.setConfig then
            _animation.setConfig({ speedScale = value })
        end
    end

    -- Log-Engine live settings
    if modId == "0-Engine-Log" and _logEngine then
        if key == "globalMinLevel" and _logEngine.SetGlobalLevel then
            _logEngine.SetGlobalLevel(value)
        elseif key == "logDir" and _logEngine.setLogDir then
            _logEngine.setLogDir(value)
        elseif key == "maxFileSize" and _logEngine.setMaxFileSize then
            _logEngine.setMaxFileSize(value)
        elseif key == "maxFiles" and _logEngine.setMaxFiles then
            _logEngine.setMaxFiles(value)
        elseif key == "maxDebugPerFrame" and _logEngine.setMaxDebugPerFrame then
            _logEngine.setMaxDebugPerFrame(value)
        elseif key == "dedupEnabled" and _logEngine.setDedupEnabled then
            _logEngine.setDedupEnabled(value)
        elseif key == "dedupMaxEntries" and _logEngine.setDedupMaxEntries then
            _logEngine.setDedupMaxEntries(value)
        elseif key == "ringSize" and _logEngine.setRingSize then
            _logEngine.setRingSize(value)
        end
    end

    -- Config-Engine live settings
    if modId == "0-Engine-Config" then
        if key == "sidebarWidth" and _cfgCore and _cfgCore.setSidebarWidth then
            _cfgCore.setSidebarWidth(value)
        elseif key == "autoSaveDelay" and _stateSync and _stateSync.setAutoSaveDelay then
            _stateSync.setAutoSaveDelay(value)
        end
    end
end

return M
