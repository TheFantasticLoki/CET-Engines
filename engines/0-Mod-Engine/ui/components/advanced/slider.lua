--[[
    Advanced Slider — UI-Engine Component Library

    Fully DrawList-rendered slider with:
    - Pill-shaped track with gradient fill
    - Draggable handle with hover/active states
    - ± buttons with modifier key support
    - Dynamic default-position indicator
    - Smooth animations via os.clock()
    - Value tooltip on hover/drag

    Dependencies: ui/utils.lua, ui/tokens.lua, ui/animation.lua, ui/color_engine.lua

    Logging: Uses Log-Engine for comprehensive tracing.
    Errors are caught and logged; component degrades gracefully.

    CET Constraints:
    - No pcall on ImGui calls (breaks LuaJIT FFI)
    - DrawList may not be available in all CET versions
    - Lua 5.1: no goto, no GC metamethods, no packed tables
]]

---@class AdvancedSlider
local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")
local Animation = require("ui/animation")
local ColorEngine = require("ui/color_engine")

-- Lazy-loaded AdvancedTooltip (late-bound to avoid circular deps)
local AdvancedTooltip = nil
local function getTooltip()
    if not AdvancedTooltip then
        local ok, mod = pcall(require, "ui/components/advanced/tooltip")
        if ok then AdvancedTooltip = mod end
    end
    return AdvancedTooltip
end

-- Lazy-loaded Theme and LogEngine references
local _theme = nil
local _log = nil

-- ============================================================================
-- Constants
-- ============================================================================

-- Default sizing
local TRACK_HEIGHT = 18          -- Height of the slider track (pixels) — matches button height
local TRACK_ROUNDING = 9         -- Pill rounding radius (half of height for full pill)
local HANDLE_WIDTH = 6           -- Width of rectangular handle (when style="rect")
local HANDLE_HOVER_WIDTH = 7     -- Handle width on hover
local HANDLE_RADIUS = 12         -- Handle circle radius (when style="circle") - larger to fill track
local HANDLE_HOVER_RADIUS = 14   -- Handle circle radius on hover
local BUTTON_WIDTH = 20          -- ± button width
local BUTTON_HEIGHT = 18         -- ± button height
local BUTTON_SPACING = 4         -- Space between button and track
local DEFAULT_INDICATOR_SHORT = 4   -- Default indicator line length at default (25% of track)
local DEFAULT_INDICATOR_LONG = 14   -- Default indicator line length away from default (75% of track)
local TOOLTIP_OFFSET_Y = -18     -- Y offset for value tooltip above handle
local ANIMATION_DURATION = 0.12  -- Handle transition animation duration (seconds)

-- ============================================================================
-- Modifier Key Detection (CET uses ImGui.IsKeyDown with ImGuiKey enums)
-- ============================================================================

--- Check if a modifier key is currently held
local function isShiftDown()
    return ImGui.IsKeyDown(ImGuiKey.LeftShift) or ImGui.IsKeyDown(ImGuiKey.RightShift)
end

local function isCtrlDown()
    return ImGui.IsKeyDown(ImGuiKey.LeftCtrl) or ImGui.IsKeyDown(ImGuiKey.RightCtrl)
end

local function isAltDown()
    return ImGui.IsKeyDown(ImGuiKey.LeftAlt) or ImGui.IsKeyDown(ImGuiKey.RightAlt)
end

-- ============================================================================
-- Logging Helper
-- ============================================================================

--- Log a message with component prefix
---@param level Log level ("debug", "info", "warn", "error")
---@param msg Message string
local function logMsg(level, msg)
    if _log and _log[level] then
        _log[level]("[AdvSlider] " .. msg)
    end
end

--- Log a formatted message
---@param level Log level
---@param fmt Format string
---@param ... Format args
local function logFmt(level, fmt, ...)
    if _log and _log[level] then
        _log[level]("[AdvSlider] " .. string.format(fmt, ...))
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

--- Initialize advanced module with dependencies
---@param theme Theme module reference (optional)
---@param log Logger instance (Log-Engine or UI-Engine modules/logger) (optional)
function M.init(theme, log)
    _theme = theme
    -- Only accept loggers that have the standard Log-Engine API (info/debug/warn/error)
    -- The UI-Engine modules/logger.lua has Log(modName, msg, level) which is different
    if log and type(log.info) == "function" and type(log.debug) == "function" then
        _log = log
        _log.info("[AdvSlider] Module initialized")
    else
        _log = nil
    end
end

-- ============================================================================
-- State Management (per-slider instance)
-- ============================================================================

-- Track per-slider state by label ID with LRU eviction
local _states = {}
local _stateOrder = {}  -- insertion order for LRU eviction
local MAX_STATES = 100  -- Maximum number of cached slider states

--- Get or create state for a slider instance
---@param id Unique slider ID
---@return table State table
local function getState(id)
    if _states[id] then
        -- Move to end (most recently used)
        for i, sid in ipairs(_stateOrder) do
            if sid == id then
                table.remove(_stateOrder, i)
                break
            end
        end
        table.insert(_stateOrder, id)
        return _states[id]
    end

    -- Create new state
    local state = {
        -- Animation state
        handleAnim = Animation.Timer(ANIMATION_DURATION, Animation.EaseOutCubic),
        defaultIndicatorAnim = Animation.Timer(0.2, Animation.EaseOutCubic),

        -- Visual state (updated each frame)
        hovered = false,
        active = false,
        hoveringHandle = false,

        -- Drag state
        dragging = false,
        dragStartValue = 0,
        dragStartMouseX = 0,
        dragTrackMinX = 0,
        dragTrackMaxX = 0,
        dragTrackWidth = 0,

        -- Previous frame values (for animation triggers)
        prevValue = nil,
        prevDefault = nil,

        -- Tooltip state
        showTooltip = false,
        tooltipValue = 0,

        -- Init flag
        initialized = false,
    }

    _states[id] = state
    table.insert(_stateOrder, id)

    -- Evict oldest if over limit
    if #_stateOrder > MAX_STATES then
        local oldId = table.remove(_stateOrder, 1)
        _states[oldId] = nil
    end

    return state
end

-- ============================================================================
-- Color Helpers
-- ============================================================================

--- Get theme-aware color for a role
---@param role Token role name
---@return table Color {r, g, b}
local function getRoleColor(role)
    local color = Tokens.color4n(role)
    if color and color.r and color.g and color.b then
        return color
    end
    -- Fallback colors
    local fallbacks = {
        primary = { r = 0.4, g = 0.6, b = 1.0 },
        text = { r = 1.0, g = 1.0, b = 1.0 },
        muted = { r = 0.5, g = 0.5, b = 0.5 },
        panel = { r = 0.12, g = 0.12, b = 0.14 },
        background = { r = 0.08, g = 0.08, b = 0.10 },
    }
    return fallbacks[role] or { r = 0.5, g = 0.5, b = 0.5 }
end

--- Pack RGBA color into ImGui 32-bit format
-- ImGui uses ABGR byte order packed into a uint32
---@param r Red (0..1)
---@param g Green (0..1)
---@param b Blue (0..1)
---@param a Alpha (0..1)
---@return number Packed ImGui color
local function packColor(r, g, b, a)
    r = r or 0.5
    g = g or 0.5
    b = b or 0.5
    r = math.floor(r * 255 + 0.5)
    g = math.floor(g * 255 + 0.5)
    b = math.floor(b * 255 + 0.5)
    a = math.floor((a or 1) * 255 + 0.5)
    -- ImGui IM_COL32: ABGR byte order
    return a * 16777216 + b * 65536 + g * 256 + r
end

--- Pack a role color with alpha
---@param role Token role name
---@param a Alpha (0..1)
---@return number Packed ImGui color
local function roleColor(role, a)
    local c = getRoleColor(role)
    return packColor(c.r, c.g, c.b, a or 1)
end

-- ============================================================================
-- DrawList Helpers (CET static-function style)
-- ============================================================================

--- Draw a rounded rectangle
---@param drawList DrawList userdata
---@param x1 Top-left X
---@param y1 Top-left Y
---@param x2 Bottom-right X
---@param y2 Bottom-right Y
---@param color Packed color
---@param rounding Corner rounding
---@param thickness Border thickness (0 = filled)
local function drawRoundRect(drawList, x1, y1, x2, y2, color, rounding, thickness)
    if not drawList then return end
    if thickness and thickness > 0 then
        ImGui.ImDrawListAddRect(drawList, x1, y1, x2, y2, color, rounding, 0, thickness)
    else
        ImGui.ImDrawListAddRectFilled(drawList, x1, y1, x2, y2, color, rounding, 0)
    end
end

--- Draw a circle
---@param drawList DrawList userdata
---@param cx Center X
---@param cy Center Y
---@param radius Radius
---@param color Packed color
---@param thickness Border thickness (0 = filled)
local function drawCircle(drawList, cx, cy, radius, color, thickness)
    if not drawList then return end
    if thickness and thickness > 0 then
        ImGui.ImDrawListAddCircle(drawList, cx, cy, radius, color, 0, thickness)
    else
        ImGui.ImDrawListAddCircleFilled(drawList, cx, cy, radius, color, 0)
    end
end

--- Draw a line
---@param drawList DrawList userdata
---@param x1 Start X
---@param y1 Start Y
---@param x2 End X
---@param y2 End Y
---@param color Packed color
---@param thickness Line thickness
local function drawLine(drawList, x1, y1, x2, y2, color, thickness)
    if not drawList then return end
    ImGui.ImDrawListAddLine(drawList, x1, y1, x2, y2, color, thickness)
end

--- Draw text
---@param drawList DrawList userdata
---@param x Position X
---@param y Position Y
---@param color Packed color
---@param text Text string
local function drawText(drawList, x, y, color, text)
    if not drawList then return end
    ImGui.ImDrawListAddText(drawList, x, y, color, text)
end

--- Safe draw call wrapper (calls drawList method with args)
---@param drawList DrawList userdata
---@param method Method name (string)
---@param ... Method arguments
local function safeDraw(drawList, method, ...)
    if not drawList then return end
    local fn = drawList[method]
    if fn then
        fn(drawList, ...)
    end
end

-- ============================================================================
-- Value <-> Position Conversion
-- ============================================================================

--- Convert value to track position (0..1)
---@param value Current value
---@param min Range minimum
---@param max Range maximum
---@return number Position (0..1)
local function valueToPos(value, min, max)
    if max == min then return 0 end
    return Animation.Clamp((value - min) / (max - min), 0, 1)
end

--- Convert track position to value
---@param pos Position (0..1)
---@param min Range minimum
---@param max Range maximum
---@return number Value
local function posToValue(pos, min, max)
    return min + pos * (max - min)
end

-- ============================================================================
-- Extracted Drawing Functions
-- ============================================================================

--- Draw a slider button (minus or plus) with hover/active states and symbol.
---@param dl DrawList userdata
---@param x number Button X position
---@param y number Button Y position
---@param w number Button width
---@param h number Button height
---@param rounding number Corner rounding
---@param isPlus boolean true for plus, false for minus
---@param normalColor number Packed color for normal state
---@param hoverColor number Packed color for hover state
---@param activeColor number Packed color for active state
---@param symbolColor number Packed color for the +/- symbol
---@param symbolHoverColor number Packed color for symbol on hover
local function drawSliderButton(dl, x, y, w, h, rounding, isPlus, normalColor, hoverColor, activeColor, symbolColor, symbolHoverColor)
    local hov = ImGui.IsItemHovered()
    local act = ImGui.IsItemActive()
    local col = act and activeColor or (hov and hoverColor or normalColor)
    drawRoundRect(dl, x, y, x + w, y + h, col, rounding, 0)
    local sCol = hov and symbolHoverColor or symbolColor
    local cx = x + w / 2
    local cy = y + h / 2
    if isPlus then
        drawLine(dl, cx - 4, cy, cx + 4, cy, sCol, 1.5)
        drawLine(dl, cx, cy - 4, cx, cy + 4, sCol, 1.5)
    else
        drawLine(dl, cx - 4, cy, cx + 4, cy, sCol, 1.5)
    end
end

--- Draw position indicator ticks above the track.
---@param dl DrawList userdata
---@param trackX1 number Track left X
---@param trackX2 number Track right X
---@param trackY number Track top Y
---@param trackWidth number Track width
---@param showTicks boolean Whether to show ticks
---@param majorTicks number Number of major ticks
---@param minorTicks number Number of minor ticks between majors
---@param majorTickHeight number Height of major ticks
---@param majorTickThickness number Thickness of major ticks
---@param centerTickHeight number Height of center tick
---@param centerTickThickness number Thickness of center tick
---@param minorTickHeight number Height of minor ticks
---@param minorTickThickness number Thickness of minor ticks
---@param majorTickColor number Packed color for major ticks
---@param centerTickColor number Packed color for center tick
---@param minorTickColor number Packed color for minor ticks
local function drawTrackTicks(dl, trackX1, trackX2, trackY, trackWidth,
    showTicks, majorTicks, minorTicks,
    majorTickHeight, majorTickThickness, centerTickHeight, centerTickThickness,
    minorTickHeight, minorTickThickness, majorTickColor, centerTickColor, minorTickColor)

    if not showTicks or majorTicks <= 0 then return end

    local totalSegments = majorTicks
    local majorSpacing = trackWidth / totalSegments

    -- Draw minor ticks first (behind majors)
    if minorTicks > 0 then
        local minorSpacing = majorSpacing / (minorTicks + 1)
        for maj = 0, totalSegments do
            for mino = 1, minorTicks do
                local tx = trackX1 + maj * majorSpacing + mino * minorSpacing
                if tx > trackX1 and tx < trackX2 then
                    drawLine(dl, tx, trackY - 1, tx, trackY - 1 - minorTickHeight, minorTickColor, minorTickThickness)
                end
            end
        end
    end

    -- Draw major ticks (skip edge ticks, enlarge center)
    for i = 0, totalSegments do
        local tx = trackX1 + i * majorSpacing
        if tx > trackX1 and tx < trackX2 then
            local isCenter = (i == math.floor(totalSegments / 2))
            local tickH = isCenter and centerTickHeight or majorTickHeight
            local tickCol = isCenter and centerTickColor or majorTickColor
            local tickThick = isCenter and centerTickThickness or majorTickThickness
            drawLine(dl, tx, trackY - 1, tx, trackY - 1 - tickH, tickCol, tickThick)
        end
    end
end

--- Draw the default position indicator line inside the track.
---@param dl DrawList userdata
---@param trackX1 number Track left X
---@param trackX2 number Track right X
---@param trackY number Track top Y
---@param trackHeight number Track height
---@param trackWidth number Track width
---@param value number Current value
---@param default number Default value
---@param min number Range minimum
---@param max number Range maximum
---@param indicatorLen number Current animated indicator length
---@param indicatorColor number Packed color
---@param indicatorThickness number Line thickness
local function drawDefaultIndicator(dl, trackX1, trackX2, trackY, trackHeight, trackWidth,
    value, default, min, max, indicatorLen, indicatorColor, indicatorThickness)

    if (max - min) <= 0 then return end
    local defaultPos = valueToPos(default, min, max)
    local defaultX = trackX1 + defaultPos * trackWidth
    local indCenterY = trackY + trackHeight / 2
    drawLine(dl, defaultX, indCenterY - indicatorLen / 2, defaultX, indCenterY + indicatorLen / 2, indicatorColor, indicatorThickness)
end

--- Draw the slider value tooltip using DrawList (foreground layer, bounds-aware).
---@param dl DrawList userdata (window draw list, used as fallback)
---@param lines table Array of { text = string, color = string }
---@param bg number Packed background color
---@param border number Packed border color
---@param colorMap table<string, number> Maps color role strings to packed colors
---@param anchor string|nil "cursor" (default) or "item" (anchor to triggering item rect)
local function drawSliderTooltip(dl, lines, bg, border, colorMap, anchor)
    if #lines == 0 then return end

    -- Calculate tooltip dimensions
    local lineHeight = select(2, ImGui.CalcTextSize("X"))
    local lineSpacing = 3
    local padding = 6
    local separatorHeight = 5 -- Extra height for separator lines
    local tooltipH = 0
    for _, entry in ipairs(lines) do
        if entry.text == "---" then
            tooltipH = tooltipH + separatorHeight + lineSpacing
        else
            tooltipH = tooltipH + lineHeight + lineSpacing
        end
    end
    tooltipH = tooltipH - lineSpacing + padding * 2 -- Remove last spacing, add padding

    local maxW = 0
    for _, entry in ipairs(lines) do
        if entry.text ~= "---" then
            local w = select(1, ImGui.CalcTextSize(entry.text))
            if w > maxW then maxW = w end
        end
    end
    local tooltipW = maxW + padding * 2

    -- Position at cursor or item rect depending on anchor
    local tooltipX, tooltipY
    if anchor == "item" then
        -- Anchor to the triggering item's bottom-right corner
        local itemMinX, itemMinY = ImGui.GetItemRectMin()
        local itemMaxX, itemMaxY = ImGui.GetItemRectMax()
        tooltipX = itemMaxX + 8
        tooltipY = itemMaxY + 4
    else
        -- Default: anchor to cursor (top-left corner near cursor)
        local mouseX, mouseY = ImGui.GetMousePos()
        tooltipX = mouseX + 16
        tooltipY = mouseY + 20
    end

    -- Clamp to display bounds (game screen / CET window, not parent element)
    local displayW, displayH = GetDisplayResolution()
    local screenMaxX = displayW
    local screenMaxY = displayH

    -- Flip to left side if near right edge
    if tooltipX + tooltipW > screenMaxX then
        tooltipX = mouseX - tooltipW - 16
    end
    -- Flip to above cursor if near bottom edge
    if tooltipY + tooltipH > screenMaxY then
        tooltipY = mouseY - tooltipH - 8
    end
    -- Clamp horizontal to screen bounds
    if tooltipX < 0 then tooltipX = 2 end
    -- Clamp vertical — if still off-screen, snap to top
    if tooltipY < 0 then tooltipY = 2 end

    -- Use foreground draw list to render over everything
    local fgDrawList = ImGui.GetForegroundDrawList()
    if fgDrawList then
        ImGui.ImDrawListAddRectFilled(fgDrawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, bg, 4, 0)
        ImGui.ImDrawListAddRect(fgDrawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, border, 4, 0, 1)
        local ty = tooltipY + padding
        for _, entry in ipairs(lines) do
            if entry.text == "---" then
                -- Draw separator line using tooltip border color (accent color, centered)
                local sepPacked = border
                ImGui.ImDrawListAddLine(fgDrawList, tooltipX + padding, ty + separatorHeight / 2, tooltipX + tooltipW - padding, ty + separatorHeight / 2, sepPacked, 1)
                ty = ty + separatorHeight + lineSpacing
            else
                local lineColor = colorMap[entry.color] or colorMap["text"]
                ImGui.ImDrawListAddText(fgDrawList, tooltipX + padding, ty, lineColor, entry.text)
                ty = ty + lineHeight + lineSpacing
            end
        end
    else
        drawRoundRect(dl, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, bg, 4, 0)
        drawRoundRect(dl, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, border, 4, 1)
        local ty = tooltipY + padding
        for _, entry in ipairs(lines) do
            if entry.text == "---" then
                -- Draw separator line using tooltip border color (accent color, centered)
                local sepPacked = border
                ImGui.ImDrawListAddLine(dl, tooltipX + padding, ty + separatorHeight / 2, tooltipX + tooltipW - padding, ty + separatorHeight / 2, sepPacked, 1)
                ty = ty + separatorHeight + lineSpacing
            else
                local lineColor = colorMap[entry.color] or colorMap["text"]
                drawText(dl, tooltipX + padding, ty, lineColor, entry.text)
                ty = ty + lineHeight + lineSpacing
            end
        end
    end
end

--- Draw the handle (rectangle or circle style).
---@param dl DrawList userdata
---@param handleX number Handle center X
---@param handleCenterY number Handle center Y
---@param handleStyle string "rect" or "circle"
---@param state table Slider state (hovered, dragging)
---@param handleW number Rect handle width
---@param handleHoverW number Rect handle width on hover
---@param handleR number Circle handle radius
---@param handleHoverR number Circle handle radius on hover
---@param trackHeight number Track height (for rect handle height calculation)
---@param bodyColor number Packed handle body color
---@param bodyHoverColor number Packed handle body hover color
---@param bodyActiveColor number Packed handle body active color
---@param borderColor number Packed handle border color
---@param dotColor number Packed handle center dot color
---@param handleRounding number Corner rounding for rect handle
local function drawHandle(dl, handleX, handleCenterY, handleStyle, state,
    handleW, handleHoverW, handleR, handleHoverR, trackHeight,
    bodyColor, bodyHoverColor, bodyActiveColor, borderColor, dotColor, handleRounding)

    local bodyCol = state.dragging and bodyActiveColor or (state.hovered and bodyHoverColor or bodyColor)

    if handleStyle == "circle" then
        local hr = state.hovered and handleHoverR or handleR
        if state.dragging then
            drawCircle(dl, handleX, handleCenterY, hr + 3, roleColor("primary", 0.2), 0)
        end
        drawCircle(dl, handleX, handleCenterY, hr, bodyCol, 0)
        drawCircle(dl, handleX, handleCenterY, hr, borderColor, 1.5)
        drawCircle(dl, handleX, handleCenterY, 2, dotColor, 0)
    else
        local hw = state.hovered and handleHoverW or handleW
        local hh = trackHeight + 6
        local hhalf = hh / 2
        if state.dragging then
            drawRoundRect(dl, handleX - hw/2 - 2, handleCenterY - hhalf - 2, handleX + hw/2 + 2, handleCenterY + hhalf + 2, roleColor("primary", 0.2), handleRounding, 0)
        end
        drawRoundRect(dl, handleX - hw/2, handleCenterY - hhalf, handleX + hw/2, handleCenterY + hhalf, bodyCol, handleRounding, 0)
        drawRoundRect(dl, handleX - hw/2, handleCenterY - hhalf, handleX + hw/2, handleCenterY + hhalf, borderColor, handleRounding, 1)
    end
end

-- ============================================================================
-- AdvancedSlider Component
-- ============================================================================

--- Advanced DrawList-rendered slider with modifier keys, animations, and default indicator
-- Supports two call styles:
--   AdvancedSlider(label, value, options)  — new style (matches other components)
--   AdvancedSlider(spec)                   — legacy style {label, value, min, max, ...}
--
---@param label_or_spec Unique label/ID string OR spec table (legacy)
---@param value Current value (nil if using spec table)
---@param options Optional table:
--   {
--     -- Core value options
--     min = number,           -- Range minimum (default: 0)
--     max = number,           -- Range maximum (default: 100)
--     default = number,       -- Default value for indicator (default: (min+max)/2)
--     step = number,          -- Base step for ± buttons (default: (max-min)/100)
--     format = string,        -- Value format string (default: "%.2f")
--     onChange = function,     -- Callback: onChange(newValue)
--
--     -- Display options
--     label = string,         -- Display name for tooltip
--     description = string,   -- Optional description for tooltip
--     tooltip = string,       -- Additional tooltip text
--     width = number,         -- Total component width (default: 256)
--     height = number,        -- Component height (default: 36)
--
--     -- Toggle options (set to false to disable)
--     showButtons = boolean,  -- Show ± buttons (default: true)
--     showTooltip = boolean,  -- Show value tooltip on hover (default: true)
--     showDefaultLine = boolean, -- Show default position indicator (default: true)
--     showTicks = boolean,    -- Show position indicator ticks (default: true)
--
--     -- Style options
--     handleStyle = string,   -- "rect" (default) or "circle"
--     valueDisplay = string,  -- "auto", "inside", "button", "none" (default: "auto")
--
--     -- Sizing options
--     trackHeight = number,   -- Track height in pixels (default: 18)
--     trackRounding = number, -- Track corner rounding radius (default: trackHeight/2)
--     handleWidth = number,   -- Rect handle width (default: 6)
--     handleHoverWidth = number, -- Rect handle width on hover (default: 7)
--     handleRadius = number,  -- Circle handle radius (default: 10)
--     handleHoverRadius = number, -- Circle handle radius on hover (default: 12)
--     buttonWidth = number,   -- ± button width (default: 20)
--     buttonHeight = number,  -- ± button height (default: 18)
--     buttonSpacing = number, -- Space between button and track (default: 4)
--     buttonRounding = number, -- Button corner rounding (default: 4)
--     handleRounding = number, -- Handle corner rounding (default: 2)
--
--     -- Indicator options
--     indicatorShort = number, -- Default indicator length at default (default: 4)
--     indicatorLong = number,  -- Default indicator length away from default (default: 14)
--     indicatorThickness = number, -- Default indicator line thickness (default: 2)
--
--     -- Tick options
--     majorTicks = number,    -- Major tick count (default: 4)
--     minorTicks = number,    -- Minor ticks between each major (default: 2)
--     majorTickHeight = number, -- Major tick height (default: 7)
--     majorTickThickness = number, -- Major tick thickness (default: 1.5)
--     centerTickHeight = number, -- Center tick height (default: 9)
--     centerTickThickness = number, -- Center tick thickness (default: 2)
--     minorTickHeight = number, -- Minor tick height (default: 4)
--     minorTickThickness = number, -- Minor tick thickness (default: 1)
--
--     -- Color options (all accept role strings or {r,g,b} tables)
--     trackColor = string/table, -- Track background color (default: "panel")
--     trackBorderColor = string/table, -- Track border color (default: "muted")
--     trackBorderAlpha = number, -- Track border alpha (default: 0.3)
--     fillColor = string/table, -- Fill color (default: "primary")
--     fillAlphaActive = number, -- Fill alpha when dragging (default: 0.85)
--     fillAlphaHover = number, -- Fill alpha when hovered (default: 0.7)
--     fillAlphaNormal = number, -- Fill alpha normally (default: 0.6)
--     handleColor = string/table, -- Handle color (default: "primary")
--     handleBorder = string/table, -- Handle border color (default: "text")
--     handleBorderAlpha = number, -- Handle border alpha (default: 0.4)
--     handleDotColor = string/table, -- Handle center dot color (default: "text")
--     handleDotAlpha = number, -- Handle center dot alpha (default: 0.8)
--     buttonColor = string/table, -- Button color (default: "panel")
--     buttonHoverColor = string/table, -- Button hover color (default: "primary")
--     buttonActiveColor = string/table, -- Button active color (default: "primary")
--     buttonSymbolColor = string/table, -- Button symbol color (default: "text")
--     indicatorColor = string/table, -- Default indicator color (default: "text")
--     indicatorAlpha = number, -- Default indicator alpha (default: 0.6)
--     tickColor = string/table, -- Minor tick color (default: "muted")
--     tickAlpha = number, -- Minor tick alpha (default: 0.4)
--     majorTickColor = string/table, -- Major tick color (default: "muted")
--     majorTickAlpha = number, -- Major tick alpha (default: 0.6)
--     centerTickColor = string/table, -- Center tick color (default: "text")
--     centerTickAlpha = number, -- Center tick alpha (default: 0.7)
--     valueTextColor = string/table, -- Value text color (default: "text")
--     valueTextAlpha = number, -- Value text alpha (default: 0.9)
--     tooltipBgColor = string/table, -- Tooltip background (default: "background")
--     tooltipBgAlpha = number, -- Tooltip background alpha (default: 0.95)
--     tooltipBorderColor = string/table, -- Tooltip border (default: "primary")
--     tooltipBorderAlpha = number, -- Tooltip border alpha (default: 0.5)
--     tooltipLabelColor = string/table, -- Tooltip label color (default: "primary")
--     tooltipValueColor = string/table, -- Tooltip value color (default: "text")
--     tooltipDefaultColor = string/table, -- Tooltip default value color (default: "muted")
--     tooltipDescColor = string/table, -- Tooltip description color (default: "text")
--     tooltipDescAlpha = number, -- Tooltip description alpha (default: 0.6)
--     tooltipAnchor = string, -- "cursor" (default) or "item" (anchor to triggering item)
--
--     -- Behavior options
--     modifierShiftMult = number, -- Shift drag multiplier (default: 0.1)
--     modifierCtrlMult = number,  -- Ctrl drag multiplier (default: 0.01)
--     modifierAltMult = number,   -- Alt drag multiplier (default: 10)
--     buttonShiftMult = number,   -- Shift button multiplier (default: 10)
--     buttonCtrlMult = number,    -- Ctrl button multiplier (default: 0.5)
--     snapDistance = number,      -- Snap to default distance (default: 0.02 of range)
--     animationDuration = number, -- Animation duration in seconds (default: 0.12)
--     indicatorAnimDuration = number, -- Indicator animation duration (default: 0.2)
--   }
---@return number newValue, boolean changed
function M.AdvancedSlider(label_or_spec, value, options)
    -- ====================================================================
    -- API style detection: spec table vs (label, value, options)
    -- ====================================================================
    local label, opts
    if type(label_or_spec) == "table" then
        local spec = label_or_spec
        label = spec.label or "##advslider"
        value = spec.value or 0
        opts = {}
        opts.min = spec.min
        opts.max = spec.max
        opts.default = spec.default
        opts.step = spec.step
        opts.format = spec.format
        opts.tooltip = spec.tooltip
        opts.width = spec.width
        opts.onChange = spec.onChange
    else
        label = label_or_spec or "##advslider"
        opts = options or {}
    end

    -- Ensure min/max are ordered
    local min = opts.min or 0
    local max = opts.max or 100
    local default = opts.default
    if default == nil then default = (min + max) / 2 end
    local step = opts.step or (max - min) / 100
    local format = opts.format or "%.2f"
    local tooltip = opts.tooltip
    local tooltipAnchor = opts.tooltipAnchor or "cursor"
    local compWidth = opts.width or 256
    local compHeight = opts.height or 36
    local showButtons = opts.showButtons ~= false
    local showTooltip = opts.showTooltip ~= false
    local showDefaultLine = opts.showDefaultLine ~= false
    local handleStyle = opts.handleStyle or "rect"
    local onChange = opts.onChange

    -- Tick configuration
    local showTicks = opts.showTicks ~= false
    local majorTicks = opts.majorTicks or 4
    local minorTicks = opts.minorTicks or 2

    -- Value display configuration
    local valueDisplay = opts.valueDisplay or "auto"
    local valueLabel = opts.label or nil
    local valueDescription = opts.description or nil

    -- Sizing options
    local trackHeight = opts.trackHeight or TRACK_HEIGHT
    local trackRounding = opts.trackRounding or (trackHeight / 2)
    local handleW = opts.handleWidth or HANDLE_WIDTH
    local handleHoverW = opts.handleHoverWidth or HANDLE_HOVER_WIDTH
    local handleR = opts.handleRadius or HANDLE_RADIUS
    local handleHoverR = opts.handleHoverRadius or HANDLE_HOVER_RADIUS
    local btnW = opts.buttonWidth or BUTTON_WIDTH
    local btnH = opts.buttonHeight or BUTTON_HEIGHT
    local btnGap = opts.buttonSpacing or BUTTON_SPACING
    local btnRounding = opts.buttonRounding or 4
    local handleRounding = opts.handleRounding or 2

    -- Indicator options
    local indicatorShort = opts.indicatorShort or DEFAULT_INDICATOR_SHORT
    local indicatorLong = opts.indicatorLong or DEFAULT_INDICATOR_LONG
    local indicatorThickness = opts.indicatorThickness or 2

    -- Tick sizing options
    local majorTickHeight = opts.majorTickHeight or 7
    local majorTickThickness = opts.majorTickThickness or 1.5
    local centerTickHeight = opts.centerTickHeight or 9
    local centerTickThickness = opts.centerTickThickness or 2
    local minorTickHeight = opts.minorTickHeight or 4
    local minorTickThickness = opts.minorTickThickness or 1

    -- Color options (resolve role strings to packed colors)
    local function resolveColor(colorOpt, defaultRole, defaultAlpha)
        if colorOpt == nil then return roleColor(defaultRole, defaultAlpha) end
        if type(colorOpt) == "table" then
            return packColor(colorOpt.r or 0.5, colorOpt.g or 0.5, colorOpt.b or 0.5, defaultAlpha or 1)
        end
        return roleColor(colorOpt, defaultAlpha)
    end

    local trackBgColor = resolveColor(opts.trackColor, "panel", 1.0)
    local trackBorderColor = resolveColor(opts.trackBorderColor, "muted", opts.trackBorderAlpha or 0.3)
    local fillColorNormal = resolveColor(opts.fillColor, "primary", opts.fillAlphaNormal or 0.6)
    local fillColorHover = resolveColor(opts.fillColor, "primary", opts.fillAlphaHover or 0.7)
    local fillColorActive = resolveColor(opts.fillColor, "primary", opts.fillAlphaActive or 0.85)
    local handleBodyColor = resolveColor(opts.handleColor, "primary", 0.8)
    local handleBodyHoverColor = resolveColor(opts.handleColor, "primary", 0.9)
    local handleBodyActiveColor = resolveColor(opts.handleColor, "primary", 1.0)
    local handleBorderColor = resolveColor(opts.handleBorder, "text", opts.handleBorderAlpha or 0.4)
    local handleDotColor = resolveColor(opts.handleDotColor, "text", opts.handleDotAlpha or 0.8)
    local btnNormalColor = resolveColor(opts.buttonColor, "panel", 0.8)
    local btnHoverColor = resolveColor(opts.buttonHoverColor, "primary", 0.4)
    local btnActiveColor = resolveColor(opts.buttonActiveColor, "primary", 0.6)
    local btnSymbolColor = resolveColor(opts.buttonSymbolColor, "text", 0.8)
    local btnSymbolHoverColor = resolveColor(opts.buttonSymbolColor, "text", 1.0)
    local indicatorColor = resolveColor(opts.indicatorColor, "text", opts.indicatorAlpha or 0.6)
    local tickColorVal = resolveColor(opts.tickColor, "muted", opts.tickAlpha or 0.4)
    local majorTickColorVal = resolveColor(opts.majorTickColor, "muted", opts.majorTickAlpha or 0.6)
    local centerTickColorVal = resolveColor(opts.centerTickColor, "text", opts.centerTickAlpha or 0.7)
    local valueTextColor = resolveColor(opts.valueTextColor, "text", opts.valueTextAlpha or 0.9)
    local tooltipBgColor = resolveColor(opts.tooltipBgColor, "background", opts.tooltipBgAlpha or 0.95)
    local tooltipBorderColor = resolveColor(opts.tooltipBorderColor, "primary", opts.tooltipBorderAlpha or 0.5)
    local tooltipLabelColor = resolveColor(opts.tooltipLabelColor, "primary", 1.0)
    local tooltipValueColor = resolveColor(opts.tooltipValueColor, "text", 1.0)
    local tooltipDefaultColor = resolveColor(opts.tooltipDefaultColor, "muted", 0.7)
    local tooltipDescColor = resolveColor(opts.tooltipDescColor, "text", opts.tooltipDescAlpha or 0.6)

    -- Behavior options (auto-calculate from step when not explicitly set)
    -- Drag multipliers scale the base delta-per-pixel (which is range/trackWidth).
    -- Shift = 0.1x base → fine control (~10x more pixels per step)
    -- Ctrl  = 0.01x base → precision control (~100x more pixels per step)
    -- Alt   = scales with step size → coarse control (~10x fewer pixels per step)
    local range = max - min
    local modifierShiftMult = opts.modifierShiftMult or 0.1
    local modifierCtrlMult = opts.modifierCtrlMult or 0.01
    local modifierAltMult = opts.modifierAltMult or math.max(0.1, 10 * step / range)
    local buttonShiftMult = opts.buttonShiftMult or 10    -- 10x step per click
    local buttonCtrlMult = opts.buttonCtrlMult or 0.5     -- half step per click
    local animDuration = opts.animationDuration or ANIMATION_DURATION
    local indicatorAnimDuration = opts.indicatorAnimDuration or 0.2

    if min > max then min, max = max, min end
    value = Animation.Clamp(value, min, max)

    local changed = false
    local newValue = value
    local id = label

    -- ====================================================================
    -- Get DrawList
    -- ====================================================================
    local drawList = nil
    local drawListAvailable = false
    local dl = ImGui.GetWindowDrawList()
    if dl then
        drawList = dl
        drawListAvailable = true
    end

    -- Fallback mode
    if not drawListAvailable then
        ImGui.SetNextItemWidth(compWidth)
        local newV, used = Utils.SafeImGuiCall(ImGui.SliderFloat, label, value, min, max, format)
        if used then newValue = newV; changed = true end
        if tooltip and tooltip ~= "" then Utils.Tooltip(tooltip) end
        if changed and onChange and type(onChange) == "function" then
            pcall(onChange, newValue)
        end
        return newValue, changed
    end

    -- ====================================================================
    -- State for this slider instance
    -- ====================================================================
    local state = getState(id)
    if not state.initialized then
        state.initialized = true
        state.prevValue = value
        state.prevDefault = default
    end

    -- ====================================================================
    -- Animation updates
    -- ====================================================================
    state.handleAnim:update()
    state.defaultIndicatorAnim:update()

    -- ====================================================================
    -- Layout: [minusBtn] [track with handle] [plusBtn]
    -- ====================================================================
    local btnAreaW = showButtons and btnW or 0
    local btnGapArea = showButtons and btnGap or 0
    local trackWidth = compWidth - (btnAreaW + btnGapArea) * 2
    if trackWidth < 30 then trackWidth = 30 end

    local cursorX, cursorY = ImGui.GetCursorScreenPos()
    if not cursorX then cursorX = 0 end
    if not cursorY then cursorY = 0 end

    -- Button Y centered
    local buttonY = cursorY + (compHeight - btnH) / 2

    -- Track geometry (centered vertically)
    local trackY = cursorY + (compHeight - trackHeight) / 2
    local trackX1 = cursorX + btnAreaW + btnGapArea
    local trackX2 = trackX1 + trackWidth

    -- Handle position
    local pos = valueToPos(value, min, max)
    local handleX = trackX1 + pos * trackWidth
    local handleCenterY = trackY + trackHeight / 2

    -- ====================================================================
    -- Draw: Minus button (LEFT side)
    -- ====================================================================
    if showButtons then
        local minusX = cursorX
        ImGui.SetCursorScreenPos(minusX, buttonY)
        if ImGui.Button("##adv-" .. label .. "-minus", btnW, btnH) then
            local actualStep = step
            if isAltDown() then
                -- Alt: increment by 1 when buttons can't do fine adjustments
                -- (step != 1 AND range > 10 for meaningful integer stepping)
                if step ~= 1 and range > 10 then
                    actualStep = 1
                else
                    newValue = default
                    changed = true
                end
            elseif isShiftDown() then
                actualStep = step * buttonShiftMult
            elseif isCtrlDown() then
                actualStep = step * buttonCtrlMult
            end
            if not changed then
                newValue = Animation.Clamp(value - actualStep, min, max)
                if newValue ~= value then changed = true end
            end
        end
        -- Button visual
        drawSliderButton(drawList, minusX, buttonY, btnW, btnH, btnRounding, false,
            btnNormalColor, btnHoverColor, btnActiveColor, btnSymbolColor, btnSymbolHoverColor)
        -- Button tooltip
        if ImGui.IsItemHovered() then
            local altStep = step
            if step ~= 1 and range > 10 then altStep = 1 end
            local minusLines = {
                { text = string.format("Decrement (%s)", string.format(format, step)), color = "text" },
                { text = "---", color = "separator" },
                { text = string.format("Shift=%s  Ctrl=%s  Alt=%s",
                    string.format(format, step * buttonShiftMult),
                    step * buttonCtrlMult < 0.001 and "fine" or string.format(format, step * buttonCtrlMult),
                    step ~= 1 and range > 10 and string.format(format, 1) or "default"),
                    color = "text_dim" },
            }
            local minusColorMap = {
                text = tooltipValueColor,
                text_dim = tooltipDescColor,
                separator = tooltipBorderColor,
            }
            local tt = getTooltip()
            if tt then
                tt.render("slider_minus_" .. label, minusLines, minusColorMap, { anchor = tooltipAnchor })
            else
                drawSliderTooltip(drawList, minusLines, tooltipBgColor, tooltipBorderColor, minusColorMap, tooltipAnchor)
            end
        end
    end

    -- ====================================================================
    -- Draw: Track (InvisibleButton for interaction)
    -- ====================================================================
    ImGui.SetCursorScreenPos(trackX1, cursorY)
    local trackClicked = ImGui.InvisibleButton("##adv-track-" .. label, trackWidth, compHeight)
    state.hovered = ImGui.IsItemHovered()
    state.active = ImGui.IsItemActive()

    -- Click tracking: detect deliberate clicks vs drags
    local CLICK_THRESHOLD = 3  -- pixels of movement before considered a drag

    -- Live drag: update every frame while mouse is down
    if state.active then
        if not state.dragging then
            -- Just started holding — capture initial state
            state.dragging = true
            state.dragStartMouseX = select(1, ImGui.GetMousePos())
            state.dragTrackWidth = trackWidth
            state.dragStartValue = value
            state._clickStartX = state.dragStartMouseX
            state._clickStartY = select(2, ImGui.GetMousePos())
            state._clickModifiers = {
                shift = isShiftDown(),
                ctrl = isCtrlDown(),
                alt = isAltDown(),
            }
            state._lastShift = isShiftDown()
            state._lastCtrl = isCtrlDown()
            state._lastAlt = isAltDown()
            state._wasDrag = false
        end
        -- Track if user moved enough to count as a drag
        if not state._wasDrag then
            local mx, my = ImGui.GetMousePos()
            local dx = mx - state._clickStartX
            local dy = my - state._clickStartY
            if math.abs(dx) > CLICK_THRESHOLD or math.abs(dy) > CLICK_THRESHOLD then
                state._wasDrag = true
            end
        end
    elseif state.dragging then
        state.dragging = false
    end

    -- Click handling: only trigger click modifiers on deliberate clicks (not drag releases)
    if trackClicked and not state._wasDrag then
        local mouseX = select(1, ImGui.GetMousePos())
        local clickPos = Animation.Clamp((mouseX - trackX1) / trackWidth, 0, 1)
        local clickValue = posToValue(clickPos, min, max)

        local mods = state._clickModifiers or {}

        if mods.alt then
            -- Alt+click: reset to default
            newValue = default
            changed = true
            state.handleAnim:start()
        elseif mods.shift then
            -- Shift+click: jump to cursor position (snap)
            if math.abs(clickValue - default) < (range * 0.02) then
                clickValue = default  -- Snap to default if close
            end
            newValue = clickValue
            changed = true
            state.dragging = false
            state.handleAnim:start()
        elseif mods.ctrl then
            -- Ctrl+click: manual value input
            -- Store pending input state; the input dialog will be drawn below
            state._pendingInput = true
            state._inputValue = tostring(math.floor(value + 0.5))
        else
            -- Normal click: start delta-based drag from current handle position
            state.dragging = true
            state.dragStartMouseX = mouseX
            state.dragTrackWidth = trackWidth
            state.dragStartValue = value
            state._lastShift = false
            state._lastCtrl = false
            state._lastAlt = false
            state.handleAnim:start()
        end
    elseif trackClicked and state._wasDrag then
        -- Drag released — just clean up, don't trigger click modifiers
        state.dragging = false
    end

    -- ====================================================================
    -- Draw: Ctrl+click input dialog (manual value entry)
    -- ====================================================================
    if state._pendingInput then
        ImGui.OpenPopup("##slider_input_" .. label)
        state._pendingInput = false
    end
    if ImGui.BeginPopup("##slider_input_" .. label) then
        ImGui.Text("Enter value:")
        ImGui.SetNextItemWidth(120)
        local inputChanged, inputText = ImGui.InputText("##input", state._inputValue or "", 64, ImGuiInputTextFlags.EnterReturnsTrue)
        if inputChanged then
            local parsed = tonumber(inputText)
            if parsed then
                parsed = Animation.Clamp(parsed, min, max)
                newValue = parsed
                changed = true
            end
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        if ImGui.Button("OK", 50, 0) then
            local parsed = tonumber(state._inputValue or "")
            if parsed then
                parsed = Animation.Clamp(parsed, min, max)
                newValue = parsed
                changed = true
            end
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine()
        if ImGui.Button("Cancel", 50, 0) then
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end

    -- Live drag update (every frame while dragging)
    if state.dragging and state.active then
        local mouseX = select(1, ImGui.GetMousePos())
        local deltaPixels = mouseX - state.dragStartMouseX
        local deltaValue = (deltaPixels / state.dragTrackWidth) * (max - min)

        local shift = isShiftDown()
        local ctrl = isCtrlDown()
        local alt = isAltDown()
        if shift ~= state._lastShift or ctrl ~= state._lastCtrl or alt ~= state._lastAlt then
            state.dragStartValue = value
            state.dragStartMouseX = mouseX
            state._lastShift = shift
            state._lastCtrl = ctrl
            state._lastAlt = alt
            deltaPixels = 0
            deltaValue = 0
        end

        if shift then
            deltaValue = deltaValue * modifierShiftMult
        elseif ctrl then
            deltaValue = deltaValue * modifierCtrlMult
        elseif alt then
            deltaValue = deltaValue * modifierAltMult
        end

        local dragValue = Animation.Clamp(state.dragStartValue + deltaValue, min, max)
        if dragValue ~= value then
            newValue = dragValue
            changed = true
        end
    end

    -- ====================================================================
    -- Draw: Plus button (RIGHT side) — after track
    -- ====================================================================
    if showButtons then
        local plusX = trackX2 + btnGapArea
        ImGui.SetCursorScreenPos(plusX, buttonY)
        if ImGui.Button("##adv-" .. label .. "-plus", btnW, btnH) then
            local actualStep = step
            if isAltDown() then
                -- Alt: increment by 1 when buttons can't do fine adjustments
                -- (step != 1 AND range > 10 for meaningful integer stepping)
                if step ~= 1 and range > 10 then
                    actualStep = 1
                else
                    newValue = default
                    changed = true
                end
            elseif isShiftDown() then
                actualStep = step * buttonShiftMult
            elseif isCtrlDown() then
                actualStep = step * buttonCtrlMult
            end
            if not changed then
                newValue = Animation.Clamp(value + actualStep, min, max)
                if newValue ~= value then changed = true end
            end
        end
        -- Button visual
        drawSliderButton(drawList, plusX, buttonY, btnW, btnH, btnRounding, true,
            btnNormalColor, btnHoverColor, btnActiveColor, btnSymbolColor, btnSymbolHoverColor)
        -- Button tooltip
        if ImGui.IsItemHovered() then
            local plusLines = {
                { text = string.format("Increment (%s)", string.format(format, step)), color = "text" },
                { text = "---", color = "separator" },
                { text = string.format("Shift=%s  Ctrl=%s  Alt=%s",
                    string.format(format, step * buttonShiftMult),
                    step * buttonCtrlMult < 0.001 and "fine" or string.format(format, step * buttonCtrlMult),
                    step ~= 1 and range > 10 and string.format(format, 1) or "default"),
                    color = "text_dim" },
            }
            local plusColorMap = {
                text = tooltipValueColor,
                text_dim = tooltipDescColor,
                separator = tooltipBorderColor,
            }
            local tt = getTooltip()
            if tt then
                tt.render("slider_plus_" .. label, plusLines, plusColorMap, { anchor = tooltipAnchor })
            else
                drawSliderTooltip(drawList, plusLines, tooltipBgColor, tooltipBorderColor, plusColorMap, tooltipAnchor)
            end
        end
    end

    -- ====================================================================
    -- Draw: Track background (visible pill)
    -- ====================================================================
    drawRoundRect(drawList, trackX1, trackY, trackX2, trackY + trackHeight, trackBgColor, trackRounding, 0)
    drawRoundRect(drawList, trackX1, trackY, trackX2, trackY + trackHeight, trackBorderColor, trackRounding, 1)

    -- ====================================================================
    -- Draw: Position indicator ticks (configurable major/minor above track)
    -- ====================================================================
    drawTrackTicks(drawList, trackX1, trackX2, trackY, trackWidth,
        showTicks, majorTicks, minorTicks,
        majorTickHeight, majorTickThickness, centerTickHeight, centerTickThickness,
        minorTickHeight, minorTickThickness, majorTickColorVal, centerTickColorVal, tickColorVal)

    -- ====================================================================
    -- Draw: Track fill (from left to handle position — only left corners rounded)
    -- ====================================================================
    local fillColor = state.dragging and fillColorActive or (state.hovered and fillColorHover or fillColorNormal)
    if pos > 0.001 then
        local fillX2 = trackX1 + pos * trackWidth
        -- Use ImDrawFlags.RoundCornersLeft (9) to only round left corners
        local fillFlags = 9  -- ImDrawFlags.RoundCornersLeft
        ImGui.ImDrawListAddRectFilled(drawList, trackX1, trackY, fillX2, trackY + trackHeight, fillColor, trackRounding, fillFlags)
    end

    -- ====================================================================
    -- Draw: Handle (rectangle by default, circle as option)
    -- ====================================================================
    drawHandle(drawList, handleX, handleCenterY, handleStyle, state,
        handleW, handleHoverW, handleR, handleHoverR, trackHeight,
        handleBodyColor, handleBodyHoverColor, handleBodyActiveColor, handleBorderColor, handleDotColor, handleRounding)

    -- ====================================================================
    -- Draw: Default position indicator (INSIDE track, AFTER handle for z-order)
    -- ====================================================================
    if showDefaultLine and (max - min) > 0 then
        local distFromDefault = math.abs(value - default) / (max - min)
        local indicatorFrac = state.defaultIndicatorAnim:fraction()
        local indicatorLen
        if distFromDefault < 0.005 then
            indicatorLen = Animation.Lerp(indicatorLong, indicatorShort, indicatorFrac)
        else
            indicatorLen = Animation.Lerp(indicatorShort, indicatorLong, indicatorFrac)
        end
        drawDefaultIndicator(drawList, trackX1, trackX2, trackY, trackHeight, trackWidth,
            value, default, min, max, indicatorLen, indicatorColor, indicatorThickness)
    end

    -- ====================================================================
    -- Draw: Rich tooltip (on hover or drag — anchored to cursor, bounds-aware)
    -- Auto-generated from component state, overridable via opts.tooltipLines
    -- ====================================================================
    if showTooltip and (state.hovered or state.dragging) then
        local lines = {}

        -- Use custom tooltip lines if provided, otherwise auto-generate
        if opts.tooltipLines and type(opts.tooltipLines) == "function" then
            lines = opts.tooltipLines({
                label = valueLabel,
                value = value,
                default = default,
                format = format,
                description = valueDescription,
                tooltip = tooltip,
                step = step,
                range = max - min,
                min = min,
                max = max,
            }) or {}
        else
            -- Auto-generate tooltip content
            if valueLabel and valueLabel ~= "" then
                table.insert(lines, { text = valueLabel, color = "primary" })
            end
            table.insert(lines, { text = "Current: " .. string.format(format, value), color = "text" })
            if default ~= value then
                table.insert(lines, { text = "Default: " .. string.format(format, default), color = "muted" })
            end
            if valueDescription and valueDescription ~= "" then
                table.insert(lines, { text = valueDescription, color = "text_dim" })
            end
            if tooltip and tooltip ~= "" then
                table.insert(lines, { text = tooltip, color = "text_dim" })
            end

            -- Separator + dynamic modifier hints with actual values
            table.insert(lines, { text = "---", color = "separator" })
            table.insert(lines, {
                text = string.format("Step: %s", string.format(format, step)),
                color = "text_dim",
            })
            -- Show drag modifier hints (use descriptive names when values are too small to be meaningful)
            local fineStep = step * modifierShiftMult
            local preciseStep = step * modifierCtrlMult
            local coarseStep = step * modifierAltMult
            local function formatStep(val)
                if val == 0 then return "fine" end
                if val < 0.001 then return "fine" end
                if val < 0.01 then return "precision" end
                return string.format(format, val)
            end
            table.insert(lines, {
                text = string.format("Drag: Shift=%s  Ctrl=%s  Alt=%s",
                    formatStep(fineStep),
                    formatStep(preciseStep),
                    formatStep(coarseStep)),
                color = "text_dim",
            })
            -- Show click modifiers
            table.insert(lines, {
                text = "Click: Shift=snap  Ctrl=input  Alt=default",
                color = "text_dim",
            })
        end

        local tooltipColorMap = {
            primary = tooltipLabelColor,
            text = tooltipValueColor,
            muted = tooltipDefaultColor,
            text_dim = tooltipDescColor,
            separator = tooltipBorderColor,
        }
        local tt = getTooltip()
        if tt then
            tt.render("slider_" .. label, lines, tooltipColorMap, { anchor = tooltipAnchor })
        else
            drawSliderTooltip(drawList, lines, tooltipBgColor, tooltipBorderColor, tooltipColorMap, tooltipAnchor)
        end
    end

    -- ====================================================================
    -- Draw: Value display (configurable: auto/inside/button/none)
    -- ====================================================================
    local valueText = string.format(format, value)
    local valTextW = select(1, ImGui.CalcTextSize(valueText))
    local valTextH = select(2, ImGui.CalcTextSize(valueText))

    local function resolveValueDisplay()
        if valueDisplay == "none" then return "none" end
        if valueDisplay == "button" and showButtons then return "button" end
        if valueDisplay == "inside" or valueDisplay == "auto" then return "inside" end
        return "none"
    end

    local displayMode = resolveValueDisplay()

    if displayMode == "inside" then
        -- Dynamic positioning: prefer the side with more space between handle and default tick
        local handleHW = (handleStyle == "circle") and (state.hovered and handleHoverR or handleR) or (state.hovered and handleHoverW or handleW)
        local defaultX = showDefaultLine and (trackX1 + valueToPos(default, min, max) * trackWidth) or nil
        local tickWidth = 3  -- Width occupied by the default tick line

        -- Left space: from track left to handle minus handle half-width
        local handleLeft = handleX - handleHW
        local handleRight = handleX + handleHW
        local leftSpace = handleLeft - trackX1
        local rightSpace = trackX2 - handleRight

        local valTextY = trackY + (trackHeight - valTextH) / 2
        local valTextX
        local gap = 4  -- Gap between handle/tick and text

        -- Helper: check if text would overlap the default tick
        local function textOverlapsTick(textX, textEndX)
            if not defaultX then return false end
            return textX < defaultX + tickWidth and textEndX > defaultX
        end

        -- Helper: calculate effective space on a side accounting for tick position
        local function effectiveSpace(spaceStart, spaceEnd, tickPos)
            if not tickPos or tickPos < spaceStart or tickPos > spaceEnd then
                return spaceEnd - spaceStart
            end
            -- Tick is between spaceStart and spaceEnd, split into two zones
            local zone1 = tickPos - spaceStart - tickWidth
            local zone2 = spaceEnd - tickPos
            return math.max(zone1, zone2)
        end

        -- Calculate effective spaces accounting for tick position
        local effLeftSpace = effectiveSpace(trackX1, handleLeft, defaultX and defaultX < handleX and defaultX or nil)
        local effRightSpace = effectiveSpace(handleRight, trackX2, defaultX and defaultX > handleX and defaultX or nil)

        -- Determine best side
        if effLeftSpace > effRightSpace and effLeftSpace > valTextW + gap then
            -- Left side has more effective space
            valTextX = handleLeft - gap - valTextW
            -- Only shift if text would actually overlap the tick
            if textOverlapsTick(valTextX, valTextX + valTextW) then
                valTextX = defaultX - tickWidth - gap - valTextW
            end
            if valTextX < trackX1 + 2 then valTextX = trackX1 + 2 end
        elseif effRightSpace > valTextW + gap then
            -- Right side has enough space
            valTextX = handleRight + gap
            -- Only shift if text would actually overlap the tick
            if textOverlapsTick(valTextX, valTextX + valTextW) then
                valTextX = defaultX + tickWidth + gap
            end
            if valTextX + valTextW > trackX2 - 2 then valTextX = trackX2 - valTextW - 2 end
        elseif effLeftSpace > valTextW + gap then
            -- Fallback to left if it fits
            valTextX = handleLeft - gap - valTextW
            if valTextX < trackX1 + 2 then valTextX = trackX1 + 2 end
        else
            -- Text doesn't fit on either side, hide it
            valTextX = nil
        end

        if valTextX and valTextW < trackWidth * 0.45 then
            drawText(drawList, valTextX, valTextY, valueTextColor, valueText)
        end

    elseif displayMode == "button" then
        -- Show value between minus button and track
        if showButtons then
            local valTextY = cursorY + (compHeight - valTextH) / 2
            local valTextX = trackX1 - valTextW - 4
            if valTextX < btnAreaW + 2 then valTextX = btnAreaW + 2 end
            drawText(drawList, valTextX, valTextY, valueTextColor, valueText)
        end
    end

    -- ====================================================================
    -- Tooltip (only when hovering track, not buttons — buttons have their own)
    -- ====================================================================
    if tooltip and tooltip ~= "" and not state.dragging and state.hovered then
        Utils.Tooltip(tooltip)
    end

    -- ====================================================================
    -- Callback
    -- ====================================================================
    if changed and onChange and type(onChange) == "function" then
        pcall(onChange, newValue)
    end

    return newValue, changed
end

return M
