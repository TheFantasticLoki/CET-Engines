-- Config-Engine Content Area
-- Mode-switching content panel: mod settings, engine settings, test results.

---@class CfgContentArea
local M = {}

-- Dependencies (late-bound)
local Core = nil
local UIEngineCore = nil  -- UI-Engine's Core (for live settings like accent color, auto-save)
local SettingsRenderer = nil
local CfgResolver = nil
local CfgUndoRedo = nil
local CfgStateSync = nil
local TestResults = nil
local TestRunner = nil
local Tokens = nil
local Components = nil  -- UI-Engine component library for modern settings rendering
local log = nil  -- Dedicated logger for content area diagnostics

local function resolveTokens()
    if Tokens then return end
    local ok, mod = pcall(require, "ui/tokens")
    if ok then Tokens = mod end
end

local function resolveComponents()
    if Components then return end
    local ok, mod = pcall(require, "ui/components")
    if ok then Components = mod end
end

local function resolveLogger()
    if log then return end
    local Utils = require("ui/utils")
    log = Utils.ResolveLogger("ContentArea", "debug")
    if log then
        log.info("ContentArea logger initialized")
    else
        print("[ContentArea] WARNING: Could not initialize logger via ResolveLogger")
    end
end

--- Apply a setting change to the live engine (e.g. theme changes)
---@param modId string The mod identifier
---@param key string The setting key
---@param value any The new value
---@return nil
local function applySettingLive(modId, key, value)
    if not ModEngine then return end

    -- UI-Engine live settings
    if modId == "0-Engine-UI" then
        if key == "currentTheme" and ModEngine.SetTheme then
            ModEngine.SetTheme(value)
        elseif key == "contrastLevel" and ModEngine.SetContrastLevel then
            ModEngine.SetContrastLevel(value)
        elseif key == "accentColor" and UIEngineCore and UIEngineCore.setAccentColor then
            UIEngineCore.setAccentColor(value)
        elseif key == "autoSave" then
            -- Sync auto-save toggle to both CfgCore (state_sync checks it) and UIEngineCore
            if Core and Core.setAutoSave then Core.setAutoSave(value) end
            if UIEngineCore and UIEngineCore.setAutoSave then UIEngineCore.setAutoSave(value) end
        elseif key == "showSidebar" and UIEngineCore and UIEngineCore.setSidebarOpen then
            UIEngineCore.setSidebarOpen(value)
        end
    end

    -- Log-Engine live settings
    if modId == "0-Engine-Log" then
        local logEngine = ModEngine and ModEngine._LogEngine
        if key == "globalMinLevel" and ModEngine.SetGlobalLevel then
            ModEngine.SetGlobalLevel(value)
        elseif key == "logDir" and logEngine and logEngine.setLogDir then
            logEngine.setLogDir(value)
        elseif key == "maxFileSize" and logEngine and logEngine.setMaxFileSize then
            logEngine.setMaxFileSize(value)
        elseif key == "maxFiles" and logEngine and logEngine.setMaxFiles then
            logEngine.setMaxFiles(value)
        elseif key == "maxDebugPerFrame" and logEngine and logEngine.setMaxDebugPerFrame then
            logEngine.setMaxDebugPerFrame(value)
        elseif key == "dedupEnabled" and logEngine and logEngine.setDedupEnabled then
            logEngine.setDedupEnabled(value)
        elseif key == "dedupMaxEntries" and logEngine and logEngine.setDedupMaxEntries then
            logEngine.setDedupMaxEntries(value)
        elseif key == "ringSize" and logEngine and logEngine.setRingSize then
            logEngine.setRingSize(value)
        end
    end

    -- Config-Engine live settings
    if modId == "0-Engine-Config" then
        if key == "sidebarWidth" and Core and Core.setSidebarWidth then
            Core.setSidebarWidth(value)
        elseif key == "autoSaveDelay" and CfgStateSync and CfgStateSync.setAutoSaveDelay then
            CfgStateSync.setAutoSaveDelay(value)
        end
    end
end

--- Initialize the content area module.
---@param deps table { core: CfgCore, uiCore: Core|nil, settingsRenderer: SettingsRenderer, resolver: SettingsResolver, undoRedo: UndoRedo, stateSync: StateSync, testResults: TestResults, testRunner: TestRunner, components: table|nil }
---@return nil
function M.init(deps)
    resolveLogger()
    if log then log.info("M.init: START") end

    Core = deps.core
    UIEngineCore = deps.uiCore
    SettingsRenderer = deps.settingsRenderer
    CfgResolver = deps.resolver
    CfgUndoRedo = deps.undoRedo
    CfgStateSync = deps.stateSync
    TestResults = deps.testResults
    TestRunner = deps.testRunner
    Components = deps.components

    if log then log.info("M.init: END") end
end

--- Draw the content area (dispatches based on contentMode).
---@return nil
function M.draw()
    resolveLogger()
    if log then log.info("M.draw: START") end

    if not Core then
        if log then log.warn("M.draw: Core is nil, returning") end
        return
    end

    local mode = Core.getContentMode()
    if log then log.info(string.format("M.draw: mode='%s'", tostring(mode))) end

    if mode == "settings" then
        drawSettingsPanel()
    elseif mode == "tests" then
        drawTestPanel()
    else
        drawModPanel()
    end
end

-- ====================================================================
-- Mod Panel (default — shows selected mod's settings)
-- ====================================================================
function drawModPanel()
    resolveLogger()
    if log then log.info("drawModPanel: START") end

    local selectedMod = Core.getSelectedMod()
    if log then log.info(string.format("drawModPanel: selectedMod=%s", tostring(selectedMod))) end

    if not selectedMod then
        ImGui.Dummy(0, 20)
        ImGui.TextDisabled("Select a mod from the sidebar")
        ImGui.TextDisabled("to view and configure its settings.")
        return
    end

    -- Redirect engine internal mods to the dedicated settings panel
    if selectedMod:sub(1, 9) == "0-Engine-" then
        Core.setContentMode("settings")
        return
    end

    local mod = Core.getMod(selectedMod)
    if not mod then
        ImGui.Text("Mod not found: " .. selectedMod)
        return
    end

    local spec = mod.spec or {}
    spec._modId = selectedMod

    -- For "custom" mode: the draw function owns the entire panel (no header clutter)
    if mod.renderMode == "custom" and spec.draw then
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
        return
    end

    -- For "external" mode: show descriptive message
    if mod.renderMode == "external" then
        ImGui.Spacing()
        ImGui.TextDisabled("This mod manages its own UI externally.")
        ImGui.TextDisabled("No settings are exposed to Config-Engine.")
        return
    end

    -- For "schema" and "hybrid" modes: compact header with info popup
    -- Name
    ImGui.Text(spec.name or selectedMod)

    -- Info button ( ⓘ ) — opens a popup with mod details
    ImGui.SameLine()
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 10)
    local infoColor = Tokens and Tokens.color4n("primary") or {r=0.25, g=0.45, b=0.75}
    ImGui.PushStyleColor(ImGuiCol.Button, infoColor.r, infoColor.g, infoColor.b, 0.6)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, infoColor.r, infoColor.g, infoColor.b, 0.8)
    ImGui.PushStyleColor(ImGuiCol.Text, 1, 1, 1, 0.9)
    local infoId = "i##info_" .. selectedMod
    if ImGui.Button(infoId, 18, 18) then
        ImGui.OpenPopup("##info_popup_" .. selectedMod)
    end
    ImGui.PopStyleColor(3)
    ImGui.PopStyleVar(1)

    if ImGui.BeginPopup("##info_popup_" .. selectedMod) then
        ImGui.Text(spec.name or selectedMod)
        ImGui.Separator()
        if spec.version then ImGui.TextDisabled("Version:  v" .. spec.version) end
        if spec.author then ImGui.TextDisabled("Author:   " .. spec.author) end
        ImGui.TextDisabled("Mod ID:   " .. selectedMod)
        if mod.renderMode then ImGui.TextDisabled("Mode:     " .. mod.renderMode) end
        local assignment = Core.getModCategory(selectedMod)
        if assignment and assignment.category then
            local catText = assignment.category
            if assignment.subcategory then catText = catText .. " › " .. assignment.subcategory end
            ImGui.TextDisabled("Category: " .. catText)
        end
        if spec.description and spec.description ~= "" then
            ImGui.Separator()
            ImGui.TextWrapped(spec.description)
        end
        -- Test status
        if TestResults then
            local r = TestResults.get(selectedMod)
            if r then
                ImGui.Separator()
                if r.status == "pass" then
                    local c = Tokens and Tokens.color4n("success") or {r=0.3, g=0.9, b=0.3}
                    ImGui.TextColored(c.r, c.g, c.b, 1, string.format("Tests: %d/%d passing", r.passed, r.passed + r.failed))
                elseif r.status == "fail" then
                    local c = Tokens and Tokens.color4n("warning") or {r=0.9, g=0.9, b=0.2}
                    ImGui.TextColored(c.r, c.g, c.b, 1, string.format("Tests: %d/%d passing", r.passed, r.passed + r.failed))
                else
                    local c = Tokens and Tokens.color4n("error") or {r=0.9, g=0.3, b=0.3}
                    ImGui.TextColored(c.r, c.g, c.b, 1, "Tests: Error")
                end
            end
        end
        ImGui.EndPopup()
    end

    -- Test badge (inline, right-aligned)
    if TestResults then
        local r = TestResults.get(selectedMod)
        if r then
            local badgeText = r.passed .. "/" .. (r.passed + r.failed)
            local badgeColor = r.status == "pass" and (Tokens and Tokens.color4n("success") or {r=0.3, g=0.9, b=0.3})
                or r.status == "fail" and (Tokens and Tokens.color4n("warning") or {r=0.9, g=0.9, b=0.2})
                or (Tokens and Tokens.color4n("error") or {r=0.9, g=0.3, b=0.3})
            local badgeW = ImGui.CalcTextSize(badgeText)
            local avail = ImGui.GetContentRegionAvail()
            ImGui.SameLine(avail - badgeW - 4)
            ImGui.TextColored(badgeColor[1], badgeColor[2], badgeColor[3], 0.8, badgeText)
        end
    end

    ImGui.Separator()

    -- Settings (schema and hybrid modes)
    if mod.renderMode == "schema" or mod.renderMode == "hybrid" then
        if SettingsRenderer and SettingsRenderer.renderSettings then
            local changed = SettingsRenderer.renderSettings(selectedMod, spec, mod.settings)
            if changed then
                if spec.settings then
                    for key, _ in pairs(spec.settings) do
                        if mod.settings[key] ~= nil then
                            applySettingLive(selectedMod, key, mod.settings[key])
                        end
                    end
                end
                if Core and Core.markDirty then
                    Core.markDirty()
                end
            end
        end
    end

    -- Custom draw (hybrid mode only — custom mode returned above)
    if mod.renderMode == "hybrid" and spec.draw then
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

    -- Reset button (only for schema/hybrid modes that have settings)
    if mod.renderMode == "schema" or mod.renderMode == "hybrid" then
        ImGui.Spacing()
        ImGui.Separator()
        if ImGui.Button("Reset to Defaults") then
            if CfgResolver and CfgResolver.resolveSettings and CfgUndoRedo and CfgUndoRedo.makePresetCommand then
                local oldSettings = {}
                for k, v in pairs(mod.settings or {}) do oldSettings[k] = v end
                local newSettings = CfgResolver.resolveSettings(spec, nil)
                local cmd = CfgUndoRedo.makePresetCommand(selectedMod, oldSettings, newSettings, "Reset to Defaults")
                CfgUndoRedo.execute(cmd, function(c)
                    Core.setMod(c.modId, { settings = c.newSettings })
                    Core.markDirty()
                    return true
                end)
            end
        end
    end
end

-- ====================================================================
-- Settings Panel (engine settings — tabbed)
-- ====================================================================
function drawSettingsPanel()
    resolveTokens()
    resolveComponents()
    resolveLogger()

    if log then log.info("drawSettingsPanel: START") end

    -- Header with icon and version
    local headerColor = Tokens and Tokens.color4n("primary") or { r = 0.4, g = 0.6, b = 1.0 }
    ImGui.TextColored(headerColor.r, headerColor.g, headerColor.b, 1, "Engine Settings")
    ImGui.Separator()
    ImGui.Spacing()

    local availW, availH = ImGui.GetContentRegionAvail()
    if log then log.info(string.format("drawSettingsPanel: avail=%.0fx%.0f", availW, availH)) end

    -- Tab bar for engine settings
    local tabBarOpen = ImGui.BeginTabBar("##engine_settings_tabs", ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)
    if log then log.info(string.format("drawSettingsPanel: BeginTabBar returned: %s", tostring(tabBarOpen))) end

    if tabBarOpen then
        -- UI Engine tab
        local tabUI = ImGui.BeginTabItem("UI Engine")
        if log then log.info(string.format("drawSettingsPanel: BeginTabItem 'UI Engine' returned: %s", tostring(tabUI))) end
        if tabUI then
            drawUIEngineSettings()
            ImGui.EndTabItem()
        end

        -- Log Engine tab
        local tabLog = ImGui.BeginTabItem("Log Engine")
        if log then log.info(string.format("drawSettingsPanel: BeginTabItem 'Log Engine' returned: %s", tostring(tabLog))) end
        if tabLog then
            drawLogEngineSettings()
            ImGui.EndTabItem()
        end

        -- Config Engine tab
        local tabCfg = ImGui.BeginTabItem("Config Engine")
        if log then log.info(string.format("drawSettingsPanel: BeginTabItem 'Config Engine' returned: %s", tostring(tabCfg))) end
        if tabCfg then
            drawConfigEngineSettings()
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end

    -- Back to mod view
    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()
    if ImGui.Button("Back to Mods") then
        Core.setContentMode("mod")
    end
end

-- ====================================================================
-- Section card helper — wraps content in a styled child window
-- ====================================================================
local _panelBg = nil
local _muted = nil

local function resolveColors()
    if _panelBg then return end
    _panelBg = Tokens and Tokens.color4n("panel") or { r = 0.06, g = 0.06, b = 0.07 }
    _muted = Tokens and Tokens.color4n("muted") or { r = 0.5, g = 0.5, b = 0.6 }
end

--- Measure content height by rendering it offscreen, then restore cursor.
--- @param buildFn function Content builder
--- @return number Measured height in pixels
local function MeasureContentHeight(buildFn)
    local savedX, savedY = ImGui.GetCursorScreenPos()

    -- Render content invisibly to measure
    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 0.0)
    ImGui.BeginGroup()
    buildFn()
    ImGui.EndGroup()
    ImGui.PopStyleVar(1)

    local _, bottom = ImGui.GetItemRectMax()
    local measuredHeight = bottom - savedY

    -- Restore cursor position
    ImGui.SetCursorScreenPos(savedX, savedY)

    return measuredHeight
end

--- Draw a section card with explicit height calculation.
--- @param id string Unique ID for the section
--- @param buildFn function Content builder
local function SectionCard(id, buildFn)
    resolveColors()
    resolveLogger()

    -- Step 1: Measure content height
    local contentHeight = MeasureContentHeight(buildFn)

    -- Step 2: Add padding (top: 10, bottom: 10)
    local totalHeight = contentHeight + 20

    -- Step 3: Clamp to available space (minimum 50px)
    local availW, availH = ImGui.GetContentRegionAvail()
    totalHeight = math.max(50, math.min(totalHeight, availH))

    if log then log.info(string.format("SectionCard [%s]: measured=%.0f total=%.0f avail=%.0f", id, contentHeight, totalHeight, availH)) end

    -- Step 4: Render with calculated height
    ImGui.PushStyleColor(ImGuiCol.ChildBg, _panelBg.r, _panelBg.g, _panelBg.b, 0.6)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 12, 10)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4)
    ImGui.BeginChild(id, -1, totalHeight, true)

    -- Step 5: Build content
    buildFn()

    ImGui.EndChild()
    ImGui.PopStyleVar(2)
    ImGui.PopStyleColor(1)
end

--- Section title
local function SectionTitle(text)
    resolveColors()
    ImGui.TextColored(_muted.r, _muted.g, _muted.b, 0.7, text)
    ImGui.Spacing()
end

-- ====================================================================
-- UI-Engine Settings (theme, appearance, interface)
-- ====================================================================
function drawUIEngineSettings()
    resolveLogger()
    if log then log.info("drawUIEngineSettings: START") end
    local mod = Core.getMod("0-Engine-UI")
    if not mod then
        if log then log.warn("drawUIEngineSettings: mod NOT FOUND") end
        return
    end
    local s = mod.settings or {}
    if log then log.info(string.format("drawUIEngineSettings: renderMode=%s", tostring(mod.renderMode))) end

    local preW, preH = ImGui.GetContentRegionAvail()
    if log then log.info(string.format("drawUIEngineSettings: avail=%.0fx%.0f", preW, preH)) end

    -- --- Theme Section ---
    SectionCard("##uiengine_theme", function()
        SectionTitle("THEME")

        -- Theme dropdown (full width)
        local themes = {
            "Dark", "Red", "Cyan", "Blue", "Green", "Amber",
            "Purple", "Rose", "Teal", "Midnight", "Orange",
            "Gold", "Pink", "White", "Arasaka", "Light",
        }
        local currentTheme = s.currentTheme or "Dark"
        local currentIdx = 1
        for i, t in ipairs(themes) do
            if t == currentTheme then currentIdx = i; break end
        end
        ImGui.Text("Theme")
        ImGui.SetNextItemWidth(-1)
        local newIdx, _ = ImGui.Combo("##theme_combo", currentIdx - 1, themes, #themes)
        if newIdx ~= currentIdx - 1 then
            local newTheme = themes[newIdx + 1]
            s.currentTheme = newTheme
            applySettingLive("0-Engine-UI", "currentTheme", newTheme)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Accent color (full width)
        ImGui.Text("Accent Color")
        ImGui.SetNextItemWidth(-1)
        local c = s.accentColor or { r = 0.4, g = 0.6, b = 1.0, a = 1.0 }
        local arr = { c.r or 0.4, c.g or 0.6, c.b or 1.0, c.a or 1.0 }
        local colorChanged
        colorChanged, arr[1], arr[2], arr[3], arr[4] = ImGui.ColorEdit4("##accent_color", arr, ImGuiColorEditFlags.NoInputs + ImGuiColorEditFlags.NoLabel)
        if colorChanged then
            local newColor = { r = arr[1], g = arr[2], b = arr[3], a = arr[4] }
            s.accentColor = newColor
            applySettingLive("0-Engine-UI", "accentColor", newColor)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Contrast level slider
        local contrast = s.contrastLevel or 1
        ImGui.Text("Contrast Level")
        ImGui.SetNextItemWidth(-1)
        local newContrast, contrastChanged = ImGui.SliderInt("##contrast", contrast, 1, 3, "%d")
        if contrastChanged then
            s.contrastLevel = newContrast
            applySettingLive("0-Engine-UI", "contrastLevel", newContrast)
            Core.markDirty()
        end
        -- Labels for contrast levels
        local labels = { [1] = "Normal", [2] = "High", [3] = "Very High" }
        ImGui.SameLine()
        ImGui.TextDisabled(labels[newContrast] or "")
    end)

    if log then log.debug("drawUIEngineSettings: after first SectionCard") end
    ImGui.Spacing()
    if log then log.debug("drawUIEngineSettings: after ImGui.Spacing") end

    -- --- Interface Section ---
    SectionCard("##uiengine_interface", function()
        SectionTitle("INTERFACE")

        -- Show Sidebar toggle
        local showSidebar = s.showSidebar
        if showSidebar == nil then showSidebar = true end
        local newSidebar, sidebarChanged = ImGui.Checkbox("Show Sidebar", showSidebar)
        if sidebarChanged then
            s.showSidebar = newSidebar
            applySettingLive("0-Engine-UI", "showSidebar", newSidebar)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Auto-Save toggle
        local autoSave = s.autoSave
        if autoSave == nil then autoSave = true end
        local newAutoSave, autoSaveChanged = ImGui.Checkbox("Auto-Save Settings", autoSave)
        if autoSaveChanged then
            s.autoSave = newAutoSave
            applySettingLive("0-Engine-UI", "autoSave", newAutoSave)
            Core.markDirty()
        end
    end)
    if log then log.debug("drawUIEngineSettings: END - both SectionCards complete") end
end
function drawLogEngineSettings()
    resolveLogger()
    if log then log.info("drawLogEngineSettings: START") end
    local mod = Core.getMod("0-Engine-Log")
    if not mod then
        if log then log.warn("drawLogEngineSettings: mod NOT FOUND") end
        return
    end
    local s = mod.settings or {}
    if log then log.info(string.format("drawLogEngineSettings: renderMode=%s", tostring(mod.renderMode))) end

    -- --- Global Section ---
    SectionCard("##logengine_global", function()
        SectionTitle("GLOBAL")

        -- Min Level
        local levels = { "debug", "info", "warn", "error" }
        local currentLevel = s.globalMinLevel or "debug"
        local levelIdx = 1
        for i, l in ipairs(levels) do
            if l == currentLevel then levelIdx = i; break end
        end
        ImGui.Text("Minimum Log Level")
        ImGui.SetNextItemWidth(-1)
        local newLevelIdx, _ = ImGui.Combo("##min_level", levelIdx - 1, levels, #levels)
        if newLevelIdx ~= levelIdx - 1 then
            local newLevel = levels[newLevelIdx + 1]
            s.globalMinLevel = newLevel
            applySettingLive("0-Engine-Log", "globalMinLevel", newLevel)
            Core.markDirty()
        end
    end)

    ImGui.Spacing()

    -- --- Ring Buffer Section ---
    SectionCard("##logengine_buffer", function()
        SectionTitle("RING BUFFER")

        -- Ring buffer size
        local ringSize = s.ringSize or 1024
        ImGui.Text("Buffer Size (entries)")
        ImGui.SetNextItemWidth(-1)
        local newRing, ringChanged = ImGui.SliderInt("##ring_size", ringSize, 256, 4096, "%d")
        if ringChanged then
            s.ringSize = newRing
            applySettingLive("0-Engine-Log", "ringSize", newRing)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Max debug per frame
        local maxDebug = s.maxDebugPerFrame or 1
        ImGui.Text("Max Debug Messages / Frame")
        ImGui.SetNextItemWidth(-1)
        local newMaxDebug, maxDebugChanged = ImGui.SliderInt("##max_debug", maxDebug, 1, 20, "%d")
        if maxDebugChanged then
            s.maxDebugPerFrame = newMaxDebug
            applySettingLive("0-Engine-Log", "maxDebugPerFrame", newMaxDebug)
            Core.markDirty()
        end
    end)

    ImGui.Spacing()

    -- --- File Output Section ---
    SectionCard("##logengine_file", function()
        SectionTitle("FILE OUTPUT")

        -- Log directory
        local logDir = s.logDir or "logs"
        ImGui.Text("Log Directory")
        ImGui.SetNextItemWidth(-1)
        local newDir, dirChanged = ImGui.InputText("##log_dir", logDir, 256)
        if dirChanged then
            s.logDir = newDir
            applySettingLive("0-Engine-Log", "logDir", newDir)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Max file size
        local fileSizes = { "512 KB", "1 MB", "2 MB", "4 MB" }
        local fileSizeValues = { 512 * 1024, 1024 * 1024, 2 * 1024 * 1024, 4 * 1024 * 1024 }
        local currentSize = s.maxFileSize or (2 * 1024 * 1024)
        local sizeIdx = 3
        for i, v in ipairs(fileSizeValues) do
            if v == currentSize then sizeIdx = i; break end
        end
        ImGui.Text("Max File Size")
        ImGui.SetNextItemWidth(-1)
        local newSizeIdx, _ = ImGui.Combo("##file_size", sizeIdx - 1, fileSizes, #fileSizes)
        if newSizeIdx ~= sizeIdx - 1 then
            local newSize = fileSizeValues[newSizeIdx + 1]
            s.maxFileSize = newSize
            applySettingLive("0-Engine-Log", "maxFileSize", newSize)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Max rotated files
        local maxFiles = s.maxFiles or 5
        ImGui.Text("Max Rotated Files")
        ImGui.SetNextItemWidth(-1)
        local newMaxFiles, maxFilesChanged = ImGui.SliderInt("##max_files", maxFiles, 1, 20, "%d")
        if maxFilesChanged then
            s.maxFiles = newMaxFiles
            applySettingLive("0-Engine-Log", "maxFiles", newMaxFiles)
            Core.markDirty()
        end
    end)

    ImGui.Spacing()

    -- --- Deduplication Section ---
    SectionCard("##logengine_dedup", function()
        SectionTitle("DEDUPLICATION")

        -- Enable dedup
        local dedupEnabled = s.dedupEnabled
        if dedupEnabled == nil then dedupEnabled = true end
        local newDedup, dedupChanged = ImGui.Checkbox("Enable Deduplication", dedupEnabled)
        if dedupChanged then
            s.dedupEnabled = newDedup
            applySettingLive("0-Engine-Log", "dedupEnabled", newDedup)
            Core.markDirty()
        end

        -- Max dedup entries (only show when dedup enabled)
        if s.dedupEnabled then
            ImGui.Spacing()
            local dedupMax = s.dedupMaxEntries or 256
            ImGui.Text("Max Tracked Entries")
            ImGui.SetNextItemWidth(-1)
            local newDedupMax, dedupMaxChanged = ImGui.SliderInt("##dedup_max", dedupMax, 64, 1024, "%d")
            if dedupMaxChanged then
                s.dedupMaxEntries = newDedupMax
                applySettingLive("0-Engine-Log", "dedupMaxEntries", newDedupMax)
                Core.markDirty()
            end
        end
    end)
end

-- ====================================================================
-- Config-Engine Settings (behavior, window)
-- ====================================================================
function drawConfigEngineSettings()
    resolveLogger()
    if log then log.info("drawConfigEngineSettings: START") end
    local mod = Core.getMod("0-Engine-Config")
    if not mod then
        if log then log.warn("drawConfigEngineSettings: mod NOT FOUND") end
        return
    end
    local s = mod.settings or {}
    if log then log.info(string.format("drawConfigEngineSettings: renderMode=%s", tostring(mod.renderMode))) end

    -- --- Behavior Section ---
    SectionCard("##cfgengine_behavior", function()
        SectionTitle("BEHAVIOR")

        -- Auto-save delay
        local saveDelay = s.autoSaveDelay or 5.0
        ImGui.Text("Auto-Save Delay (seconds)")
        ImGui.SetNextItemWidth(-1)
        local newDelay, delayChanged = ImGui.SliderFloat("##save_delay", saveDelay, 0.5, 15.0, "%.1f s")
        if delayChanged then
            s.autoSaveDelay = newDelay
            applySettingLive("0-Engine-Config", "autoSaveDelay", newDelay)
            Core.markDirty()
        end
    end)

    ImGui.Spacing()

    -- --- Window Section ---
    SectionCard("##cfgengine_window", function()
        SectionTitle("WINDOW")

        -- Sidebar width
        local sidebarWidth = s.sidebarWidth or 280
        ImGui.Text("Sidebar Width (px)")
        ImGui.SetNextItemWidth(-1)
        local newWidth, widthChanged = ImGui.SliderInt("##sidebar_w", sidebarWidth, 200, 500, "%d px")
        if widthChanged then
            s.sidebarWidth = newWidth
            applySettingLive("0-Engine-Config", "sidebarWidth", newWidth)
            Core.markDirty()
        end

        ImGui.Spacing()

        -- Default window dimensions (side by side)
        local winW = s.defaultWindowWidth or 900
        local winH = s.defaultWindowHeight or 600
        ImGui.Text("Default Window Size")
        ImGui.SetNextItemWidth(ImGui.GetContentRegionAvail() / 2 - 4)
        local newWinW, winWChanged = ImGui.SliderInt("##win_w", winW, 600, 1920, "%d")
        ImGui.SameLine()
        ImGui.SetNextItemWidth(-1)
        local newWinH, winHChanged = ImGui.SliderInt("##win_h", winH, 400, 1080, "%d")
        if winWChanged then
            s.defaultWindowWidth = newWinW
            Core.markDirty()
        end
        if winHChanged then
            s.defaultWindowHeight = newWinH
            Core.markDirty()
        end
    end)
end

-- ====================================================================
-- Test Panel (central test management)
-- ====================================================================
function drawTestPanel()
    resolveLogger()
    if log then log.info("drawTestPanel: START") end

    ImGui.Text("Test Results")
    ImGui.Separator()

    if not TestResults or not TestRunner then
        if log then log.warn("drawTestPanel: TestResults or TestRunner is nil") end
        ImGui.TextDisabled("Test system not initialized")
        return
    end

    -- Aggregate stats
    local stats = TestResults.getAggregateStats()
    ImGui.Text(string.format("Total: %d mods with tests", stats.total))
    local cPass = Tokens and Tokens.color4n("success") or {r=0.3, g=0.9, b=0.3}
    local cFail = Tokens and Tokens.color4n("warning") or {r=0.9, g=0.9, b=0.2}
    local cErr = Tokens and Tokens.color4n("error") or {r=0.9, g=0.3, b=0.3}
    ImGui.TextColored(cPass.r, cPass.g, cPass.b, 1, string.format("  Passing: %d", stats.passing))
    ImGui.TextColored(cFail.r, cFail.g, cFail.b, 1, string.format("  Failing: %d", stats.failing))
    ImGui.TextColored(cErr.r, cErr.g, cErr.b, 1, string.format("  Errors: %d", stats.errors))

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Run all button
    if ImGui.Button("Run All (Startup)") then
        TestRunner.runAllTests("startup")
    end
    ImGui.SameLine()
    if ImGui.Button("Run All (Full)") then
        TestRunner.runAllTests("full")
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Per-mod results table
    if ImGui.BeginTable("##test_results_table", 4, ImGuiTableFlags.Borders + ImGuiTableFlags.RowBg) then
        ImGui.TableSetupColumn("Mod", ImGuiTableColumnFlags.WidthStretch)
        ImGui.TableSetupColumn("Status", ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableSetupColumn("Results", ImGuiTableColumnFlags.WidthFixed, 80)
        ImGui.TableSetupColumn("Action", ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableHeadersRow()

        local mods = Core.getAllMods()
        for modId, _ in pairs(mods) do
            local mod = Core.getMod(modId)
            if mod then
                local spec = mod.spec or {}
                local r = TestResults.get(modId)

                ImGui.TableNextRow()

                -- Mod name
                ImGui.TableSetColumnIndex(0)
                ImGui.Text(spec.name or modId)

                -- Status
                ImGui.TableSetColumnIndex(1)
                if r then
                    local icon, status = TestResults.getStatusIcon(modId)
                    if status == "pass" then
                        ImGui.TextColored(0.3, 0.9, 0.3, 1, icon)
                    elseif status == "fail" then
                        ImGui.TextColored(0.9, 0.9, 0.2, 1, icon)
                    else
                        ImGui.TextColored(0.9, 0.3, 0.3, 1, icon)
                    end
                else
                    ImGui.TextDisabled("○")
                end

                -- Results
                ImGui.TableSetColumnIndex(2)
                if r then
                    ImGui.Text(string.format("%d/%d", r.passed, r.passed + r.failed))
                else
                    ImGui.TextDisabled("—")
                end

                -- Action
                ImGui.TableSetColumnIndex(3)
                local btnLabel = "Run##" .. modId
                if ImGui.SmallButton(btnLabel) then
                    TestRunner.runModTests(modId, "full")
                end
            end
        end

        ImGui.EndTable()
    end

    -- Back to mod view
    ImGui.Spacing()
    if ImGui.Button("Back to Mods") then
        Core.setContentMode("mod")
    end
end

return M
