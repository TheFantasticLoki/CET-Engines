--[[
    Icon Browser — UI-Engine Component Library

    Searchable icon grid for browsing IconGlyphs.

    Search syntax:
      "account"           → substring match on name
      tag:Account         → filter by category tag
      tag:Account search  → combined filter

    Dependencies: IconGlyphs global (CET MaterialDesign icons)

    Usage:
        local IconBrowser = require("ui/components/icon_browser")
        IconBrowser.Draw("##my_browser", {
            onSelect = function(name, glyph) print("Selected: " .. name) end,
        })
]]

local M = {}

-- Glyphs module (late-bound to avoid circular deps)
local Glyphs = nil
-- Tokens module (late-bound for theme-aware colors)
local Tokens = nil

-- ============================================================================
-- Icon Index (built once, cached)
-- ============================================================================

local _iconList = nil
local _byTag = nil
local _tagNames = nil

local function buildIndex()
    if _iconList then return end
    _iconList = {}
    _byTag = { All = {} }
    _tagNames = {}
    local seen = {}

    if not IconGlyphs then
        print("[IconBrowser] IconGlyphs global is nil!")
        return
    end

    local count = 0
    for name, glyph in pairs(IconGlyphs) do
        if type(glyph) == "string" and not seen[name] then
            seen[name] = true
            local entry = { name = name, glyph = glyph }
            table.insert(_iconList, entry)
            table.insert(_byTag.All, entry)
            count = count + 1
        end
    end

    table.sort(_iconList, function(a, b) return a.name < b.name end)

    -- Auto-categorize by name prefix
    local prefixes = {
        "Account", "Alert", "Arrow", "Bell", "Calendar", "Camera",
        "Cart", "Chat", "Check", "Clock", "Cloud", "Close", "Cog",
        "Console", "Controller", "Database", "Delete", "Download",
        "Edit", "Email", "Exit", "Eye", "File", "Filter", "Fire",
        "Flag", "Folder", "Gift", "Globe", "Graph", "Heart",
        "Home", "Information", "Key", "Label", "Lightning", "Link",
        "List", "Lock", "Magnify", "Map", "Menu", "Message",
        "Microphone", "Minus", "Music", "Network", "Notification",
        "Numeric", "Page", "Palette", "Paperclip", "Phone", "Pin",
        "Play", "Plus", "Power", "Print", "Puzzle", "Radio",
        "Refresh", "Script", "Security", "Server", "Settings",
        "Share", "Shield", "Skull", "Speaker", "Speedometer",
        "Star", "Store", "Sync", "Table", "Tag", "Text",
        "Thumb", "Timer", "Toggle", "Tool", "Traffic", "Trophy",
        "Upload", "View", "Volume", "Window", "Wrench",
    }

    for _, prefix in ipairs(prefixes) do
        _byTag[prefix] = {}
    end
    for _, entry in ipairs(_iconList) do
        for _, prefix in ipairs(prefixes) do
            if entry.name:sub(1, #prefix) == prefix then
                table.insert(_byTag[prefix], entry)
            end
        end
    end
    for _, prefix in ipairs(prefixes) do
        if #_byTag[prefix] > 0 then
            table.insert(_tagNames, prefix)
        end
    end
    table.sort(_tagNames)
end

-- ============================================================================
-- Search with tag: syntax
-- ============================================================================

local function parseQuery(query)
    if not query or #query == 0 then
        return "", nil
    end
    local tagFilter = nil
    local text = query
    local tag = text:match("tag:(%S+)")
    if tag then
        tagFilter = tag
        text = text:gsub("tag:%S+", ""):match("^%s*(.-)%s*$")
    end
    return text:lower(), tagFilter
end

local function searchIcons(text, tagFilter)
    local pool = _iconList or {}
    if tagFilter and _byTag[tagFilter] then
        pool = _byTag[tagFilter]
    end
    if not text or #text == 0 then
        return pool
    end
    local results = {}
    for _, icon in ipairs(pool) do
        if icon.name:lower():find(text, 1, true) then
            table.insert(results, icon)
        end
    end
    return results
end

-- ============================================================================
-- State
-- ============================================================================

local function getState(id)
    if not M._states then M._states = {} end
    if not M._states[id] then
        M._states[id] = { searchQuery = "", selectedName = nil }
    end
    return M._states[id]
end
M._states = {}

-- ============================================================================
-- Draw — uses ImDrawListAddText pattern from sidebar (proven to work)
-- ============================================================================

function M.Draw(id, options)
    options = options or {}
    local onSelect = options.onSelect
    local cellSize = options.cellSize or 32
    local height = options.height

    local state = getState(id)
    buildIndex()

    if not _iconList or #_iconList == 0 then
        ImGui.TextDisabled("No icons available")
        return nil
    end

    -- Search bar
    ImGui.SetNextItemWidth(-1)
    local newQuery
    newQuery, _ = ImGui.InputTextWithHint("##is_" .. id, "Search... (tag:Name to filter)", state.searchQuery, 256)
    if newQuery ~= state.searchQuery then
        state.searchQuery = newQuery
    end

    local text, tagFilter = parseQuery(state.searchQuery)
    local icons = searchIcons(text, tagFilter)

    -- Lazy-load Glyphs module
    if not Glyphs then
        local ok, mod = pcall(require, "ui/components/glyphs")
        if ok then Glyphs = mod end
    end
    -- Lazy-load Tokens module
    if not Tokens then
        local ok, mod = pcall(require, "ui/tokens")
        if ok then Tokens = mod end
    end

    -- ====================================================================
    -- Performance cap: only render up to MAX_VISIBLE icons.
    -- Users narrow the set with search/tag filters.
    -- ====================================================================
    local MAX_VISIBLE = 300
    local totalFound = #icons
    local renderCount = math.min(totalFound, MAX_VISIBLE)

    -- ====================================================================
    -- Grid — BeginTable approach.
    -- CET quirk: SameLine inside BeginChild doesn't lay out horizontally.
    -- BeginTable handles column wrapping natively.
    -- ====================================================================
    local gridH = height or 400
    -- Subtract scrollbar width so last column isn't clipped
    local SCROLLBAR_W = 15
    local gridW = ImGui.GetContentRegionAvail() - SCROLLBAR_W
    local cols = math.max(1, math.floor(gridW / cellSize))
    local glyphSize = math.floor(cellSize * 0.7)

    ImGui.BeginChild("##ig_" .. id, -1, gridH)

    -- Zero frame padding so buttons fill their table cells exactly
    if ImGuiStyleVar and ImGuiStyleVar.FramePadding then
        ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
    end

    if ImGui.BeginTable("##icon_grid_" .. id, cols) then
        for i = 1, renderCount do
            local icon = icons[i]
            local isSelected = (state.selectedName == icon.name)

            -- Start new row at first column of each row
            if ((i - 1) % cols) == 0 then
                ImGui.TableNextRow()
            end

            if ImGui.TableNextColumn() then
                -- Button fills the cell
                local clicked = ImGui.InvisibleButton("##ic" .. i, cellSize, cellSize)

                -- Selection highlight
                if isSelected then
                    local minX, minY = ImGui.GetItemRectMin()
                    local maxX, maxY = ImGui.GetItemRectMax()
                    local pad = 2
                    local selColor = Tokens and Tokens.color4n("primary") or {r=0.3, g=0.5, b=0.9}
                    ImGui.ImDrawListAddRectFilled(
                        ImGui.GetWindowDrawList(),
                        minX + pad, minY + pad,
                        maxX - pad, maxY - pad,
                        ImGui.GetColorU32(selColor.r, selColor.g, selColor.b, 0.4),
                        4, 0
                    )
                end

                -- Draw glyph centered on button (via Glyphs module)
                if Glyphs then
                    local inactiveColor = Tokens and Tokens.color4n("muted") or {r=0.75, g=0.75, b=0.75}
                    local glyphColor = isSelected
                        and ImGui.GetColorU32(1.0, 1.0, 1.0, 1.0)
                        or  ImGui.GetColorU32(inactiveColor.r, inactiveColor.g, inactiveColor.b, 0.9)
                    Glyphs.CenteredOnItem(icon.name, { size = glyphSize, color = glyphColor })
                end

                if clicked then
                    state.selectedName = icon.name
                    if onSelect then onSelect(icon.name, icon.glyph) end
                end

                if ImGui.IsItemHovered() then
                    ImGui.SetTooltip(icon.name)
                end
            end
        end
        ImGui.EndTable()
    end

    if ImGuiStyleVar and ImGuiStyleVar.FramePadding then
        ImGui.PopStyleVar(1)
    end

    ImGui.EndChild()

    -- Result count
    if totalFound > renderCount then
        ImGui.TextDisabled(string.format(
            "Showing %d of %d — narrow with search or tag filter",
            renderCount, totalFound
        ))
    elseif totalFound > 0 then
        ImGui.TextDisabled(string.format("%d icons", totalFound))
    end

    -- Selected detail panel
    if state.selectedName then
        ImGui.Separator()
        ImGui.Spacing()
        for _, icon in ipairs(_iconList) do
            if icon.name == state.selectedName then
                -- Icon preview using Glyphs module
                if Glyphs then
                    ImGui.PushID("##preview")
                    Glyphs.Preview(icon.name, { size = 48 })
                    ImGui.PopID()
                end
                ImGui.SameLine()
                ImGui.BeginGroup()
                ImGui.Text(icon.name)
                if ImGui.Button("Copy Glyph") then
                    ImGui.SetClipboardText(icon.glyph)
                end
                ImGui.SameLine()
                if ImGui.Button("Copy Name") then
                    ImGui.SetClipboardText(icon.name)
                end
                ImGui.SameLine()
                if ImGui.Button("Copy Ref") then
                    ImGui.SetClipboardText("IconGlyphs." .. icon.name)
                end
                ImGui.EndGroup()
                break
            end
        end
    end

    return state.selectedName
end

-- ============================================================================
-- Static Helpers (delegate to Glyphs module)
-- ============================================================================

function M.getGlyph(name)
    if not Glyphs then
        local ok, mod = pcall(require, "ui/components/glyphs")
        if ok then Glyphs = mod end
    end
    return Glyphs and Glyphs.Get(name) or nil
end

function M.getNames()
    buildIndex()
    local names = {}
    for _, icon in ipairs(_iconList or {}) do
        table.insert(names, icon.name)
    end
    return names
end

return M
