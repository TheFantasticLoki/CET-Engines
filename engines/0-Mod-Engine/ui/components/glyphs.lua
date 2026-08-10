--[[
    Glyphs — UI-Engine Component Library

    Centralized CET IconGlyphs rendering. All glyph drawing goes through
    this module so consumers never duplicate ImDrawListAddText boilerplate.

    CET constraints enforced here:
      - Static ImGui.ImDrawListAddText(drawList, ...) — no method syntax
      - No pcall around individual draw calls (breaks LuaJIT FFI)
      - Font size passed explicitly to ImDrawListAddText 7-arg overload
      - Centering uses renderSize, not CalcTextSize (which returns wrong width)

    Dependencies: IconGlyphs global (CET MaterialDesign icons)

    Usage:
        local Glyphs = require("ui/components/glyphs")

        -- Button with centered glyph
        local clicked = Glyphs.Button("##id", "Palette", {
            size = 28, tooltip = "Theme", fallback = "T",
        })

        -- Inline glyph at cursor
        Glyphs.Inline("Palette", { spacing = 4 })

        -- Centered glyph on last item (button, selectable, etc.)
        Glyphs.CenteredOnItem("Palette", { size = 22 })

        -- Large preview
        Glyphs.Preview("Palette", { size = 48 })
]]

---@class Glyphs
local M = {}

-- ============================================================================
-- Logger (late-bound)
-- ============================================================================

local _log = nil

--- Initialize the logger (called by init.lua after first logger is created)
---@param logger table|nil Logger instance or nil to disable
function M.setLogger(logger)
    _log = logger
end

-- ============================================================================
-- Feature detection (cached at load time)
-- ============================================================================

local _available = nil

--- Check if CET supports ImDrawListAddText rendering
---@return boolean
function M.Available()
    if _available ~= nil then return _available end
    _available = ImGui.GetWindowDrawList ~= nil
        and ImGui.GetItemRectMin ~= nil
        and ImGui.GetItemRectMax ~= nil
        and ImGui.ImDrawListAddText ~= nil
        and ImGui.GetColorU32 ~= nil
        and ImGui.GetFontSize ~= nil
    return _available
end

-- ============================================================================
-- Safe accessor
-- ============================================================================

--- Get an icon glyph from the CET IconGlyphs global
---@param name string Icon name (e.g., "Palette", "Star")
---@param fallback string|nil Fallback if glyph unavailable
---@return string|nil glyph
function M.Get(name, fallback)
    if not IconGlyphs or not name then return fallback end
    local glyph = IconGlyphs[name]
    if type(glyph) == "string" and glyph ~= "" then return glyph end
    return fallback
end

--- Get an icon glyph with debug logging
---@param name string Icon name (e.g., "Check", "AlphaX")
---@param fallback string|nil Fallback if glyph unavailable
---@return string|nil glyph
function M.GetLogged(name, fallback)
    if not IconGlyphs then
        if _log then _log.debug("Glyphs.GetLogged: IconGlyphs global is nil") end
        return fallback
    end
    if not name then
        if _log then _log.debug("Glyphs.GetLogged: name is nil") end
        return fallback
    end
    local glyph = IconGlyphs[name]
    if type(glyph) == "string" and glyph ~= "" then
        if _log then _log.debug(string.format("Glyphs.Get(%s) = found", name)) end
        return glyph
    end
    if _log then _log.debug(string.format("Glyphs.Get(%s) = not found, fallback=%s", name, tostring(fallback))) end
    return fallback
end

-- ============================================================================
-- Core draw helper
-- ============================================================================

--- Draw a glyph at the given position using ImDrawListAddText
---@param drawList userdata Window draw list
---@param glyph string The icon glyph character
---@param x number Screen X position
---@param y number Screen Y position
---@param size number Font size in pixels
---@param color number Packed U32 color
local function drawGlyph(drawList, glyph, x, y, size, color)
    ImGui.ImDrawListAddText(drawList, size, x, y, color, glyph)
end

-- ============================================================================
-- Public rendering functions
-- ============================================================================

--- Draw a button with a centered icon glyph.
--- Replaces the old DrawIconGlyphButton pattern.
---@param id string Unique button ID (e.g., "##sidebar_settings")
---@param iconName string IconGlyphs name (e.g., "Palette")
---@param opts table|nil Options: { size, glyphSize, tooltip, fallback, color }
---@return boolean clicked
function M.Button(id, iconName, opts)
    opts = opts or {}
    local btnSize = opts.size or 28
    local glyph = M.Get(iconName, opts.fallback)
    local display = glyph or opts.fallback or ""

    -- When we have a glyph, hide the label so we can draw it centered
    local hasGlyph = glyph ~= nil and glyph ~= ""
    local label = hasGlyph and ("##" .. id) or (display .. "##" .. id)

    local clicked = ImGui.Button(label, btnSize, btnSize)

    if hasGlyph and M.Available() then
        local renderSize = opts.glyphSize or math.floor(btnSize * 0.7)
        local color = opts.color or ImGui.GetColorU32(1.0, 1.0, 1.0, 0.96)
        local minX, minY = ImGui.GetItemRectMin()
        local maxX, maxY = ImGui.GetItemRectMax()
        local btnW = maxX - minX
        local btnH = maxY - minY
        drawGlyph(
            ImGui.GetWindowDrawList(), glyph,
            minX + (btnW - renderSize) * 0.5,
            minY + (btnH - renderSize) * 0.5,
            renderSize, color
        )
    end

    if opts.tooltip and ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.Text(opts.tooltip)
        ImGui.EndTooltip()
    end

    return clicked
end

--- Draw an icon glyph at the current cursor position.
--- Advances the cursor past the glyph so subsequent content appears after it.
--- Replaces the old DrawIconGlyphInline pattern.
---@param iconName string IconGlyphs name
---@param opts table|nil Options: { size, color, spacing }
---@return boolean drawn True if glyph was drawn
function M.Inline(iconName, opts)
    opts = opts or {}
    local glyph = M.Get(iconName)
    if not glyph or not M.Available() then return false end

    local renderSize = opts.size or ImGui.GetFontSize()
    local color = opts.color or ImGui.GetColorU32(1.0, 1.0, 1.0, 0.9)
    local spacing = opts.spacing or 4

    local x, y = ImGui.GetCursorScreenPos()
    drawGlyph(ImGui.GetWindowDrawList(), glyph, x, y, renderSize, color)

    -- Advance cursor past the glyph
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + renderSize + spacing)
    return true
end

--- Draw a glyph centered on the last item (button, selectable, etc.).
--- Replaces the old DrawCenteredButtonText pattern.
---@param iconName string IconGlyphs name
---@param opts table|nil Options: { size, color }
function M.CenteredOnItem(iconName, opts)
    opts = opts or {}
    local glyph = M.Get(iconName)
    if not glyph or not M.Available() then return end

    local renderSize = opts.size or ImGui.GetFontSize()
    local color = opts.color or ImGui.GetColorU32(1.0, 1.0, 1.0, 0.96)

    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()
    local btnW = maxX - minX
    local btnH = maxY - minY

    drawGlyph(
        ImGui.GetWindowDrawList(), glyph,
        minX + (btnW - renderSize) * 0.5,
        minY + (btnH - renderSize) * 0.5,
        renderSize, color
    )
end

--- Draw a large icon glyph preview.
--- Used in icon browser detail panels and category previews.
---@param iconName string IconGlyphs name
---@param opts table|nil Options: { size, color }
function M.Preview(iconName, opts)
    opts = opts or {}
    local glyph = M.Get(iconName)
    if not glyph or not M.Available() then return end

    local previewSize = opts.size or 48
    local renderSize = previewSize - 8
    local color = opts.color or ImGui.GetColorU32(1.0, 1.0, 1.0, 1.0)

    ImGui.InvisibleButton("##glyph_preview_" .. iconName, previewSize, previewSize)

    local minX, minY = ImGui.GetItemRectMin()
    local maxX, maxY = ImGui.GetItemRectMax()
    local btnW = maxX - minX
    local btnH = maxY - minY

    drawGlyph(
        ImGui.GetWindowDrawList(), glyph,
        minX + (btnW - renderSize) * 0.5,
        minY + (btnH - renderSize) * 0.5,
        renderSize, color
    )
end

return M
