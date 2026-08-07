-- Config-Engine Main Window
-- Orchestrates sidebar + content area rendering.
-- Phase 7: Full implementation with cards, search, categories.

---@class CfgWindow
local M = {}

-- Dependencies (late-bound)
local Core = nil
local Components = nil
local Tokens = nil
local Sidebar = nil
local ContentArea = nil

--- Initialize the window module.
---@param deps table { core: CfgCore, components: table, tokens: table }
---@return nil
function M.init(deps)
    Core = deps.core
    Components = deps.components
    Tokens = deps.tokens
    -- Pre-load sidebar and content area (avoid pcall require every frame)
    local okS, sidebarMod = pcall(require, "cfg/ui/sidebar")
    if okS then Sidebar = sidebarMod end
    local okC, contentMod = pcall(require, "cfg/ui/content_area")
    if okC then ContentArea = contentMod end
end

--- Draw the main Config-Engine window.
-- Called by init.lua during onDraw.
---@param ctx table|nil UI-Engine context (unused, uses Components directly)
---@return nil
function M.draw(ctx)
    if not Core or not Components then return end

    -- Main window layout using columns
    local sidebarWidth = Core.getSidebarWidth()

    -- Render sidebar + content in a row layout
    if Components.BeginTable then
        local isOpen = Components.BeginTable("configengine_main", 2, {
            widths = { sidebarWidth, 0 }, -- 0 = fill remaining
            noHeader = true,
            noBorders = true,
            noInnerPad = true,
        })

        if isOpen then
            -- Sidebar column
            if Sidebar and Sidebar.draw then
                Sidebar.draw(ctx)
            end

            -- Content area column
            if ContentArea and ContentArea.draw then
                ContentArea.draw(ctx)
            end

            Components.EndTable()
        end
    end
end

return M
