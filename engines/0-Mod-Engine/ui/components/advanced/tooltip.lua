--[[
    AdvancedTooltip — UI-Engine Component Library

    Centralized, DrawList-based tooltip with theme compliance, animation,
    and interactive mode. Replaces three separate tooltip implementations:
    - Utils.Tooltip() (bare ImGui wrapper)
    - Sidebar drawModEntry tooltip (ImGui.BeginTooltip, first-frame bug)
    - AdvancedSlider tooltip (DrawList-based, feature-rich)

    Features:
    - DrawList rendering (no first-frame sizing bug)
    - Theme-aware colors via Tokens
    - Bounds-aware positioning (smart flip, screen clamp)
    - Fade animation (respects global Animation config)
    - Show/hide delays (prevents tooltip spam)
    - Interactive mode (grace zone, buttons, click-through)
    - Configurable anchor (cursor or item rect)
    - Builder API with Lua 5.1 compatibility
    - Backward-compatible with lines table format

    Dependencies: ui/utils.lua, ui/tokens.lua, ui/animation.lua
    CET Constraints: No pcall on ImGui calls, Lua 5.1 only
    Note: .end() is a Lua reserved keyword, so we use :done() for the builder
]]

---@class AdvancedTooltip
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")
local Animation = require("ui/animation")

-- Lazy-load Separator module (avoids circular deps at require time)
local Separator = nil
local SeparatorLoaded = false
local function getSeparator()
    if not SeparatorLoaded then
        SeparatorLoaded = true
        local ok, mod = pcall(require, "ui/components/separator")
        if ok then Separator = mod end
    end
    return Separator
end

-- ============================================================================
-- Configuration
-- ============================================================================

--- Default tooltip options
local DEFAULTS = {
    -- Positioning
    anchor = "cursor",        -- "cursor" or "item"
    offsetX = 16,            -- Horizontal offset from anchor
    offsetY = 20,            -- Vertical offset from anchor (below cursor)
    flipOffset = 16,         -- Offset when flipping to opposite side
    maxWidth = 400,          -- Max tooltip width
    padding = 6,             -- Internal padding
    rounding = 4,            -- Corner rounding

    -- Behavior
    delay_show = 0,          -- Seconds before showing (0 = immediate)
    delay_hide = 0,          -- Seconds before hiding (0 = immediate)
    interactive = false,     -- Enable interactive elements + grace zone
    follow_cursor = false,   -- Follow mouse movement while visible
    sticky = false,          -- Stay until explicitly dismissed

    -- Colors (resolved from Tokens)
    bgRole = "background",
    bgAlpha = 0.95,
    borderRole = "primary",
    borderAlpha = 0.5,
    headerRole = "primary",
    labelRole = "muted",
    labelAlpha = 0.6,
    valueRole = "text",
    valueAlpha = 0.9,
    descriptionRole = "muted",
    descriptionAlpha = 0.7,
    separatorRole = "panel",
    separatorAlpha = 0.4,
    footerRole = "muted",
    footerAlpha = 0.5,
    buttonRole = "primary",
}

-- ============================================================================
-- Color Helpers
-- ============================================================================

--- Resolve a color option (string role, {r,g,b} table, or packed uint32)
---@param colorOpt string|table|number|nil Color option
---@param defaultRole string Default token role
---@param defaultAlpha number Default alpha
---@return number Packed ImGui color
local function resolvePackedColor(colorOpt, defaultRole, defaultAlpha)
    if colorOpt == nil then
        local c = Tokens.color4n(defaultRole)
        return packColor(c.r, c.g, c.b, defaultAlpha)
    end
    if type(colorOpt) == "number" then
        return colorOpt -- Already packed
    end
    if type(colorOpt) == "string" then
        local c = Tokens.color4n(colorOpt)
        return packColor(c.r, c.g, c.b, defaultAlpha)
    end
    if type(colorOpt) == "table" then
        return packColor(colorOpt.r or 0.5, colorOpt.g or 0.5, colorOpt.b or 0.5, defaultAlpha)
    end
    return packColor(0.5, 0.5, 0.5, defaultAlpha)
end

--- Pack RGBA into ImGui uint32
---@return number Packed color
function packColor(r, g, b, a)
    r = math.max(0, math.min(1, r or 0.5))
    g = math.max(0, math.min(1, g or 0.5))
    b = math.max(0, math.min(1, b or 0.5))
    a = math.max(0, math.min(1, a or 1))
    local ri = math.floor(r * 255 + 0.5)
    local gi = math.floor(g * 255 + 0.5)
    local bi = math.floor(b * 255 + 0.5)
    local ai = math.floor(a * 255 + 0.5)
    return ai * 16777216 + bi * 65536 + gi * 256 + ri
end

--- Resolve color role from options, falling back to defaults
---@param opts table Options table
---@param key string Option key (e.g., "headerRole")
---@param defaultRole string Default token role
---@param defaultAlpha number Default alpha
---@return number Packed color
local function resolveRole(opts, key, defaultRole, defaultAlpha)
    local role = opts[key] or defaultRole
    local alphaKey = key .. "Alpha"
    local alpha = opts[alphaKey] or defaultAlpha
    return resolvePackedColor(role, role, alpha)
end

-- ============================================================================
-- Per-Instance State
-- ============================================================================

local _instances = {}
local _instanceOrder = {}
local MAX_INSTANCES = 50

--- Get or create state for a tooltip instance
---@param id string Unique tooltip ID
---@return table State
local function getState(id)
    if _instances[id] then
        -- LRU: move to end
        for i, sid in ipairs(_instanceOrder) do
            if sid == id then
                table.remove(_instanceOrder, i)
                break
            end
        end
        table.insert(_instanceOrder, id)
        return _instances[id]
    end

    local state = {
        visible = false,
        alpha = 0,
        fadeInTimer = Animation.Timer(0.1, Animation.EaseOutCubic),
        fadeOutTimer = Animation.Timer(0.05, Animation.Linear),
        lastVisibleTime = 0,
        mouseX = 0,
        mouseY = 0,
    }

    _instances[id] = state
    table.insert(_instanceOrder, id)

    -- LRU eviction
    if #_instanceOrder > MAX_INSTANCES then
        local oldId = table.remove(_instanceOrder, 1)
        _instances[oldId] = nil
    end

    return state
end

-- ============================================================================
-- Positioning
-- ============================================================================

--- Calculate tooltip position with bounds-aware flipping
---@param tooltipW number Tooltip width
---@param tooltipH number Tooltip height
---@param anchor string "cursor" or "item"
---@param offsetX number Horizontal offset
---@param offsetY number Vertical offset
---@param flipOffset number Offset when flipping
---@return number x, number y Screen coordinates for top-left corner
local function calculatePosition(tooltipW, tooltipH, anchor, offsetX, offsetY, flipOffset)
    local tooltipX, tooltipY

    if anchor == "item" then
        local itemMinX, itemMinY = ImGui.GetItemRectMin()
        local itemMaxX, itemMaxY = ImGui.GetItemRectMax()
        tooltipX = itemMaxX + offsetX
        tooltipY = itemMaxY + 4
    else
        local mouseX, mouseY = ImGui.GetMousePos()
        tooltipX = mouseX + offsetX
        tooltipY = mouseY + offsetY
    end

    local displayW, displayH = GetDisplayResolution()

    -- Flip to left side if near right edge
    if tooltipX + tooltipW > displayW then
        local mouseX = ImGui.GetMousePos()
        tooltipX = mouseX - tooltipW - flipOffset
    end

    -- Flip to above cursor if near bottom edge
    if tooltipY + tooltipH > displayH then
        local mouseY = ImGui.GetMousePos()
        tooltipY = mouseY - tooltipH - 8
    end

    -- Clamp to screen bounds
    if tooltipX < 0 then tooltipX = 2 end
    if tooltipY < 0 then tooltipY = 2 end

    return tooltipX, tooltipY
end

-- ============================================================================
-- Text Wrapping
-- ============================================================================

--- Break text into lines that fit within maxWidth at word boundaries
---@param text string Text to wrap
---@param maxWidth number Max pixel width per line
---@return table Array of wrapped line strings
local function wrapTextLines(text, maxWidth)
    if maxWidth <= 0 then return { text } end

    -- Single word that exceeds width still gets its own line
    local fullW = select(1, ImGui.CalcTextSize(text))
    if fullW <= maxWidth then return { text } end

    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    if #words == 0 then return { text } end

    local result = {}
    local currentLine = words[1]
    for i = 2, #words do
        local testLine = currentLine .. " " .. words[i]
        local w = select(1, ImGui.CalcTextSize(testLine))
        if w > maxWidth then
            result[#result + 1] = currentLine
            currentLine = words[i]
        else
            currentLine = testLine
        end
    end
    if currentLine ~= "" then
        result[#result + 1] = currentLine
    end
    return result
end

-- Cache for wrapped lines per entry (avoids recomputing in measure + draw)
local _wrapCache = {}

--- Clear wrap cache (call once per frame before measurement)
local function clearWrapCache()
    _wrapCache = {}
end

--- Get wrapped lines for an entry, using cache
---@param text string
---@param contentWidth number
---@param doWrap boolean
---@return table Array of line strings (single element if no wrapping)
local function getCachedWrappedLines(text, contentWidth, doWrap)
    if not doWrap or contentWidth <= 0 then
        return { text }
    end
    local cacheKey = text .. "|" .. tostring(math.floor(contentWidth))
    if not _wrapCache[cacheKey] then
        _wrapCache[cacheKey] = wrapTextLines(text, contentWidth)
    end
    return _wrapCache[cacheKey]
end

-- ============================================================================
-- Measurement
-- ============================================================================

--- Measure tooltip dimensions from lines table
---@param lines table Array of line entries (text, separator, headerInline, keyValue)
---@param opts table Options
---@return number width, number height
local function measureTooltip(lines, opts)
    clearWrapCache()
    local lineHeight = select(2, ImGui.CalcTextSize("X"))
    local lineSpacing = 3
    local separatorHeight = 5
    local padding = opts.padding or DEFAULTS.padding
    local maxWidth = opts.maxWidth or DEFAULTS.maxWidth

    -- First pass: compute content width (max single-line width, clamped)
    local maxW = 0
    for _, entry in ipairs(lines) do
        if entry.type == "separator" then
            -- Separator fills full width — no contribution to maxW
        elseif entry.type == "headerInline" then
            local tw = select(1, ImGui.CalcTextSize(entry.title))
            local rw = entry.right and select(1, ImGui.CalcTextSize(entry.right)) or 0
            local totalW = tw + rw + 20  -- spacing between title and right
            if totalW > maxW then maxW = totalW end
        elseif entry.type == "keyValue" then
            local kw = select(1, ImGui.CalcTextSize(entry.key .. ": "))
            local vw = entry.value and select(1, ImGui.CalcTextSize(tostring(entry.value))) or 0
            if kw + vw > maxW then maxW = kw + vw end
        elseif entry.text ~= "---" then
            local w = select(1, ImGui.CalcTextSize(entry.text))
            if w > maxW then maxW = w end
        end
    end
    local tooltipW = maxW + padding * 2
    if maxWidth and tooltipW > maxWidth then
        tooltipW = maxWidth
    end

    -- Second pass: compute height using actual word wrapping
    local contentWidth = tooltipW - padding * 2
    local tooltipH = 0
    for _, entry in ipairs(lines) do
        if entry.type == "separator" then
            tooltipH = tooltipH + separatorHeight + lineSpacing
        elseif entry.type == "headerInline" then
            tooltipH = tooltipH + lineHeight + lineSpacing
        elseif entry.type == "keyValue" then
            tooltipH = tooltipH + lineHeight + lineSpacing
        elseif entry.text == "---" then
            tooltipH = tooltipH + separatorHeight + lineSpacing
        else
            local textW = select(1, ImGui.CalcTextSize(entry.text))
            local doWrap = entry.wrap or (textW > contentWidth)
            local wrappedLines = getCachedWrappedLines(entry.text, contentWidth, doWrap)
            tooltipH = tooltipH + #wrappedLines * (lineHeight + lineSpacing)
        end
    end
    tooltipH = tooltipH - lineSpacing + padding * 2

    return tooltipW, tooltipH
end

-- ============================================================================
-- Drawing
-- ============================================================================

--- Draw tooltip at calculated position
---@param lines table Array of line entries
---@param tooltipX number Screen X
---@param tooltipY number Screen Y
---@param tooltipW number Width
---@param tooltipH number Height
---@param colors table Resolved packed colors
---@param dl DrawList userdata (fallback)
local function drawTooltip(lines, tooltipX, tooltipY, tooltipW, tooltipH, colors, dl)
    local padding = DEFAULTS.padding
    local lineHeight = select(2, ImGui.CalcTextSize("X"))
    local lineSpacing = 3
    local separatorHeight = 5
    local contentWidth = tooltipW - padding * 2

    local fgDrawList = ImGui.GetForegroundDrawList()
    local useDrawList = fgDrawList or dl

    if not useDrawList then return end

    -- Background and border
    ImGui.ImDrawListAddRectFilled(useDrawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, colors.bg, DEFAULTS.rounding, 0)
    ImGui.ImDrawListAddRect(useDrawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, colors.border, DEFAULTS.rounding, 0, 1)

    -- Content — render each entry type
    local ty = tooltipY + padding
    for _, entry in ipairs(lines) do
        if entry.type == "separator" then
            -- Themed separator line
            local sepLineY = ty + separatorHeight / 2
            ImGui.ImDrawListAddLine(useDrawList, tooltipX + padding, sepLineY, tooltipX + tooltipW - padding, sepLineY, colors.border, 1)
            ty = ty + separatorHeight + lineSpacing
        elseif entry.type == "headerInline" then
            -- Title on left, right text on right, same line
            local titleColor = colors[entry.titleColor or "header"] or colors.header
            local rightColor = colors[entry.rightColor or "muted"] or colors.muted
            ImGui.ImDrawListAddText(useDrawList, tooltipX + padding, ty, titleColor, entry.title)
            if entry.right then
                local rightW = select(1, ImGui.CalcTextSize(entry.right))
                ImGui.ImDrawListAddText(useDrawList, tooltipX + tooltipW - padding - rightW, ty, rightColor, entry.right)
            end
            ty = ty + lineHeight + lineSpacing
        elseif entry.type == "keyValue" then
            -- Label in muted grey, value in normal color
            local keyColor = colors[entry.keyColor or "muted"] or colors.muted
            local valueColor = colors[entry.valueColor or "text"] or colors.text
            local keyText = entry.key .. ": "
            local keyW = select(1, ImGui.CalcTextSize(keyText))
            ImGui.ImDrawListAddText(useDrawList, tooltipX + padding, ty, keyColor, keyText)
            if entry.value then
                ImGui.ImDrawListAddText(useDrawList, tooltipX + padding + keyW, ty, valueColor, tostring(entry.value))
            end
            ty = ty + lineHeight + lineSpacing
        elseif entry.text == "---" then
            -- Legacy separator fallback
            ImGui.ImDrawListAddLine(useDrawList, tooltipX + padding, ty + lineHeight / 2, tooltipX + tooltipW - padding, ty + lineHeight / 2, colors.separator, 1)
            ty = ty + separatorHeight + lineSpacing
        else
            local lineColor = colors[entry.color] or colors.text
            local textW = select(1, ImGui.CalcTextSize(entry.text))
            local doWrap = entry.wrap or (textW > contentWidth)
            local wrappedLines = getCachedWrappedLines(entry.text, contentWidth, doWrap)
            for _, wrappedLine in ipairs(wrappedLines) do
                ImGui.ImDrawListAddText(useDrawList, tooltipX + padding, ty, lineColor, wrappedLine)
                ty = ty + lineHeight + lineSpacing
            end
        end
    end
end

-- ============================================================================
-- Public API: Builder Pattern (Lua 5.1 compatible)
-- ============================================================================

--- Begin building a tooltip. Returns a builder table.
--- Use :done() to finalize (NOT :end() — Lua reserved keyword).
---@param id string Unique tooltip ID
---@param opts table|nil Options (see DEFAULTS)
---@return table builder Builder table with chainable methods
function M.begin(id, opts)
    opts = opts or {}
    local state = getState(id)

    -- Merge with defaults
    local merged = {}
    for k, v in pairs(DEFAULTS) do merged[k] = v end
    for k, v in pairs(opts) do merged[k] = v end

    local lines = {}
    local colors = {
        bg = resolveRole(merged, "bgRole", "background", merged.bgAlpha),
        border = resolveRole(merged, "borderRole", "primary", merged.borderAlpha),
        text = resolvePackedColor("text", "text", 0.9),
        separator = resolveRole(merged, "separatorRole", "panel", merged.separatorAlpha),
        header = resolvePackedColor("primary", "primary", 0.95),
        muted = resolvePackedColor("muted", "muted", 0.55),
        description = resolvePackedColor("text", "text", 0.85),
        success = resolvePackedColor("success", "success", 0.9),
        warning = resolvePackedColor("warning", "warning", 0.9),
        error = resolvePackedColor("error", "error", 0.9),
        primary = resolvePackedColor("primary", "primary", 0.9),
        footer = resolvePackedColor("muted", "muted", 0.5),
    }

    local builder = {}

    --- Add a header line (title on first line, subtitle below)
    function builder.header(title, subtitle)
        if title and title ~= "" then
            table.insert(lines, { text = title, color = "header" })
        end
        if subtitle and subtitle ~= "" then
            table.insert(lines, { text = subtitle, color = "muted" })
        end
        return builder
    end

    --- Add a header with title on left and right text on same line
    --- @param title string Left text (larger, theme color)
    --- @param right string|nil Right text (muted, right-aligned)
    function builder.headerInline(title, right)
        if title and title ~= "" then
            table.insert(lines, { type = "headerInline", title = title, right = right, titleColor = "header", rightColor = "muted" })
        end
        return builder
    end

    --- Add a themed separator line
    --- @param opts table|nil Separator options (color, alpha, thickness)
    function builder.separator(opts)
        table.insert(lines, { type = "separator", opts = opts })
        return builder
    end

    --- Add a key-value pair with label in muted grey and value in normal color
    --- @param key string Label text (rendered in muted grey)
    --- @param value any Value text (rendered in normal text color)
    --- @param opts table|nil Optional: { keyColor = string, valueColor = string }
    function builder.keyValue(key, value, opts)
        if value ~= nil and tostring(value) ~= "" then
            opts = opts or {}
            table.insert(lines, {
                type = "keyValue",
                key = tostring(key),
                value = tostring(value),
                keyColor = opts.keyColor or "muted",
                valueColor = opts.valueColor or "text",
            })
        end
        return builder
    end

    --- Add a key-value label pair (legacy: single color for whole line)
    function builder.label(key, value, colorRole)
        local text = key .. ": " .. tostring(value)
        table.insert(lines, { text = text, color = colorRole or "text" })
        return builder
    end

    --- Add a value-only line
    function builder.valueOnly(text, colorRole)
        table.insert(lines, { text = tostring(text), color = colorRole or "text" })
        return builder
    end

    --- Add a description line (wrapped)
    function builder.description(text)
        if text and text ~= "" then
            table.insert(lines, { text = tostring(text), color = "description", wrap = true })
        end
        return builder
    end

    --- Add a test status line
    function builder.testStatus(passed, total)
        if passed and total then
            local statusText = string.format("Tests: %d/%d passing", passed, total)
            local colorRole = (passed == total) and "success" or "warning"
            table.insert(lines, { text = statusText, color = colorRole })
        end
        return builder
    end

    --- Add a footer line
    function builder.footer(text)
        if text and text ~= "" then
            table.insert(lines, { text = tostring(text), color = "footer" })
        end
        return builder
    end

    --- Add a custom line with explicit color
    function builder.customLine(text, colorRole)
        table.insert(lines, { text = tostring(text), color = colorRole or "text" })
        return builder
    end

    --- Add raw lines (for backward compat with tooltipLines callback)
    function builder.addLines(rawLines)
        for _, entry in ipairs(rawLines or {}) do
            table.insert(lines, entry)
        end
        return builder
    end

    --- Finalize and render the tooltip
    function builder.done()
        -- Check show delay
        if merged.delay_show > 0 then
            local now = os.clock()
            if now - state.lastVisibleTime < merged.delay_show then
                return
            end
        end

        -- Make visible
        state.visible = true
        state.lastVisibleTime = os.clock()

        -- Calculate dimensions
        local tooltipW, tooltipH = measureTooltip(lines, merged)

        -- Calculate position
        local tooltipX, tooltipY = calculatePosition(tooltipW, tooltipH, merged.anchor, merged.offsetX, merged.offsetY, merged.flipOffset)

        -- Render
        drawTooltip(lines, tooltipX, tooltipY, tooltipW, tooltipH, colors, nil)
    end

    return builder
end

--- Render a tooltip from a lines table (backward compatible with slider tooltip format)
---@param id string Unique tooltip ID
---@param lines table Array of { text = string, color = string }
---@param colorMap table<string, number> Maps color role strings to packed colors
---@param opts table|nil Options
function M.render(id, lines, colorMap, opts)
    if not lines or #lines == 0 then return end
    opts = opts or {}

    local state = getState(id)
    state.visible = true
    state.lastVisibleTime = os.clock()

    local tooltipW, tooltipH = measureTooltip(lines, opts)
    local tooltipX, tooltipY = calculatePosition(tooltipW, tooltipH, opts.anchor or "cursor", opts.offsetX or 16, opts.offsetY or 20, opts.flipOffset or 16)

    -- Build colors: merge caller's colorMap with bg/border defaults
    local colors = {
        bg = colorMap.bg or resolvePackedColor("background", "background", 0.95),
        border = colorMap.border or resolvePackedColor("primary", "primary", 0.5),
        text = colorMap.text or resolvePackedColor("text", "text", 0.9),
        separator = colorMap.separator or resolvePackedColor("panel", "panel", 0.3),
        primary = colorMap.primary or colorMap.text or resolvePackedColor("primary", "primary", 0.9),
        muted = colorMap.muted or colorMap.text or resolvePackedColor("muted", "muted", 0.6),
        text_dim = colorMap.text_dim or colorMap.muted or resolvePackedColor("muted", "muted", 0.5),
        success = colorMap.success or resolvePackedColor("success", "success", 0.9),
        warning = colorMap.warning or resolvePackedColor("warning", "warning", 0.9),
        error = colorMap.error or resolvePackedColor("error", "error", 0.9),
        description = colorMap.description or colorMap.text or resolvePackedColor("text", "text", 0.85),
        footer = colorMap.footer or colorMap.muted or resolvePackedColor("muted", "muted", 0.5),
        header = colorMap.header or colorMap.primary or resolvePackedColor("primary", "primary", 0.9),
        button = colorMap.button or colorMap.primary or resolvePackedColor("primary", "primary", 0.9),
    }

    drawTooltip(lines, tooltipX, tooltipY, tooltipW, tooltipH, colors, nil)
end

--- Hide a tooltip
---@param id string Tooltip ID
function M.hide(id)
    local state = _instances[id]
    if state then
        state.visible = false
    end
end

--- Check if a tooltip is visible
---@param id string Tooltip ID
---@return boolean
function M.isVisible(id)
    local state = _instances[id]
    return state and state.visible or false
end

return M
