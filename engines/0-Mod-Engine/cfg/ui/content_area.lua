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
local Glyphs = nil  -- Icon glyph rendering
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

local function resolveGlyphs()
    if Glyphs then return end
    local ok, mod = pcall(require, "ui/components/glyphs")
    if ok then Glyphs = mod end
end

--- Draw a clickable glyph without button background.
--- Uses InvisibleButton for click detection + drawList for rendering.
---@param id string Unique ID for the glyph
---@param iconName string IconGlyphs name (e.g., "InformationOutline")
---@param opts table|nil Options: { size, color, tooltip }
---@return boolean clicked
local function GlyphButton(id, iconName, opts)
    opts = opts or {}
    resolveGlyphs()
    if not Glyphs or not Glyphs.Available() then return false end

    local glyph = Glyphs.Get(iconName, opts.fallback)
    if not glyph then return false end

    local size = opts.size or 20
    local color = opts.color or ImGui.GetColorU32(1.0, 1.0, 1.0, 0.8)

    -- Create invisible clickable area
    local clicked = ImGui.InvisibleButton(id, size, size)

    -- Draw the glyph centered in the button area
    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()
    local btnW = maxX - minX
    local btnH = maxY - minY
    local renderSize = size - 4

    ImGui.ImDrawListAddText(
        ImGui.GetWindowDrawList(),
        renderSize,
        minX + (btnW - renderSize) * 0.5,
        minY + (btnH - renderSize) * 0.5,
        color,
        glyph
    )

    -- Tooltip
    if opts.tooltip and ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(opts.tooltip)
        ImGui.EndTooltip()
    end

    return clicked
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
---@param deps table { core: CfgCore, uiCore: Core|nil, settingsRenderer: SettingsRenderer, resolver: SettingsResolver, undoRedo: UndoRedo, stateSync: StateSync, testResults: TestResults, testRunner: TestRunner, components: table|nil, storage: table|nil }
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

--- Clear cached heights and force re-measurement on next frame.
--- Delegates to SettingsRenderer which owns the actual section height cache.
function M.clearHeightCache()
    if log then log.info("Height cache cleared - will re-measure on next frame") end
end


-- ====================================================================
-- Mod Panel (default — shows selected mod's settings)
-- ====================================================================

--- Draw mod info popup (version, author, description, test status).
---@param selectedMod string The selected mod ID
---@param mod table The mod state
---@param spec table The mod spec
---@return nil
local function drawModInfoPopup(selectedMod, mod, spec)
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
end

--- Draw reset settings button.
---@param selectedMod string The selected mod ID
---@param mod table The mod state
---@param spec table The mod spec
---@return nil
local function drawResetButton(selectedMod, mod, spec)
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

local function drawModPanel()
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
-- Engine Settings (schema-driven rendering)
-- ====================================================================

--- Generic engine settings renderer using schema.
---@param engineId string The engine mod ID (e.g., "0-Engine-UI")
local function drawEngineSettings(engineId)
    resolveLogger()
    if log then log.info(string.format("drawEngineSettings: START for %s", engineId)) end

    local mod = Core.getMod(engineId)
    if not mod then
        if log then log.warn(string.format("drawEngineSettings: mod %s NOT FOUND", engineId)) end
        return
    end

    local spec = mod.spec or {}
    local settings = mod.settings or {}

    if log then log.info(string.format("drawEngineSettings: spec.settings=%s, settings keys=%s", tostring(spec.settings ~= nil), tostring(next(settings)))) end

    -- Use SettingsRenderer to render from schema
    if SettingsRenderer and SettingsRenderer.renderSettings and spec.settings then
        local changed = SettingsRenderer.renderSettings(engineId, spec, settings)
        if changed then
            -- Recursively apply live settings changes (handles nested sections)
            local function applySettingsRecursive(settingsDef, settingsTable)
                for key, setting in pairs(settingsDef) do
                    if setting.type == "section" and setting.settings then
                        -- Recurse into section's nested settings with the same settings table
                        applySettingsRecursive(setting.settings, settingsTable)
                    elseif settingsTable[key] ~= nil then
                        applySettingLive(engineId, key, settingsTable[key])
                    end
                end
            end
            applySettingsRecursive(spec.settings, settings)
            if Core and Core.markDirty then
                Core.markDirty()
            end
        end
    else
        if log then log.warn(string.format("drawEngineSettings: SettingsRenderer or spec.settings not available for %s", engineId)) end
        ImGui.TextDisabled("Settings not available")
    end
end

-- ====================================================================
-- Settings Panel (engine settings — tabbed)
-- ====================================================================
local function drawSettingsPanel()
    resolveTokens()
    resolveComponents()
    resolveLogger()

    if log then log.info("drawSettingsPanel: START") end

    -- Header with title and info glyph
    local headerColor = Tokens and Tokens.color4n("primary") or { r = 0.4, g = 0.6, b = 1.0 }
    ImGui.TextColored(headerColor.r, headerColor.g, headerColor.b, 1, "Engine Settings")

    -- Info glyph right after title (left side)
    ImGui.SameLine()
    if GlyphButton("##engine_info", "InformationOutline", { size = 18, tooltip = "Engine Information" }) then
        ImGui.OpenPopup("##engine_info_popup")
    end

    -- Back to Mods button on right side
    local availW = ImGui.GetContentRegionAvail()
    ImGui.SameLine(availW - 100)
    ImGui.PushStyleColor(ImGuiCol.Button, 0.3, 0.3, 0.3, 0.6)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.4, 0.4, 0.4, 0.8)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.9, 0.9, 0.9, 1.0)
    if ImGui.Button("Back to Mods", 90, 22) then
        Core.setContentMode("mod")
    end
    ImGui.PopStyleColor(3)

    -- Engine info popup
    if ImGui.BeginPopup("##engine_info_popup") then
        ImGui.Text("0-Mod-Engine v1.0.0-unified")
        ImGui.Separator()

        -- Engine versions
        local engines = {
            { id = "0-Engine-UI", name = "UI-Engine" },
            { id = "0-Engine-Log", name = "Log-Engine" },
            { id = "0-Engine-Config", name = "Config-Engine" },
        }

        for _, engine in ipairs(engines) do
            local mod = Core.getMod(engine.id)
            if mod then
                local spec = mod.spec or {}
                local version = spec.version or "unknown"
                local renderMode = mod.renderMode or "unknown"

                -- Test status
                local testStatus = ""
                if TestResults then
                    local r = TestResults.get(engine.id)
                    if r then
                        if r.passed == r.total then
                            testStatus = string.format("  [PASS %d/%d]", r.passed, r.total)
                        else
                            testStatus = string.format("  [FAIL %d/%d]", r.passed, r.total)
                        end
                    else
                        testStatus = "  [NO TESTS]"
                    end
                end

                ImGui.Text(string.format("%s: %s (%s)%s", engine.name, version, renderMode, testStatus))
            else
                ImGui.TextDisabled(string.format("%s: not loaded", engine.name))
            end
        end

        -- DevKit info
        ImGui.Separator()
        ImGui.Text("DevKit:")
        local devkitMod = Core.getMod("UI-Engine-DevKit")
        if devkitMod then
            local devkitSpec = devkitMod.spec or {}
            local devkitVersion = devkitSpec.version or "unknown"
            ImGui.Text(string.format("  Version: %s", devkitVersion))

            -- DevKit test status
            if TestResults then
                local r = TestResults.get("UI-Engine-DevKit")
                if r then
                    if r.passed == r.total then
                        ImGui.TextColored(0.3, 0.9, 0.3, 1.0, string.format("  Tests: %d/%d PASS", r.passed, r.total))
                    else
                        ImGui.TextColored(0.9, 0.9, 0.2, 1.0, string.format("  Tests: %d/%d PASS", r.passed, r.total))
                    end
                else
                    ImGui.TextDisabled("  Tests: No results")
                end
            end
        else
            ImGui.TextDisabled("  Not loaded")
        end

        ImGui.Separator()
        ImGui.TextDisabled("Author: The Fantastic loki")
        ImGui.EndPopup()
    end

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
            drawEngineSettings("0-Engine-UI")
            ImGui.EndTabItem()
        end

        -- Log Engine tab
        local tabLog = ImGui.BeginTabItem("Log Engine")
        if log then log.info(string.format("drawSettingsPanel: BeginTabItem 'Log Engine' returned: %s", tostring(tabLog))) end
        if tabLog then
            drawEngineSettings("0-Engine-Log")
            ImGui.EndTabItem()
        end

        -- Config Engine tab
        local tabCfg = ImGui.BeginTabItem("Config Engine")
        if log then log.info(string.format("drawSettingsPanel: BeginTabItem 'Config Engine' returned: %s", tostring(tabCfg))) end
        if tabCfg then
            drawEngineSettings("0-Engine-Config")
            
            -- Clear height cache button
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.Button("Clear Section Height Cache") then
                M.clearHeightCache()
                if SettingsRenderer and SettingsRenderer.clearHeightCache then
                    SettingsRenderer.clearHeightCache()
                end
                if log then log.info("Height cache cleared by user") end
            end
            ImGui.SameLine()
            ImGui.TextDisabled("(forces re-measurement on next frame)")
            
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end
end

-- ====================================================================
-- Test Panel (central test management)
-- ====================================================================
local function drawTestPanel()
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

--- Draw detached mod windows (right-click → "Open in Window").
--- Called from init.lua onDraw to render floating mod windows.
---@return nil
function M.drawDetachedWindows()
    if not Core then return end

    local detached = Core.getDetachedMods()
    if not detached then return end

    for modId, winState in pairs(detached) do
        local mod = Core.getMod(modId)
        if mod then
            local spec = mod.spec or {}
            local title = (spec.name or modId) .. "##detached_" .. modId
            ImGui.SetNextWindowPos(winState.x, winState.y, ImGuiCond.FirstUseEver)
            ImGui.SetNextWindowSize(winState.width, winState.height, ImGuiCond.FirstUseEver)
            local visible = ImGui.Begin(title, true)
            if visible then
                -- Render mod info header
                ImGui.Text(spec.name or modId)
                ImGui.Separator()
                if spec.version then ImGui.Text("Version: " .. spec.version) end
                if spec.author then ImGui.Text("Author: " .. spec.author) end
                if spec.description then ImGui.TextWrapped(spec.description) end
                ImGui.Spacing()
                ImGui.Separator()
                ImGui.Spacing()

                -- Render settings if schema-based
                if (mod.renderMode == "schema" or mod.renderMode == "hybrid") and SettingsRenderer and SettingsRenderer.renderSettings then
                    local changed = SettingsRenderer.renderSettings(modId, spec, mod.settings)
                    if changed and spec.settings then
                        for key, _ in pairs(spec.settings) do
                            if mod.settings[key] ~= nil then
                                applySettingLive(modId, key, mod.settings[key])
                            end
                        end
                        if Core.markDirty then Core.markDirty() end
                    end
                end

                -- Custom draw
                if (mod.renderMode == "custom" or mod.renderMode == "hybrid") and spec.draw then
                    local modCtx = { modId = modId, spec = spec }
                    setmetatable(modCtx, {
                        __index = function(_, k)
                            if ImGui[k] then return ImGui[k] end
                            return nil
                        end
                    })
                    local drawOk, drawErr = pcall(spec.draw, modCtx)
                    if not drawOk then
                        ImGui.TextColored(1, 0.3, 0.3, 1, "Draw error: " .. tostring(drawErr))
                    end
                end
            end
            -- Handle close button (visibility becomes false when X is clicked)
            if not visible then
                Core.reattachMod(modId)
            end
            ImGui.End()
        else
            -- Mod no longer exists, clean up
            Core.reattachMod(modId)
        end
    end
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

return M
