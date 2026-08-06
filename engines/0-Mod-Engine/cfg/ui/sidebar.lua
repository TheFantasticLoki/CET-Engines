-- Config-Engine Sidebar
-- Toolbar, search, filters, categories, test indicators, context menu.

---@class CfgSidebar
local M = {}

-- Dependencies (late-bound)
local Core = nil
local SearchParser = nil
local TestResults = nil
local Categories = nil

-- Filter state (persisted via Core.activeFilters)
local filterOpen = false
local themeOpen = false

--- Safely get an icon glyph from ImGui.IconGlyphs
---@param name string Icon name (e.g., "Settings", "Star", "Palette")
---@return string|nil glyph
local function GetSafeIconGlyph(name)
    if not IconGlyphs or not name then return nil end
    local glyph = IconGlyphs[name]
    if type(glyph) == "string" and glyph ~= "" then return glyph end
    return nil
end

--- Check if we can draw centered text on buttons
---@return boolean
local function CanDrawCenteredButtonText()
    return ImGui.GetWindowDrawList and
        ImGui.GetItemRectMin and
        ImGui.GetItemRectMax and
        ImGui.ImDrawListAddText and
        ImGui.CalcTextSize and
        ImGui.GetColorU32 and
        ImGui.GetFontSize
end

--- Draw centered text on the last button
---@param text string Glyph text to draw
local function DrawCenteredButtonText(text)
    if not CanDrawCenteredButtonText() then return end
    pcall(function()
        local minX, minY = ImGui.GetItemRectMin()
        local maxX, maxY = ImGui.GetItemRectMax()
        local textW, textH = ImGui.CalcTextSize(text)
        local color = ImGui.GetColorU32(1.0, 1.0, 1.0, 0.96)
        ImGui.ImDrawListAddText(
            ImGui.GetWindowDrawList(),
            ImGui.GetFontSize(),
            minX + ((maxX - minX) - textW) * 0.5,
            minY + ((maxY - minY) - textH) * 0.5,
            color,
            text
        )
    end)
end

--- Draw an icon glyph button (CET-compatible pattern from Reflex Engine)
---@param id string Button unique ID
---@param iconName string IconGlyphs name
---@param fallbackText string Fallback text if glyph unavailable
---@param width number Button width
---@param height number Button height
---@param tooltip string|nil Tooltip text
---@return boolean clicked
local function DrawIconGlyphButton(id, iconName, fallbackText, width, height, tooltip)
    local glyph = GetSafeIconGlyph(iconName)
    local display = glyph or fallbackText or ""
    local drawCentered = CanDrawCenteredButtonText()
    local label = drawCentered and ("##" .. id) or (display .. "##" .. id)
    local clicked = ImGui.Button(label, width, height or 0.0)

    if drawCentered then
        DrawCenteredButtonText(display)
    end

    if tooltip and ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(tooltip)
        ImGui.EndTooltip()
    end

    return clicked
end

--- Initialize the sidebar module.
---@param deps table { core: CfgCore, searchParser: SearchParser, testResults: TestResults, categories: Categories }
---@return nil
function M.init(deps)
    Core = deps.core
    SearchParser = deps.searchParser
    TestResults = deps.testResults
    Categories = deps.categories
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
    if DrawIconGlyphButton("sidebar_settings", "Settings", "\xc2\x9e99", btnSize, btnSize, "Engine Settings") then
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
    if DrawIconGlyphButton("sidebar_filter", "Star", "\xe2\x98\x85", btnSize, btnSize, filterTooltip) then
        filterOpen = not filterOpen
        themeOpen = false
    end
    if hasFilters then ImGui.PopStyleColor() end
    ImGui.SameLine()

    -- Theme quick-switch (palette icon)
    if DrawIconGlyphButton("sidebar_theme", "Palette", "\xf0\x9f\x8e\xa8", btnSize, btnSize, "Quick Theme Switch") then
        themeOpen = not themeOpen
        filterOpen = false
    end
    ImGui.SameLine()

    -- Sort mode
    local sortMode, sortAsc = Core.getSortMode()
    local sortLabel = sortMode == "name" and "A-Z" or sortMode == "author" and "Au" or "Ver"
    if DrawIconGlyphButton("sidebar_sort", "Sort", sortLabel, btnSize, btnSize, "Sort: " .. sortMode .. (sortAsc and " (asc)" or " (desc)")) then
        -- Cycle: name -> author -> version -> name
        local modes = { "name", "author", "version" }
        local nextIdx = 1
        for i, m in ipairs(modes) do
            if m == sortMode then nextIdx = (i % #modes) + 1; break end
        end
        Core.setSortMode(modes[nextIdx], true)
    end
    if ImGui.SmallButton(sortLabel) then
        -- Cycle: name -> author -> version -> name
        local modes = { "name", "author", "version" }
        local nextIdx = 1
        for i, m in ipairs(modes) do
            if m == sortMode then nextIdx = (i % #modes) + 1; break end
        end
        Core.setSortMode(modes[nextIdx], true)
    end
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text("Sort: " .. sortMode .. (sortAsc and " (asc)" or " (desc)"))
        ImGui.TextDisabled("Click to cycle")
        ImGui.EndTooltip()
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
        local themes = { "Dark", "Red", "Cyan", "Blue", "Green", "Amber", "Purple", "Pink" }
        local current = Core.getContentMode and "Dark" or "Dark"
        for _, name in ipairs(themes) do
            local isSelected = (name == current)
            if ImGui.Selectable(name, isSelected) then
                -- Apply theme
                if ModEngine and ModEngine.SetTheme then
                    ModEngine.SetTheme(name)
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

    -- Group by category
    local grouped = {}
    local ungrouped = {}
    for _, modId in ipairs(modIds) do
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

    -- Render categories
    local catOrder = Categories and Categories.order or {}
    local renderedCats = {}

    for _, catName in ipairs(catOrder) do
        local mods = grouped[catName]
        if mods and #mods > 0 then
            renderedCats[catName] = true
            local expanded = Core.isCategoryExpanded(catName)
            local header = (expanded and "\xc2\x96\xb2 " or "\xc2\x96\xbc ") .. catName .. " (" .. #mods .. ")"

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
            if ImGui.TreeNodeEx(catName, ImGuiTreeNodeFlags.NoTreePushOnOpen, catName .. " (" .. #mods .. ")") then
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

    -- Pin/favorite indicators
    local prefix = ""
    if mod.pinned then prefix = prefix .. "* " end
    if mod.favorite then prefix = prefix .. "+ " end

    -- Selectable
    ImGui.Selectable(prefix .. label, isSelected)
    if ImGui.IsItemClicked() then
        Core.setSelectedMod(modId)
        Core.setContentMode("mod")
    end

    -- Test indicator (inline after selectable)
    if TestResults then
        local icon, status = TestResults.getStatusIcon(modId)
        if status ~= "none" then
            ImGui.SameLine()
            if status == "pass" then
                ImGui.TextColored(0.3, 0.9, 0.3, 1, icon)
            elseif status == "fail" then
                ImGui.TextColored(0.9, 0.9, 0.2, 1, icon)
            else
                ImGui.TextColored(0.9, 0.3, 0.3, 1, icon)
            end
        end
    end

    -- Tooltip
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(spec.description or label)
        if spec.version then ImGui.Text("Version: " .. spec.version) end
        if spec.author then ImGui.Text("Author: " .. spec.author) end
        -- Test status tooltip
        if TestResults then
            local r = TestResults.get(modId)
            if r then
                ImGui.Separator()
                ImGui.Text(string.format("Tests: %d/%d passing", r.passed, r.passed + r.failed))
                if r.warnings and r.warnings > 0 then
                    ImGui.TextDisabled(r.warnings .. " warnings")
                end
            end
        end
        ImGui.EndTooltip()
    end

    -- Right-click context menu
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
