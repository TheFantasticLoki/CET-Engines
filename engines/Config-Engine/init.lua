--[[
    Config-Engine Entry Point

    CET mod that uses UI-Engine as its framework to provide a unified
    mod management interface with settings schemas, undo/redo, presets,
    and categories.

    Public API: _G.ConfigEngine
]]

-- ============================================================================
-- Module Loading (safe, deferred dependencies)
-- ============================================================================

local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then
        return mod
    end
    print("[ConfigEngine] FAILED to load '" .. path .. "': " .. tostring(mod))
    return nil
end

-- Load modules relative to mod root (CET require convention)
local Core = SafeRequire("core")
local Schema = SafeRequire("modules.settings_schema")
local Resolver = SafeRequire("modules.settings_resolver")
local UndoRedo = SafeRequire("modules.undo_redo")
local ModManager = SafeRequire("modules.mod_manager")
local SettingsRenderer = SafeRequire("modules.settings_renderer")
local StateSync = SafeRequire("modules.state_sync")
-- Note: EngineSchemas is loaded lazily inside registerEngines() for better error reporting

-- ============================================================================
-- State
-- ============================================================================

local initialized = false
local overlayOpen = false
local UIEngine = nil
local LogEngine = nil
local log = nil
local drawFrameCount = 0
local rescanInterval = 120  -- re-check for late-loading mods every 2 seconds at 60fps

-- ============================================================================
-- Public API
-- ============================================================================

--- Register a mod with Config-Engine.
---@param modId Unique mod identifier
---@param spec Registration spec table
---@return boolean success, string|nil error
local function Register(modId, spec)
    if not initialized then
        return false, "ConfigEngine not initialized"
    end
    if not ModManager then
        return false, "ModManager module not loaded"
    end
    return ModManager.register(modId, spec)
end

--- Unregister a mod from Config-Engine.
---@param modId The mod identifier
---@return boolean success
local function Unregister(modId)
    if not initialized then return false end
    if not ModManager then return false end
    return ModManager.unregister(modId)
end

--- Get mod info.
---@param modId The mod identifier
---@return table|nil
local function GetModInfo(modId)
    if not initialized then return nil end
    if not ModManager then return nil end
    return ModManager.getModInfo(modId)
end

--- Get list of all registered mods.
---@return table Array of modId strings
local function GetModList()
    if not initialized then return {} end
    if not ModManager then return {} end
    return ModManager.getModList()
end

--- Get a mod's settings.
---@param modId The mod identifier
---@return table|nil
local function GetModSettings(modId)
    if not initialized then return nil end
    if not ModManager then return nil end
    return ModManager.getSettings(modId)
end

--- Update a mod's settings.
---@param modId The mod identifier
---@param settings New settings values
---@return boolean success
local function SetModSettings(modId, settings)
    if not initialized then return false end
    if not ModManager then return false end
    return ModManager.updateSettings(modId, settings)
end

--- Reset a mod's settings to defaults.
---@param modId The mod identifier
---@return boolean success
local function ResetModSettings(modId)
    if not initialized then return false end
    if not ModManager then return false end
    return ModManager.resetSettings(modId)
end

--- Set a mod's category.
---@param modId The mod identifier
---@param category The category name
---@param subcategory Optional subcategory
local function SetModCategory(modId, category, subcategory)
    if not initialized then return end
    Core.setModCategory(modId, category, subcategory)
end

--- Get a mod's category.
---@param modId The mod identifier
---@return table|nil { category, subcategory }
local function GetModCategory(modId)
    if not initialized then return nil end
    return Core.getModCategory(modId)
end

--- Check if Config-Engine manages a mod.
---@param modId The mod identifier
---@return boolean
local function IsManaged(modId)
    if not initialized then return false end
    return Core.getMod(modId) ~= nil
end

--- Detach a mod to its own window.
---@param modId The mod identifier
local function DetachMod(modId)
    if not initialized then return end
    Core.detachMod(modId)
end

--- Reattach a detached mod.
---@param modId The mod identifier
local function ReattachMod(modId)
    if not initialized then return end
    Core.reattachMod(modId)
end

--- Undo the last change.
---@return boolean success
local function Undo()
    if not initialized then return false end
    return UndoRedo.undo(function(cmd)
        if cmd.type == "setting" then
            local mod = Core.getMod(cmd.modId)
            if mod and mod.settings then
                Resolver.setValue(mod.settings, cmd.key, cmd.oldValue)
                Core.markDirty()
                return true
            end
            return false
        end
        return false
    end) ~= nil
end

--- Redo the last undone change.
---@return boolean success
local function Redo()
    if not initialized then return false end
    return UndoRedo.redo(function(cmd)
        if cmd.type == "setting" then
            local mod = Core.getMod(cmd.modId)
            if mod and mod.settings then
                Resolver.setValue(mod.settings, cmd.key, cmd.newValue)
                Core.markDirty()
                return true
            end
            return false
        end
        return false
    end) ~= nil
end

--- Check if undo is available.
---@return boolean
local function CanUndo()
    if not initialized then return false end
    return UndoRedo.canUndo()
end

--- Check if redo is available.
---@return boolean
local function CanRedo()
    if not initialized then return false end
    return UndoRedo.canRedo()
end

-- ============================================================================
-- Engine Panel (overlay for all engine settings)
-- ============================================================================

local enginePanelOpen = false
local enginePanelTarget = nil  -- modId to show, or nil for all

local engineDefs = {
    { id = "0-Engine-UI",    icon = "\u{2728}", color = {0.2, 0.4, 0.9}, version = "v0.5.0" },
    { id = "0-Engine-Log",   icon = "\u{1F4DC}", color = {0.2, 0.65, 0.3}, version = "v1.1.0" },
    { id = "0-Engine-Config", icon = "\u{2699}", color = {0.7, 0.35, 0.8}, version = "v0.1.0" },
}

local function drawEngineIconBar()
    for _, eng in ipairs(engineDefs) do
        ImGui.PushStyleColor(ImGuiCol.Button, eng.color[1], eng.color[2], eng.color[3], 1)
        if ImGui.Button(eng.icon .. "##" .. eng.id, 28, 28) then
            Core.setSelectedMod(eng.id)
        end
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text(eng.id)
            ImGui.TextDisabled(eng.version)
            ImGui.EndTooltip()
        end
        ImGui.PopStyleColor()
        ImGui.SameLine()
    end
    ImGui.SameLine()
    ImGui.Dummy(0, 0)  -- end the same-line row
end

--- Draw the engine-only content panel (when an engine is selected)
local function drawEngineContent(mod)
    local spec = mod.spec or {}

    -- Header
    ImGui.Text(spec.name or "Unknown")
    if spec.version then ImGui.SameLine(); ImGui.TextDisabled(spec.version) end
    ImGui.Separator()
    if spec.description then ImGui.TextWrapped(spec.description); ImGui.Spacing() end
    ImGui.Separator()
    ImGui.Spacing()

    -- Schema settings
    if mod.renderMode == "schema" or mod.renderMode == "hybrid" then
        if SettingsRenderer and SettingsRenderer.renderSettings then
            local changed = SettingsRenderer.renderSettings(mod.spec._modId or "", spec, mod.settings)
            if changed and StateSync then
                StateSync.autoSave(0)
            end
        end
    end
end

-- ============================================================================
-- Sidebar Drawing
-- ============================================================================

local function drawSidebar()
    -- Engine icon bar (always visible at top)
    drawEngineIconBar()

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Search bar
    local query = Core.getSearchQuery()
    ImGui.SetNextItemWidth(-1)
    local newQuery, queryChanged = ImGui.InputTextWithHint("##cfgsearch", "Search mods...", query or "", 256)
    if queryChanged then
        Core.setSearchQuery(newQuery)
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Mod list
    local modIds = Core.getSortedModIds()
    local selectedMod = Core.getSelectedMod()

    for _, modId in ipairs(modIds) do
        local mod = Core.getMod(modId)
        if mod then
            local spec = mod.spec or {}
            local label = spec.name or modId

            -- Filter by search query
            local matchesQuery = true
            if query and #query > 0 then
                local nameMatch = string.find(label:lower(), query:lower(), 1, true)
                local idMatch = string.find(modId:lower(), query:lower(), 1, true)
                matchesQuery = nameMatch or idMatch
            end

            if matchesQuery then
                local isSelected = selectedMod == modId

                -- Pin/favorite indicators
                local prefix = ""
                if mod.pinned then prefix = prefix .. "* " end
                if mod.favorite then prefix = prefix .. "+ " end

                if ImGui.Selectable(prefix .. label, isSelected) then
                    Core.setSelectedMod(modId)
                end

                -- Tooltip
                if ImGui.IsItemHovered() and spec.description then
                    ImGui.BeginTooltip()
                    ImGui.Text(spec.description)
                    if spec.version then
                        ImGui.Text("Version: " .. spec.version)
                    end
                    if spec.author then
                        ImGui.Text("Author: " .. spec.author)
                    end
                    ImGui.EndTooltip()
                end
            end
        end
    end

    -- Show message if no mods
    if #modIds == 0 then
        ImGui.Spacing()
        ImGui.TextDisabled("No mods registered")
        ImGui.TextDisabled("Use ConfigEngine.Register()")
    end
end

-- ============================================================================
-- Content Area Drawing
-- ============================================================================

local function drawContent()
    local selectedMod = Core.getSelectedMod()

    if not selectedMod then
        ImGui.Spacing(20)
        ImGui.TextDisabled("Select a mod from the sidebar")
        ImGui.Spacing()
        ImGui.TextDisabled("to view and configure its settings.")
        return
    end

    local mod = Core.getMod(selectedMod)
    if not mod then
        ImGui.Text("Mod not found: " .. selectedMod)
        return
    end

    local spec = mod.spec or {}
    spec._modId = selectedMod  -- stash for renderer

    -- Mod header
    ImGui.Text(spec.name or selectedMod)
    ImGui.Separator()
    if spec.version then ImGui.Text("Version: " .. spec.version) end
    if spec.author then ImGui.Text("Author: " .. spec.author) end
    if spec.description then ImGui.TextWrapped(spec.description) end
    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Settings
    if mod.renderMode == "schema" or mod.renderMode == "hybrid" then
        if SettingsRenderer and SettingsRenderer.renderSettings then
            local changed = SettingsRenderer.renderSettings(selectedMod, spec, mod.settings)
            if changed then
                -- Apply live effects for engine settings
                if spec.settings then
                    for key, _ in pairs(spec.settings) do
                        if mod.settings[key] ~= nil then
                            applySettingLive(selectedMod, key, mod.settings[key])
                        end
                    end
                end
                if StateSync then StateSync.autoSave(0) end
            end
        end
    end

    -- Custom draw
    if (mod.renderMode == "custom" or mod.renderMode == "hybrid") and spec.draw then
        local modCtx = { modId = selectedMod, spec = spec }
        setmetatable(modCtx, {
            __index = function(_, k)
                if ImGui[k] then return ImGui[k] end
                return nil
            end
        })
        local ok, err = pcall(spec.draw, modCtx)
        if not ok then
            ImGui.TextColored(1, 0.3, 0.3, 1, "Draw error: " .. tostring(err))
        end
    end

    -- Reset button
    ImGui.Spacing()
    ImGui.Separator()
    if ImGui.Button("Reset to Defaults") then
        local oldSettings = {}
        for k, v in pairs(mod.settings or {}) do oldSettings[k] = v end
        local newSettings = Resolver.resolveSettings(spec, nil)
        local cmd = UndoRedo.makePresetCommand(selectedMod, oldSettings, newSettings, "Reset to Defaults")
        UndoRedo.execute(cmd, function(c)
            Core.setMod(c.modId, { settings = c.newSettings })
            Core.markDirty()
            return true
        end)
    end
end

-- ============================================================================
-- Main Draw Function
-- ============================================================================

local function draw()
    if not overlayOpen then return end
    if not initialized then return end

    -- Theme push (must be balanced with pop)
    if UIEngine and UIEngine.Theme and UIEngine.Theme.PushTheme then
        UIEngine.Theme.PushTheme()
    end

    -- Create the main window
    ImGui.SetNextWindowSize(800, 600, ImGuiCond.FirstUseEver)

    if ImGui.Begin("Config Engine") then
        -- Menu bar
        if ImGui.BeginMenuBar() then
            if ImGui.BeginMenu("Edit") then
                if ImGui.MenuItem("Undo", nil, false, CanUndo()) then
                    Undo()
                end
                if ImGui.MenuItem("Redo", nil, false, CanRedo()) then
                    Redo()
                end
                ImGui.EndMenu()
            end
            if ImGui.BeginMenu("View") then
                local compact = Core.isCompactMode()
                if ImGui.MenuItem("Compact Mode", nil, compact) then
                    Core.toggleCompactMode()
                end
                ImGui.EndMenu()
            end
            ImGui.EndMenuBar()
        end

        -- Main content: sidebar + content area
        local sidebarWidth = Core.getSidebarWidth()

        -- Sidebar
        ImGui.BeginChild("##cfgsidebar", sidebarWidth, 0, true)
        drawSidebar()
        ImGui.EndChild()

        ImGui.SameLine()

        -- Content area
        ImGui.BeginChild("##cfgcontent", 0, 0, true)
        drawContent()
        ImGui.EndChild()
    end
    ImGui.End()

    -- Theme pop
    if UIEngine and UIEngine.Theme and UIEngine.Theme.PopTheme then
        UIEngine.Theme.PopTheme()
    end
end

-- ============================================================================
-- Engine Registration (must be defined BEFORE initModules calls it)
-- ============================================================================

local function registerEngines()
    if not ModManager then
        local msg = "ModManager not loaded, cannot register engines"
        print("[ConfigEngine] " .. msg)
        if log then log.error(msg) end
        return
    end

    -- Try to load EngineSchemas via multiple methods
    local schemas = EngineSchemas
    if not schemas then
        local method = nil
        local errMsg = nil

        -- Method 1: pcall require with dot path (standard Lua)
        local ok, loaded = pcall(require, "config.engine_schemas")
        if ok and loaded and type(loaded) == "table" then
            schemas = loaded
            EngineSchemas = loaded
            method = "require(dot)"
        else
            errMsg = tostring(loaded)
        end

        -- Method 2: pcall require with slash path (CET convention)
        if not schemas then
            ok, loaded = pcall(require, "config/engine_schemas")
            if ok and loaded and type(loaded) == "table" then
                schemas = loaded
                EngineSchemas = loaded
                method = "require(slash)"
            else
                errMsg = errMsg .. " | " .. tostring(loaded)
            end
        end

        -- Method 3: loadfile directly
        if not schemas then
            local f, ferr = loadfile("config/engine_schemas.lua")
            if f then
                local loadOk, loadResult = pcall(f)
                if loadOk and type(loadResult) == "table" then
                    schemas = loadResult
                    EngineSchemas = loadResult
                    method = "loadfile"
                else
                    errMsg = errMsg .. " | loadfile: " .. tostring(loadResult)
                end
            else
                errMsg = errMsg .. " | loadfile: " .. tostring(ferr)
            end
        end

        if schemas then
            print("[ConfigEngine] Loaded engine_schemas via " .. method)
            if log then log.info("Loaded engine_schemas via " .. method) end
        else
            print("[ConfigEngine] FAILED to load config.engine_schemas: " .. tostring(errMsg))
            if log then log.error("FAILED to load config.engine_schemas: " .. tostring(errMsg)) end
            return
        end
    end

    if not schemas then
        print("[ConfigEngine] No engine schemas to register")
        return
    end

    local count = 0
    for engineId, schema in pairs(schemas) do
        if not Core.getMod(engineId) then
            local regOk, err = ModManager.register(engineId, schema)
            if regOk then
                print("[ConfigEngine] Registered engine: " .. engineId)
                if log then log.info("Registered engine: " .. engineId) end
                count = count + 1
            else
                print("[ConfigEngine] Failed to register " .. engineId .. ": " .. tostring(err))
                if log then log.warn("Failed to register " .. engineId .. ": " .. tostring(err)) end
            end
        end
    end
    if count > 0 then
        print("[ConfigEngine] Registered " .. count .. " engine(s)")
        if log then log.info("Registered " .. count .. " engine(s)") end
    end
end

--- Apply a setting change to the live UI-Engine (e.g. theme changes)
local function applySettingLive(modId, key, value)
    if modId == "0-Engine-UI" and UIEngine then
        if key == "currentTheme" and UIEngine.SetTheme then
            UIEngine.SetTheme(value)
        end
    end
end

--- Apply all saved engine settings to their live counterparts (called after state load)
local function applySavedEngineSettings()
    if not UIEngine then return end
    local uiMod = Core.getMod("0-Engine-UI")
    if uiMod and uiMod.settings then
        if uiMod.settings.currentTheme and UIEngine.SetTheme then
            UIEngine.SetTheme(uiMod.settings.currentTheme)
        end
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

local function initModules()
    if initialized then return end

    -- Resolve UI-Engine (must be after onInit when event system is ready)
    UIEngine = GetMod("0-Engine-UI")

    -- Resolve Log-Engine (optional)
    LogEngine = GetMod("0-Engine-Log")
    if LogEngine then
        local ok, logger = pcall(LogEngine.CreateLogger, "Config-Engine", { minLevel = "debug" })
        if ok and logger then
            log = logger
            print("[ConfigEngine] Log-Engine connected")
        end
    end

    -- Initialize core
    if Core then
        Core.init()
        if UIEngine and UIEngine.Events then
            Core.setEventEmitter(function(event, ...)
                UIEngine.Events.emit(event, ...)
            end)
        end
    end

    -- Initialize modules
    if ModManager then
        ModManager.init({
            core = Core,
            events = UIEngine and UIEngine.Events or { emit = function() end },
            uiEngine = UIEngine,
            logger = log,
        })
    end

    if SettingsRenderer then
        SettingsRenderer.init({
            core = Core,
            events = UIEngine and UIEngine.Events or { emit = function() end },
            components = UIEngine and UIEngine.Components or nil,
            undoRedo = UndoRedo,
        })
    end

    if UndoRedo then
        UndoRedo.init({ maxSteps = 50 })
    end

    if StateSync then
        StateSync.init({
            core = Core,
            storage = UIEngine and UIEngine.Storage,
            logger = log,
        })
        StateSync.loadAll()
    end

    initialized = true
    print("[ConfigEngine] Initialized")
    if log then log.info("ConfigEngine initialized") end

    -- Register engine schemas
    registerEngines()

    -- Apply saved settings to live engines (e.g. theme)
    applySavedEngineSettings()
end

-- ============================================================================
-- CET Callbacks
-- ============================================================================

---@diagnostic disable-next-line:lowercase-global
function onInit()
    print("[ConfigEngine] onInit() CALLED")
    initModules()
end

---@diagnostic disable-next-line:lowercase-global
function onDraw()
    if not overlayOpen then return end
    if not initialized then return end

    drawFrameCount = drawFrameCount + 1

    -- Periodically re-scan for late-loading mods (DevKit, TestingMod, etc.)
    if drawFrameCount % rescanInterval == 0 then
        registerEngines()
    end

    -- Draw window (wrapped in single pcall per CET requirement)
    local drawOk, drawErr = pcall(draw)
    if not drawOk then
        if log then log.error("Draw error: " .. tostring(drawErr)) end
        print("[ConfigEngine] Draw error: " .. tostring(drawErr))
    end
end

---@diagnostic disable-next-line:lowercase-global
function onShutdown()
    if not initialized then return end
    if StateSync then
        StateSync.flush()
    end
    initialized = false
    print("[ConfigEngine] Shutdown")
    if log then log.info("ConfigEngine shutdown") end
end

-- ============================================================================
-- CET Event Registration
-- ============================================================================

registerForEvent("onInit", onInit)
registerForEvent("onDraw", onDraw)
registerForEvent("onShutdown", onShutdown)

registerForEvent("onOverlayOpen", function()
    overlayOpen = true
end)

registerForEvent("onOverlayClose", function()
    overlayOpen = false
    if StateSync then
        StateSync.flush()
    end
end)

-- ============================================================================
-- Public API Global
-- ============================================================================

ConfigEngine = {
    -- Core API
    Register = Register,
    Unregister = Unregister,
    GetMod = GetModInfo,
    GetMods = GetModList,

    -- Settings API
    GetSettings = GetModSettings,
    SetSettings = SetModSettings,
    ResetSettings = ResetModSettings,

    -- Undo/Redo
    Undo = Undo,
    Redo = Redo,
    CanUndo = CanUndo,
    CanRedo = CanRedo,

    -- Category API
    SetCategory = SetModCategory,
    GetCategory = GetModCategory,

    -- Window API
    IsManaged = IsManaged,
    DetachMod = DetachMod,
    ReattachMod = ReattachMod,

    -- Internal (for advanced use)
    Core = Core,
    Schema = Schema,
    Resolver = Resolver,
    UndoRedo = UndoRedo,
    ModManager = ModManager,
    SettingsRenderer = SettingsRenderer,
    StateSync = StateSync,
}

-- Return for GetMod() resolution
return ConfigEngine
