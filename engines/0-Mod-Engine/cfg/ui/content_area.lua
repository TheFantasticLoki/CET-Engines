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
    if ModEngine and ModEngine.SetTheme then
        if key == "currentTheme" then
            ModEngine.SetTheme(value)
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

    local mod = Core.getMod(selectedMod)
    if not mod then
        ImGui.Text("Mod not found: " .. selectedMod)
        return
    end

    local spec = mod.spec or {}
    spec._modId = selectedMod

    -- DIAGNOSTIC: Log drawModPanel state
    if not _contentDiagCount then _contentDiagCount = 0 end
    _contentDiagCount = _contentDiagCount + 1
    if _contentDiagCount <= 3 then
        local hasSettings = (spec.settings ~= nil)
        local settingCount = 0
        if hasSettings then for _ in pairs(spec.settings) do settingCount = settingCount + 1 end end
        print(string.format("[ContentArea] drawModPanel #%d: mod=%s, renderMode=%s, hasSettings=%s, count=%d",
            _contentDiagCount, tostring(selectedMod), tostring(mod.renderMode),
            tostring(hasSettings), settingCount))
    end

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
