--[[
    Containers — UI-Engine Component Library

    Container widgets for organizing content.
    Includes CollapsingSection, TreeNode, CustomTreeNode.

    Dependencies: ui/utils.lua, ui/tokens.lua, core.lua (for section state)
]]

local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- Lazy-loaded Core for section state
local _core = nil

--- Initialize containers module
-- @param core Core module reference
function M.init(core)
    _core = core
end

-- --- Collapsing Section ---

--- Collapsing section with persisted state
-- @param label Section label
-- @param defaultOpen Default open state
-- @param buildFn Function that builds section content
-- @param options Optional: {group, tooltip}
-- @return boolean isOpen
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
-- @param label Node label
-- @param buildFn Function that builds node content
-- @return boolean isOpen
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
-- @param label Node label
-- @param icon Icon text/glyph (optional)
-- @param buildFn Function that builds node content
-- @return boolean isOpen
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

return M
