-- Config-Engine Sidebar
-- Mod list, search, categories. Phase 7: basic implementation.

---@class CfgSidebar
---Mod list sidebar with search bar, category filtering, and selectable mod entries.
local M = {}

-- Dependencies (late-bound)
---@type table?
local Core = nil
---@type table?
local Components = nil

--- Initialize the sidebar module.
---@param deps table { core: CfgCore, components: ComponentsModule }
---@return nil
function M.init(deps)
    Core = deps.core
    Components = deps.components
end

--- Draw the sidebar.
---@param ctx table UI-Engine context
---@return nil
function M.draw(ctx)
    if not Core or not Components then return end

    -- Search bar
    local query = Core.getSearchQuery()
    local newQuery, queryChanged = Components.InputText(
        "##search",
        query or "",
        { placeholder = "Search mods...", width = -1 }
    )
    if queryChanged then
        Core.setSearchQuery(newQuery)
    end

    Components.Spacing(4)

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
                -- Mod selectable
                local isSelected = selectedMod == modId
                local icon = ""
                if mod.pinned then icon = Components.GetIcon and Components.GetIcon("star") or "* " end
                if mod.favorite then icon = icon .. (Components.GetIcon and Components.GetIcon("heart") or "+ ") end

                local clicked = Components.SafeSelectable(
                    icon .. label,
                    isSelected,
                    { tooltip = spec.description }
                )

                if clicked then
                    Core.setSelectedMod(modId)
                end
            end
        end
    end
end

return M
