-- Config-Engine Content Area
-- Mode-switching content panel: mod settings, engine settings, test results.

---@class CfgContentArea
local M = {}

-- Dependencies (late-bound)
local Core = nil
local SettingsRenderer = nil
local CfgResolver = nil
local CfgUndoRedo = nil
local CfgStateSync = nil
local TestResults = nil
local TestRunner = nil

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
        elseif key == "accentColor" and Core and Core.setAccentColor then
            Core.setAccentColor(value)
        elseif key == "autoSave" and Core and Core.setAutoSave then
            Core.setAutoSave(value)
        elseif key == "showSidebar" and Core and Core.setSidebarOpen then
            Core.setSidebarOpen(value)
        elseif key == "showLoggerOverlay" then
            local logMod = ModEngine and ModEngine.Logger
            if logMod and logMod.SetOverlay then
                logMod.SetOverlay(value)
            end
        elseif key == "maxDebugPerFrame" then
            local logMod = ModEngine and ModEngine.Logger
            if logMod and logMod.SetMaxDebugPerFrame then
                logMod.SetMaxDebugPerFrame(value)
            end
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
        if key == "sortMode" and Core then
            local _, sortAsc = Core.getSortMode()
            Core.setSortMode(value, sortAsc)
        elseif key == "sortAscending" and Core then
            local sortMode = Core.getSortMode()
            Core.setSortMode(sortMode, value)
        elseif key == "sidebarWidth" and Core and Core.setSidebarWidth then
            Core.setSidebarWidth(value)
        elseif key == "compactMode" and Core and Core.setCompactMode then
            Core.setCompactMode(value)
        elseif key == "maxUndoSteps" or key == "maxRedoSteps" then
            -- Re-initialize undo/redo with new limits
            local cfgMod = Core.getMod("0-Engine-Config")
            if cfgMod and cfgMod.settings and CfgUndoRedo then
                CfgUndoRedo.init({
                    maxSteps = cfgMod.settings.maxUndoSteps or 50,
                    maxRedoSteps = cfgMod.settings.maxRedoSteps or 50,
                })
            end
        end
    end
end

--- Initialize the content area module.
---@param deps table { core: CfgCore, settingsRenderer: SettingsRenderer, resolver: SettingsResolver, undoRedo: UndoRedo, stateSync: StateSync, testResults: TestResults, testRunner: TestRunner }
---@return nil
function M.init(deps)
    Core = deps.core
    SettingsRenderer = deps.settingsRenderer
    CfgResolver = deps.resolver
    CfgUndoRedo = deps.undoRedo
    CfgStateSync = deps.stateSync
    TestResults = deps.testResults
    TestRunner = deps.testRunner
end

--- Draw the content area (dispatches based on contentMode).
---@return nil
function M.draw()
    if not Core then return end

    local mode = Core.getContentMode()

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
    local selectedMod = Core.getSelectedMod()
    if not selectedMod then
        ImGui.Spacing(20)
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

    -- Mod header
    ImGui.Text(spec.name or selectedMod)
    ImGui.Separator()
    if spec.version then ImGui.Text("Version: " .. spec.version) end
    if spec.author then ImGui.Text("Author: " .. spec.author) end
    if spec.description then ImGui.TextWrapped(spec.description) end

    -- Test badge in header
    if TestResults then
        local r = TestResults.get(selectedMod)
        if r then
            ImGui.SameLine()
            if r.status == "pass" then
                ImGui.TextColored(0.3, 0.9, 0.3, 1, "✓ " .. r.passed .. "/" .. (r.passed + r.failed))
            elseif r.status == "fail" then
                ImGui.TextColored(0.9, 0.9, 0.2, 1, "⚠ " .. r.passed .. "/" .. (r.passed + r.failed))
            else
                ImGui.TextColored(0.9, 0.3, 0.3, 1, "✗ Error")
            end
        end
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- Settings
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
                if CfgStateSync then CfgStateSync.autoSave(0) end
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

-- ====================================================================
-- Settings Panel (engine settings — tabbed)
-- ====================================================================
function drawSettingsPanel()
    ImGui.Text("Engine Settings")
    ImGui.Separator()

    -- Tab bar for engine settings
    if ImGui.BeginTabBar("##engine_settings_tabs") then
        if ImGui.BeginTabItem("UI-Engine") then
            drawEngineSettings("0-Engine-UI")
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Log-Engine") then
            drawEngineSettings("0-Engine-Log")
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Config-Engine") then
            drawEngineSettings("0-Engine-Config")
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end

    -- Back to mod view
    ImGui.Spacing()
    if ImGui.Button("Back to Mods") then
        Core.setContentMode("mod")
    end
end

--- Draw settings for a specific engine.
---@param engineId string The engine mod ID
function drawEngineSettings(engineId)
    local mod = Core.getMod(engineId)
    if not mod then
        ImGui.TextDisabled("No settings available for " .. engineId)
        return
    end

    local spec = mod.spec or {}
    if SettingsRenderer and SettingsRenderer.renderSettings and mod.settings then
        local changed = SettingsRenderer.renderSettings(engineId, spec, mod.settings)
        if changed then
            if spec.settings then
                for key, _ in pairs(spec.settings) do
                    if mod.settings[key] ~= nil then
                        applySettingLive(engineId, key, mod.settings[key])
                    end
                end
            end
            if CfgStateSync then CfgStateSync.autoSave(0) end
        end
    else
        ImGui.TextDisabled("Settings renderer not available")
    end
end

-- ====================================================================
-- Test Panel (central test management)
-- ====================================================================
function drawTestPanel()
    ImGui.Text("Test Results")
    ImGui.Separator()

    if not TestResults or not TestRunner then
        ImGui.TextDisabled("Test system not initialized")
        return
    end

    -- Aggregate stats
    local stats = TestResults.getAggregateStats()
    ImGui.Text(string.format("Total: %d mods with tests", stats.total))
    ImGui.TextColored(0.3, 0.9, 0.3, 1, string.format("  Passing: %d", stats.passing))
    ImGui.TextColored(0.9, 0.9, 0.2, 1, string.format("  Failing: %d", stats.failing))
    ImGui.TextColored(0.9, 0.3, 0.3, 1, string.format("  Errors: %d", stats.errors))

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
