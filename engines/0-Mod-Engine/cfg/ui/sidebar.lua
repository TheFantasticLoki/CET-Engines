-- Config-Engine Sidebar
-- Toolbar, search, filters, categories, test indicators, context menu.

---@class CfgSidebar
local M = {}

-- Dependencies (late-bound)
local Core = nil
local SearchParser = nil
local TestResults = nil
local Categories = nil
local Tokens = nil

local function resolveTokens()
    if Tokens then return end
    local ok, mod = pcall(require, "ui/tokens")
    if ok then Tokens = mod end
end

-- Filter state (persisted via Core.activeFilters)
local filterOpen = false
local themeOpen = false

--- Glyphs module (late-bound)
local Glyphs = nil

--- Initialize the sidebar module.
---@param deps table { core: CfgCore, searchParser: SearchParser, testResults: TestResults, categories: Categories }
---@return nil
function M.init(deps)
    Core = deps.core
    SearchParser = deps.searchParser
    TestResults = deps.testResults
    Categories = deps.categories
    -- Load Glyphs module (may not be available yet)
    Glyphs = deps.glyphs or (function()
        local ok, mod = pcall(require, "ui/components/glyphs")
        return ok and mod or nil
    end)()
end

--- Draw the sidebar.
---@return nil
function M.draw()
    if not Core then return end

    -- ====================================================================
    -- Toolbar row (icon buttons using ImGui.IconGlyphs)
    -- ====================================================================
    local btnSize = 28

    -- Settings button (gear icon)
    if Glyphs and Glyphs.Button("sidebar_settings", "ApplicationCog", { size = btnSize, tooltip = "Engine Settings", fallback = "S" }) then
        Core.setContentMode("settings")
    end
    ImGui.SameLine()

    -- Favorites/Filter button (star icon)
    local activeFilters = Core.getActiveFilters()
    local hasFilters = #activeFilters > 0
    if hasFilters then
        ImGui.PushStyleColor(ImGuiCol.Button, 0.3, 0.6, 1.0, 1.0)
    end
    local filterTooltip = hasFilters and ("Filter mods (" .. #activeFilters .. " active)") or "Filter mods"
    if Glyphs and Glyphs.Button("sidebar_filter", "FilterMenu", { size = btnSize, tooltip = filterTooltip, fallback = "F" }) then
        filterOpen = not filterOpen
        themeOpen = false
    end
    if hasFilters then ImGui.PopStyleColor() end
    ImGui.SameLine()

    -- Theme quick-switch (palette icon)
    if Glyphs and Glyphs.Button("sidebar_theme", "Palette", { size = btnSize, tooltip = "Quick Theme Switch", fallback = "T" }) then
        themeOpen = not themeOpen
        filterOpen = false
    end
    ImGui.SameLine()

    -- Sort mode
    local sortMode, sortAsc = Core.getSortMode()
    local sortLabel = sortMode == "name" and "A-Z" or sortMode == "author" and "Au" or "Ver"
    if Glyphs and Glyphs.Button("sidebar_sort", "Sort", { size = btnSize, tooltip = "Sort: " .. sortMode .. (sortAsc and " (asc)" or " (desc)"), fallback = sortLabel }) then
        -- Cycle: name -> author -> version -> name
        local modes = { "name", "author", "version" }
        local nextIdx = 1
        for i, m in ipairs(modes) do
            if m == sortMode then nextIdx = (i % #modes) + 1; break end
        end
        Core.setSortMode(modes[nextIdx], true)
    end

    -- ====================================================================
    -- Filter popup
    -- ====================================================================
    if filterOpen then
        ImGui.OpenPopup("##cfg_filter_popup")
        filterOpen = false -- close after opening
    end
    if ImGui.BeginPopup("##cfg_filter_popup") then
        ImGui.Text("Filters")
        ImGui.Separator()

        -- Tag filters
        local availableTags = { "favorite", "development", "framework", "gameplay", "ui" }
        local activeTags = {}
        for _, f in ipairs(activeFilters) do
            if f.key == "tag" then activeTags[f.value] = true end
        end

        for _, tag in ipairs(availableTags) do
            local isActive = activeTags[tag] or false
            if ImGui.Checkbox(tag, isActive) then
                -- Toggle filter
                local newFilters = {}
                for _, f in ipairs(activeFilters) do
                    if not (f.key == "tag" and f.value == tag) then
                        table.insert(newFilters, f)
                    end
                end
                if not isActive then
                    table.insert(newFilters, { key = "tag", value = tag })
                end
                Core.setActiveFilters(newFilters)
            end
        end

        ImGui.Separator()
        if ImGui.Button("Clear All") then
            Core.setActiveFilters({})
        end
        ImGui.EndPopup()
    end

    -- ====================================================================
    -- Theme popup
    -- ====================================================================
    if themeOpen then
        ImGui.OpenPopup("##cfg_theme_popup")
        themeOpen = false
    end
    if ImGui.BeginPopup("##cfg_theme_popup") then
        ImGui.Text("Theme")
        ImGui.Separator()
        -- Theme list populated from Core or a theme provider
        local themes = (ModEngine and ModEngine.GetThemeList and ModEngine.GetThemeList()) or { "Dark" }
        local current = (ModEngine and ModEngine.GetTheme and ModEngine.GetTheme()) or "Dark"
        for _, name in ipairs(themes) do
            local isSelected = (name == current)
            ImGui.Selectable(name, isSelected)
            if ImGui.IsItemClicked() then
                -- Apply theme via ModEngine
                if ModEngine and ModEngine.SetTheme then
                    ModEngine.SetTheme(name)
                end
                -- Sync theme to Config-Engine settings store so engine settings dropdown stays in sync
                local engineMod = Core.getMod("0-Engine-UI")
                if engineMod and engineMod.settings and engineMod.settings.currentTheme ~= nil then
                    engineMod.settings.currentTheme = name
                end
            end
        end
        ImGui.EndPopup()
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- ====================================================================
    -- Search bar
    -- ====================================================================
    local query = Core.getSearchQuery()
    ImGui.SetNextItemWidth(-1)
    local newQuery, queryChanged = ImGui.InputTextWithHint("##cfgsearch", "Search mods...", query or "", 256)
    if queryChanged then
        Core.setSearchQuery(newQuery)
    end

    -- Show active filter indicators
    if #activeFilters > 0 then
        ImGui.TextDisabled(#activeFilters .. " filter(s)")
    end

    ImGui.Spacing()
    ImGui.Separator()
    ImGui.Spacing()

    -- ====================================================================
    -- Parse search query
    -- ====================================================================
    local parsed = nil
    if SearchParser and query and #query > 0 then
        parsed = SearchParser.parse(query)
    end

    -- ====================================================================
    -- Mod list with categories
    -- ====================================================================
    local modIds = Core.getSortedModIds()
    local selectedMod = Core.getSelectedMod()
    local visibleCount = 0

    -- Group by category (skip engine internal mods — they have a dedicated settings panel)
    local enginePrefixes = { ["0-Engine-"] = true }
    local grouped = {}
    local ungrouped = {}
    for _, modId in ipairs(modIds) do
        -- Skip engine mods from sidebar list (managed via dedicated settings panel)
        local isEngine = false
        for prefix, _ in pairs(enginePrefixes) do
            if modId:sub(1, #prefix) == prefix then isEngine = true; break end
        end
        if not isEngine then
            local mod = Core.getMod(modId)
            if mod then
                local assignment = Core.getModCategory(modId)
                local cat = (assignment and assignment.category) or "Uncategorized"

                -- Apply search/filter
                local matches = true
                if parsed then
                    matches = SearchParser.matches(mod, modId, assignment, parsed)
                end

                if matches then
                    visibleCount = visibleCount + 1
                    if not grouped[cat] then grouped[cat] = {} end
                    table.insert(grouped[cat], modId)
                end
            end
        end
    end

    -- Render categories
    local catOrder = Categories and Categories.order or {}
    local renderedCats = {}

    for _, catName in ipairs(catOrder) do
        local mods = grouped[catName]
        if mods and #mods > 0 then
            renderedCats[catName] = true
            local expanded = Core.isCategoryExpanded(catName)

            local header = catName .. " (" .. #mods .. ")"

            if ImGui.TreeNodeEx(catName, ImGuiTreeNodeFlags.NoTreePushOnOpen, header) then
                if not expanded then Core.toggleCategory(catName) end
                for _, modId in ipairs(mods) do
                    drawModEntry(modId, selectedMod)
                end
                ImGui.TreePop()
            elseif expanded then
                Core.toggleCategory(catName)
            end
        end
    end

    -- Render ungrouped mods (not in any defined category)
    for catName, mods in pairs(grouped) do
        if not renderedCats[catName] and #mods > 0 then
            local header = catName .. " (" .. #mods .. ")"
            if ImGui.TreeNodeEx(catName, ImGuiTreeNodeFlags.NoTreePushOnOpen, header) then
                for _, modId in ipairs(mods) do
                    drawModEntry(modId, selectedMod)
                end
                ImGui.TreePop()
            end
        end
    end

    -- Empty state
    if visibleCount == 0 then
        ImGui.Spacing()
        if #modIds == 0 then
            ImGui.TextDisabled("No mods registered")
            ImGui.TextDisabled("Use ModEngine.RegisterMod()")
        else
            ImGui.TextDisabled("No mods match filters")
        end
    end
end

--- Draw a single mod entry in the sidebar.
---@param modId string The mod identifier
---@param selectedMod string|nil Currently selected mod ID
---@return nil
function drawModEntry(modId, selectedMod)
    local mod = Core.getMod(modId)
    if not mod then return end

    local spec = mod.spec or {}
    local label = spec.name or modId
    local isSelected = selectedMod == modId

    -- ── Row layout: [status dot] [name] [version badge] ──────────────
    local dotColor = nil
    if TestResults then
        local _, status = TestResults.getStatusIcon(modId)
        if status == "pass" then
            dotColor = Tokens and Tokens.color4n("success") or {r=0.3, g=0.9, b=0.3, a=1.0}
        elseif status == "fail" then
            dotColor = Tokens and Tokens.color4n("warning") or {r=0.9, g=0.9, b=0.2, a=1.0}
        elseif status == "error" then
            dotColor = Tokens and Tokens.color4n("error") or {r=0.9, g=0.3, b=0.3, a=1.0}
        end
    end
    -- Enabled/disabled dot (when no tests)
    if not dotColor then
        dotColor = mod.enabled ~= false
            and (Tokens and Tokens.color4n("success") or {r=0.4, g=0.7, b=0.4, a=0.8})
            or  (Tokens and Tokens.color4n("muted") or {r=0.5, g=0.5, b=0.5, a=0.5})
    end

    -- Pin/favorite indicators
    local prefix = ""
    if mod.pinned then prefix = prefix .. "★ " end
    if mod.favorite then prefix = prefix .. "♥ " end

    -- Build display label: "  ● prefixName"
    local displayLabel = "  " .. prefix .. label

    -- Selectable
    ImGui.Selectable(displayLabel, isSelected)
    if ImGui.IsItemClicked() then
        Core.setSelectedMod(modId)
        Core.setContentMode("mod")
    end

    -- Draw status dot in the left margin (overlapping the selectable)
    -- Use the item rect to position a small colored circle
    pcall(function()
        local minX, minY = ImGui.GetItemRectMin()
        local drawList = ImGui.GetWindowDrawList()
        if drawList and minX then
            local dotR = 3
            local dotX = minX + 6
            local dotY = minY + (ImGui.GetItemRectHeight() / 2)
            local packed = ImGui.GetColorU32(dotColor[1], dotColor[2], dotColor[3], dotColor[4])
            ImGui.ImDrawListAddCircleFilled(drawList, dotX, dotY, dotR, packed, 0)
        end
    end)

    -- Version badge (right-aligned, muted)
    if spec.version then
        pcall(function()
            local textW = ImGui.CalcTextSize(spec.version)
            local maxW = ImGui.GetContentRegionAvail()
            local itemMaxX = ImGui.GetItemRectMax()
            local windowX = ImGui.GetCursorScreenPos()
            local badgeX = itemMaxX - textW - 8
            local badgeY = ImGui.GetItemRectMin() + (ImGui.GetItemRectHeight() - ImGui.GetTextLineHeight()) / 2
            if badgeX > windowX then
                local drawList = ImGui.GetWindowDrawList()
                local cVer = Tokens and Tokens.color4n("muted") or {r=0.5, g=0.5, b=0.6}
                ImGui.ImDrawListAddText(drawList, ImGui.GetFontSize(), badgeX, badgeY,
                    ImGui.GetColorU32(cVer.r, cVer.g, cVer.b, 0.7), spec.version)
            end
        end)
    end

    -- ── Rich Tooltip ─────────────────────────────────────────────────
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()

        -- Header: name + version
        ImGui.TextColored(0.9, 0.9, 1.0, 1.0, label)
        if spec.version then
            ImGui.SameLine()
            ImGui.TextDisabled("v" .. spec.version)
        end

        -- Author
        if spec.author then
            ImGui.TextDisabled("by " .. spec.author)
        end

        -- Description
        if spec.description and spec.description ~= "" then
            ImGui.Spacing()
            ImGui.TextWrapped(spec.description)
        end

        -- Metadata section
        ImGui.Separator()

        -- Category
        local assignment = Core.getModCategory(modId)
        if assignment and assignment.category then
            local catText = assignment.category
            if assignment.subcategory then
                catText = catText .. " › " .. assignment.subcategory
            end
            ImGui.TextDisabled("Category: ")
            ImGui.SameLine()
            ImGui.Text(catText)
        end

        -- Render mode
        if mod.renderMode then
            ImGui.TextDisabled("Mode: ")
            ImGui.SameLine()
            ImGui.Text(mod.renderMode)
        end

        -- Tags
        local tags = Core.getModTags(modId)
        if tags and #tags > 0 then
            ImGui.TextDisabled("Tags: ")
            ImGui.SameLine()
            ImGui.Text(table.concat(tags, ", "))
        end

        -- Test status
        if TestResults then
            local r = TestResults.get(modId)
            if r then
                ImGui.Separator()
                local statusColor
                if r.status == "pass" then
                    statusColor = Tokens and Tokens.color4n("success") or {0.3, 0.9, 0.3}
                elseif r.status == "fail" then
                    statusColor = Tokens and Tokens.color4n("warning") or {0.9, 0.9, 0.2}
                else
                    statusColor = Tokens and Tokens.color4n("error") or {0.9, 0.3, 0.3}
                end
                ImGui.TextColored(statusColor[1], statusColor[2], statusColor[3], 1.0,
                    string.format("Tests: %d/%d passing", r.passed, r.passed + r.failed))
                if r.warnings and r.warnings > 0 then
                    ImGui.TextDisabled("  " .. r.warnings .. " warning(s)")
                end
            end
        end

        -- Custom tooltip from mod author
        if spec.tooltipFn and type(spec.tooltipFn) == "function" then
            ImGui.Separator()
            local ok, customLines = pcall(spec.tooltipFn, mod)
            if ok and type(customLines) == "string" then
                ImGui.TextWrapped(customLines)
            elseif ok and type(customLines) == "table" then
                for _, line in ipairs(customLines) do
                    ImGui.TextWrapped(tostring(line))
                end
            end
        elseif spec.tooltip and type(spec.tooltip) == "string" then
            ImGui.Separator()
            ImGui.TextWrapped(spec.tooltip)
        end

        ImGui.EndTooltip()
    end

    -- ── Right-click context menu ─────────────────────────────────────
    if ImGui.BeginPopupContextItem("##mod_ctx_" .. modId) then
        if ImGui.MenuItem("Pin", nil, mod.pinned) then
            Core.setMod(modId, { pinned = not mod.pinned })
        end
        if ImGui.MenuItem("Favorite", nil, mod.favorite) then
            Core.setMod(modId, { favorite = not mod.favorite })
        end
        ImGui.Separator()
        if ImGui.MenuItem("Run Tests") then
            local TestRunner = require("cfg/test_runner")
            TestRunner.runModTests(modId, "full")
        end
        ImGui.Separator()
        if ImGui.MenuItem("Open in Window") then
            Core.detachMod(modId)
        end
        ImGui.EndPopup()
    end
end

return M
