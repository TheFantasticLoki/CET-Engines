--[[
    Containers — UI-Engine Component Library

    Container widgets for organizing content.
    Includes CollapsingSection, TreeNode, CustomTreeNode.

    Dependencies: ui/utils.lua, ui/tokens.lua, core.lua (for section state)
]]

---@class ContainerComponents
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- Lazy-loaded Core for section state
local _core = nil

--- Initialize containers module
---@param core Core module reference
---@return nil
function M.init(core)
    _core = core
end

-- --- Collapsing Section ---

--- Collapsing section with persisted state
---@param label Section label
---@param defaultOpen Default open state
---@param buildFn Function that builds section content
---@param options Optional: {group, tooltip}
---@return boolean isOpen
function M.CollapsingSection(label, defaultOpen, buildFn, options)
    label = label or ""
    defaultOpen = defaultOpen ~= false
    options = options or {}
    local group = options.group or label
    local tooltip = options.tooltip

    -- Get persisted state if Core available
    local isOpen = defaultOpen
    if _core and _core.getSectionState then
        local saved = _core.getSectionState(group)
        if saved ~= nil then
            isOpen = saved
        end
    end

    -- Render collapsing header
    local headerOpen = Utils.SafeImGuiCall(ImGui.CollapsingHeader, label, isOpen and ImGuiTreeNodeFlags.DefaultOpen or 0)

    -- State changed
    if headerOpen ~= isOpen then
        isOpen = headerOpen
        -- Persist state if Core available
        if _core and _core.setSectionState then
            _core.setSectionState(group, isOpen)
        end
    end

    -- Build content if open
    if isOpen and buildFn and type(buildFn) == "function" then
        buildFn()
    end

    if tooltip and tooltip ~= "" then
        Utils.Tooltip(tooltip)
    end

    return isOpen
end

-- --- Tree Node ---

--- Tree node
---@param label Node label
---@param buildFn Function that builds node content
---@return boolean isOpen
function M.TreeNode(label, buildFn)
    label = label or ""

    local isOpen = Utils.SafeImGuiCall(ImGui.TreeNode, label)

    if isOpen and buildFn and type(buildFn) == "function" then
        buildFn()
        Utils.SafeImGuiCall(ImGui.TreePop)
    end

    return isOpen
end

-- --- Custom Tree Node ---

--- Sidebar category variant with icon
---@param label Node label
---@param icon Icon text/glyph (optional)
---@param buildFn Function that builds node content
---@return boolean isOpen
function M.CustomTreeNode(label, icon, buildFn)
    label = label or ""

    -- Build display text with icon
    local display = label
    if icon and icon ~= "" then
        display = icon .. " " .. label
    end

    local isOpen = Utils.SafeImGuiCall(ImGui.TreeNode, display)

    if isOpen and buildFn and type(buildFn) == "function" then
        buildFn()
        Utils.SafeImGuiCall(ImGui.TreePop)
    end

    return isOpen
end

-- --- Card ---

--- Card container with header, body, footer
--- NOTE: Card uses raw ImGui calls intentionally. Push/Pop style calls are NOT
--- wrapped per CET FFI rule (pcall on ImGui calls breaks LuaJIT FFI binding).
--- BeginChild/EndChild pairs are safe across CET versions.
---@param spec Table: { title, subtitle, icon, headerRight, body, footer, onClick, selected }
---@return boolean clicked
function M.Card(spec)
    spec = spec or {}
    local title = spec.title or ""
    local subtitle = spec.subtitle
    local icon = spec.icon
    local headerRight = spec.headerRight
    local body = spec.body
    local footer = spec.footer
    local onClick = spec.onClick
    local selected = spec.selected or false

    -- Get theme colors
    local borderColor = selected and Tokens.color4n("primary") or Tokens.color4n("border")
    local bgColor = Tokens.color4n("background")

    local clicked = false

    -- Push style for card
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, Tokens.SPACING.md, Tokens.SPACING.md)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, Tokens.BORDER_RADIUS.md)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Border, borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, bgColor.r, bgColor.g, bgColor.b, bgColor.a * 0.5)

    -- Calculate card height
    local headerHeight = 0
    local bodyHeight = 0
    local footerHeight = 0
    local lineHeight = ImGui.GetTextLineHeight()

    if title ~= "" then
        headerHeight = lineHeight + Tokens.SPACING.sm
        if subtitle then
            headerHeight = headerHeight + lineHeight * 0.8
        end
    end

    if body and type(body) == "function" then
        bodyHeight = lineHeight * 3  -- Estimate for body
    end

    if footer and type(footer) == "function" then
        footerHeight = lineHeight + Tokens.SPACING.sm * 2
    end

    local totalHeight = headerHeight + bodyHeight + footerHeight + Tokens.SPACING.md * 2

    -- Begin child window for card
    ImGui.BeginChild("##card_" .. title, 0, totalHeight, true)

    -- Header section
    if title ~= "" then
        -- Icon + Title
        local displayTitle = title
        if icon and icon ~= "" then
            displayTitle = icon .. " " .. title
        end

        -- Cache token colors to avoid repeated resolution
        local tp = Tokens.color4n("textPrimary")
        ImGui.TextColored(tp.r, tp.g, tp.b, tp.a, displayTitle)

        -- Subtitle
        if subtitle then
            local ts = Tokens.color4n("textSecondary")
            ImGui.TextColored(ts.r, ts.g, ts.b, ts.a, subtitle)
        end

        -- Header right content
        if headerRight and type(headerRight) == "function" then
            ImGui.SameLine(ImGui.GetContentRegionAvailWidth() - 50)
            headerRight()
        end

        ImGui.Separator()
    end

    -- Body section
    if body and type(body) == "function" then
        body()
    end

    -- Footer section
    if footer and type(footer) == "function" then
        ImGui.Separator()
        footer()
    end

    ImGui.EndChild()

    -- Check for click on the card
    if onClick and type(onClick) == "function" then
        if ImGui.IsItemClicked() then
            clicked = true
            onClick()
        end
    end

    -- Pop style
    ImGui.PopStyleColor(2)
    ImGui.PopStyleVar(3)

    return clicked
end

return M
