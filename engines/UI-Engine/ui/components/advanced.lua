--[[
    Advanced — UI-Engine Component Library

    Advanced widgets for complex interactions.
    Includes AdvancedSlider, ThemeDropdown, ComboBox.

    AdvancedSlider is a fully DrawList-rendered slider with:
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

local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")
local Animation = require("ui/animation")
local ColorEngine = require("ui/color_engine")

-- Lazy-loaded Theme and LogEngine references
local _theme = nil
local _log = nil

-- Diagnostic flag (one-time DrawList method dump)
local _drawListDiagDone = false

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
-- Modifier Key Tracking (CET uses registerInputEvent, not ImGui.IsKeyDown)
-- MUST register at module load time, not lazily
-- ============================================================================

local _keysDown = {}    -- Tracks currently held keys: { [vk_code] = true }

-- Windows Virtual Key codes for modifier keys
local VK_LSHIFT = 0xA0
local VK_RSHIFT = 0xA1
local VK_LCONTROL = 0xA2
local VK_RCONTROL = 0xA3
local VK_LALT = 0xA4
local VK_RALT = 0xA5

--- Register input events for all modifier keys at module load time
--- This must happen at root level, not inside function calls
local function registerModifierKeyTracking()
    local modifierKeys = {
        { slug = "advslider_shift_l",  vk = VK_LSHIFT },
        { slug = "advslider_shift_r",  vk = VK_RSHIFT },
        { slug = "advslider_ctrl_l",   vk = VK_LCONTROL },
        { slug = "advslider_ctrl_r",   vk = VK_RCONTROL },
        { slug = "advslider_alt_l",    vk = VK_LALT },
        { slug = "advslider_alt_r",    vk = VK_RALT },
    }
    for _, info in ipairs(modifierKeys) do
        registerInputEvent(info.slug, function(action)
            if action == "press" then
                _keysDown[info.vk] = true
            elseif action == "release" then
                _keysDown[info.vk] = nil
            end
        end)
    end
end

-- Register immediately at module load time
local ok, err = pcall(registerModifierKeyTracking)
if not ok then
    print("[AdvSlider] Key tracking registration failed: " .. tostring(err))
end

--- Check if a modifier key is currently held
local function isShiftDown()
    return _keysDown[VK_LSHIFT] or _keysDown[VK_RSHIFT] or false
end

local function isCtrlDown()
    return _keysDown[VK_LCONTROL] or _keysDown[VK_RCONTROL] or false
end

local function isAltDown()
    return _keysDown[VK_LALT] or _keysDown[VK_RALT] or false
end

-- ============================================================================
-- Logging Helper
-- ============================================================================

--- Log a message with component prefix
-- @param level Log level ("debug", "info", "warn", "error")
-- @param msg Message string
local function logMsg(level, msg)
    if _log and _log[level] then
        _log[level]("[AdvSlider] " .. msg)
    end
end

--- Log a formatted message
-- @param level Log level
-- @param fmt Format string
-- @param ... Format args
local function logFmt(level, fmt, ...)
    if _log and _log[level] then
        _log[level]("[AdvSlider] " .. string.format(fmt, ...))
    end
end

-- ============================================================================
-- Initialization
-- ============================================================================

--- Initialize advanced module with dependencies
-- @param theme Theme module reference (optional)
-- @param log Logger instance (Log-Engine or UI-Engine modules/logger) (optional)
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

-- Track per-slider state by label ID
local _states = {}

--- Get or create state for a slider instance
-- @param id Unique slider ID
-- @return table State table
local function getState(id)
    if not _states[id] then
        _states[id] = {
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
    end
    return _states[id]
end

-- ============================================================================
-- Color Helpers
-- ============================================================================

--- Get theme-aware color for a role
-- @param role Token role name
-- @return table Color {r, g, b}
local function getRoleColor(role)
    local color = Tokens.color4n(role)
    if color then
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
-- @param r Red (0..1)
-- @param g Green (0..1)
-- @param b Blue (0..1)
-- @param a Alpha (0..1)
-- @return number Packed ImGui color
local function packColor(r, g, b, a)
    r = math.floor(r * 255 + 0.5)
    g = math.floor(g * 255 + 0.5)
    b = math.floor(b * 255 + 0.5)
    a = math.floor((a or 1) * 255 + 0.5)
    -- ImGui IM_COL32: ABGR byte order
    return a * 16777216 + b * 65536 + g * 256 + r
end

--- Pack a role color with alpha
-- @param role Token role name
-- @param a Alpha (0..1)
-- @return number Packed ImGui color
local function roleColor(role, a)
    local c = getRoleColor(role)
    return packColor(c.r, c.g, c.b, a or 1)
end

-- ============================================================================
-- DrawList Helpers (CET static-function style)
-- ============================================================================

--- Draw a rounded rectangle
-- @param drawList DrawList userdata
-- @param x1 Top-left X
-- @param y1 Top-left Y
-- @param x2 Bottom-right X
-- @param y2 Bottom-right Y
-- @param color Packed color
-- @param rounding Corner rounding
-- @param thickness Border thickness (0 = filled)
local function drawRoundRect(drawList, x1, y1, x2, y2, color, rounding, thickness)
    if not drawList then return end
    if thickness and thickness > 0 then
        ImGui.ImDrawListAddRect(drawList, x1, y1, x2, y2, color, rounding, 0, thickness)
    else
        ImGui.ImDrawListAddRectFilled(drawList, x1, y1, x2, y2, color, rounding, 0)
    end
end

--- Draw a circle
-- @param drawList DrawList userdata
-- @param cx Center X
-- @param cy Center Y
-- @param radius Radius
-- @param color Packed color
-- @param thickness Border thickness (0 = filled)
local function drawCircle(drawList, cx, cy, radius, color, thickness)
    if not drawList then return end
    if thickness and thickness > 0 then
        ImGui.ImDrawListAddCircle(drawList, cx, cy, radius, color, 0, thickness)
    else
        ImGui.ImDrawListAddCircleFilled(drawList, cx, cy, radius, color, 0)
    end
end

--- Draw a line
-- @param drawList DrawList userdata
-- @param x1 Start X
-- @param y1 Start Y
-- @param x2 End X
-- @param y2 End Y
-- @param color Packed color
-- @param thickness Line thickness
local function drawLine(drawList, x1, y1, x2, y2, color, thickness)
    if not drawList then return end
    ImGui.ImDrawListAddLine(drawList, x1, y1, x2, y2, color, thickness)
end

--- Draw text
-- @param drawList DrawList userdata
-- @param x Position X
-- @param y Position Y
-- @param color Packed color
-- @param text Text string
local function drawText(drawList, x, y, color, text)
    if not drawList then return end
    ImGui.ImDrawListAddText(drawList, x, y, color, text)
end

--- Safe draw call wrapper (calls drawList method with args)
-- @param drawList DrawList userdata
-- @param method Method name (string)
-- @param ... Method arguments
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
-- @param value Current value
-- @param min Range minimum
-- @param max Range maximum
-- @return number Position (0..1)
local function valueToPos(value, min, max)
    if max == min then return 0 end
    return Animation.Clamp((value - min) / (max - min), 0, 1)
end

--- Convert track position to value
-- @param pos Position (0..1)
-- @param min Range minimum
-- @param max Range maximum
-- @return number Value
local function posToValue(pos, min, max)
    return min + pos * (max - min)
end

-- ============================================================================
-- AdvancedSlider Component
-- ============================================================================

--- Advanced DrawList-rendered slider with modifier keys, animations, and default indicator
-- Supports two call styles:
--   AdvancedSlider(label, value, options)  — new style (matches other components)
--   AdvancedSlider(spec)                   — legacy style {label, value, min, max, ...}
--
-- @param label_or_spec Unique label/ID string OR spec table (legacy)
-- @param value Current value (nil if using spec table)
-- @param options Optional table:
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
-- @return number newValue, boolean changed
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

    -- Behavior options
    local modifierShiftMult = opts.modifierShiftMult or 0.1
    local modifierCtrlMult = opts.modifierCtrlMult or 0.01
    local modifierAltMult = opts.modifierAltMult or 10
    local buttonShiftMult = opts.buttonShiftMult or 10
    local buttonCtrlMult = opts.buttonCtrlMult or 0.5
    local snapDistance = opts.snapDistance or ((max - min) * 0.02)
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
        if not _drawListDiagDone then
            _drawListDiagDone = true
            print("[AdvSlider] DrawList available (type=" .. type(dl) .. ")")
        end
    else
        print("[AdvSlider] WARN: GetWindowDrawList() nil — fallback")
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

    local cursorX, cursorY = Utils.SafeImGuiCall(ImGui.GetCursorScreenPos)
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
                newValue = default
                changed = true
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
        local mHov = ImGui.IsItemHovered()
        local mAct = ImGui.IsItemActive()
        local mCol = mAct and btnActiveColor or (mHov and btnHoverColor or btnNormalColor)
        drawRoundRect(drawList, minusX, buttonY, minusX + btnW, buttonY + btnH, mCol, btnRounding, 0)
        local sCol = mHov and btnSymbolHoverColor or btnSymbolColor
        local mcx = minusX + btnW / 2
        local mcy = buttonY + btnH / 2
        drawLine(drawList, mcx - 4, mcy, mcx + 4, mcy, sCol, 1.5)
    end

    -- ====================================================================
    -- Draw: Track (InvisibleButton for interaction)
    -- ====================================================================
    ImGui.SetCursorScreenPos(trackX1, cursorY)
    local trackClicked = ImGui.InvisibleButton("##adv-track-" .. label, trackWidth, compHeight)
    state.hovered = ImGui.IsItemHovered()
    state.active = ImGui.IsItemActive()

    -- Live drag: update every frame while mouse is down over track
    if state.active then
        state.dragging = true
        state.dragStartMouseX = state.dragStartMouseX or select(1, ImGui.GetMousePos())
        state.dragTrackWidth = state.dragTrackWidth or trackWidth
        state.dragStartValue = state.dragStartValue or value
    elseif state.dragging then
        state.dragging = false
    end

    -- Click-to-position
    if trackClicked then
        local mouseX = select(1, ImGui.GetMousePos())
        local clickPos = Animation.Clamp((mouseX - trackX1) / trackWidth, 0, 1)
        local clickValue = posToValue(clickPos, min, max)

        -- Diagnostic tracing for first-click snap issue
        if not state._clicksLogged then
            state._clicksLogged = 0
        end
        state._clicksLogged = (state._clicksLogged or 0) + 1
        if state._clicksLogged <= 3 then
            print(string.format("[AdvSlider] CLICK #%d id=%s mouseX=%.1f trackX1=%.1f trackX2=%.1f trackWidth=%.1f clickPos=%.3f clickValue=%.2f value=%.2f default=%.2f snapDist=%.2f",
                state._clicksLogged, id, mouseX, trackX1, trackX2, trackWidth, clickPos, clickValue, value, default, snapDistance))
        end

        if math.abs(clickValue - default) < snapDistance then clickValue = default end
        newValue = clickValue
        changed = true
        -- Start drag — base is the CLICKED value, not the original
        state.dragging = true
        state.dragStartMouseX = mouseX
        state.dragTrackWidth = trackWidth
        state.dragStartValue = clickValue
        state.handleAnim:start()
    end

    -- Live drag update (every frame while dragging)
    if state.dragging and state.active then
        local mouseX = select(1, ImGui.GetMousePos())
        local deltaPixels = mouseX - state.dragStartMouseX
        local deltaValue = (deltaPixels / state.dragTrackWidth) * (max - min)
        if isShiftDown() then
            deltaValue = deltaValue * modifierShiftMult
        elseif isCtrlDown() then
            deltaValue = deltaValue * modifierCtrlMult
        elseif isAltDown() then
            deltaValue = deltaValue * modifierAltMult
        end
        local dragValue = Animation.Clamp(state.dragStartValue + deltaValue, min, max)
        if dragValue ~= value then
            newValue = dragValue
            changed = true
            -- Log first few drag updates
            if (state._dragLogs or 0) < 3 then
                state._dragLogs = (state._dragLogs or 0) + 1
                print(string.format("[AdvSlider] DRAG #%d id=%s deltaPixels=%.1f deltaValue=%.4f dragStartValue=%.2f dragValue=%.2f",
                    state._dragLogs, id, deltaPixels, deltaValue, state.dragStartValue, dragValue))
            end
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
                newValue = default
                changed = true
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
        local pHov = ImGui.IsItemHovered()
        local pAct = ImGui.IsItemActive()
        local pCol = pAct and btnActiveColor or (pHov and btnHoverColor or btnNormalColor)
        drawRoundRect(drawList, plusX, buttonY, plusX + btnW, buttonY + btnH, pCol, btnRounding, 0)
        local psCol = pHov and btnSymbolHoverColor or btnSymbolColor
        local pcx = plusX + btnW / 2
        local pcy = buttonY + btnH / 2
        drawLine(drawList, pcx - 4, pcy, pcx + 4, pcy, psCol, 1.5)
        drawLine(drawList, pcx, pcy - 4, pcx, pcy + 4, psCol, 1.5)
    end

    -- ====================================================================
    -- Draw: Track background (visible pill)
    -- ====================================================================
    drawRoundRect(drawList, trackX1, trackY, trackX2, trackY + trackHeight, trackBgColor, trackRounding, 0)
    drawRoundRect(drawList, trackX1, trackY, trackX2, trackY + trackHeight, trackBorderColor, trackRounding, 1)

    -- ====================================================================
    -- Draw: Position indicator ticks (configurable major/minor above track)
    -- ====================================================================
    if showTicks and majorTicks > 0 then
        local totalSegments = majorTicks
        local majorSpacing = trackWidth / totalSegments

        -- Draw minor ticks first (behind majors)
        if minorTicks > 0 then
            local minorSpacing = majorSpacing / (minorTicks + 1)
            for maj = 0, totalSegments do
                for mino = 1, minorTicks do
                    local tx = trackX1 + maj * majorSpacing + mino * minorSpacing
                    if tx > trackX1 and tx < trackX2 then
                        drawLine(drawList, tx, trackY - 1, tx, trackY - 1 - minorTickHeight, tickColorVal, minorTickThickness)
                    end
                end
            end
        end

        -- Draw major ticks (skip edge ticks, enlarge center)
        for i = 0, totalSegments do
            local tx = trackX1 + i * majorSpacing
            if tx > trackX1 and tx < trackX2 then  -- Skip edge ticks
                local isCenter = (i == math.floor(totalSegments / 2))
                local tickH = isCenter and centerTickHeight or majorTickHeight
                local tickCol = isCenter and centerTickColorVal or majorTickColorVal
                local tickThick = isCenter and centerTickThickness or majorTickThickness
                drawLine(drawList, tx, trackY - 1, tx, trackY - 1 - tickH, tickCol, tickThick)
            end
        end
    end

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
    local handleBodyCol = state.dragging and handleBodyActiveColor or (state.hovered and handleBodyHoverColor or handleBodyColor)

    if handleStyle == "circle" then
        -- Circle handle
        local hr = state.hovered and handleHoverR or handleR
        if state.dragging then
            drawCircle(drawList, handleX, handleCenterY, hr + 3, roleColor("primary", 0.2), 0)
        end
        drawCircle(drawList, handleX, handleCenterY, hr, handleBodyCol, 0)
        drawCircle(drawList, handleX, handleCenterY, hr, handleBorderColor, 1.5)
        drawCircle(drawList, handleX, handleCenterY, 2, handleDotColor, 0)
    else
        -- Rectangle handle (default)
        local hw = state.hovered and handleHoverW or handleW
        local hh = trackHeight + 6
        local hhalf = hh / 2
        if state.dragging then
            drawRoundRect(drawList, handleX - hw/2 - 2, handleCenterY - hhalf - 2, handleX + hw/2 + 2, handleCenterY + hhalf + 2, roleColor("primary", 0.2), handleRounding, 0)
        end
        drawRoundRect(drawList, handleX - hw/2, handleCenterY - hhalf, handleX + hw/2, handleCenterY + hhalf, handleBodyCol, handleRounding, 0)
        drawRoundRect(drawList, handleX - hw/2, handleCenterY - hhalf, handleX + hw/2, handleCenterY + hhalf, handleBorderColor, handleRounding, 1)
    end

    -- ====================================================================
    -- Draw: Default position indicator (INSIDE track, AFTER handle for z-order)
    -- ====================================================================
    if showDefaultLine and (max - min) > 0 then
        local defaultPos = valueToPos(default, min, max)
        local defaultX = trackX1 + defaultPos * trackWidth
        local distFromDefault = math.abs(value - default) / (max - min)
        local indicatorFrac = state.defaultIndicatorAnim:fraction()

        -- Dynamic length: short when at default, long when away
        local indicatorLen
        if distFromDefault < 0.005 then
            indicatorLen = Animation.Lerp(indicatorLong, indicatorShort, indicatorFrac)
        else
            indicatorLen = Animation.Lerp(indicatorShort, indicatorLong, indicatorFrac)
        end

        local indCenterY = trackY + trackHeight / 2
        drawLine(drawList, defaultX, indCenterY - indicatorLen / 2, defaultX, indCenterY + indicatorLen / 2, indicatorColor, indicatorThickness)
    end

    -- ====================================================================
    -- Draw: Rich tooltip (on hover or drag — anchored to cursor, bounds-aware)
    -- Uses foreground draw list to render over everything
    -- ====================================================================
    if showTooltip and (state.hovered or state.dragging) then
        local lines = {}
        -- Label
        if valueLabel and valueLabel ~= "" then
            table.insert(lines, { text = valueLabel, color = "primary" })
        end
        -- Current value
        table.insert(lines, { text = "Current: " .. string.format(format, value), color = "text" })
        -- Default value (if different from current)
        if default ~= value then
            table.insert(lines, { text = "Default: " .. string.format(format, default), color = "muted" })
        end
        -- Description
        if valueDescription and valueDescription ~= "" then
            table.insert(lines, { text = valueDescription, color = "text_dim" })
        end
        -- Additional tooltip
        if tooltip and tooltip ~= "" then
            table.insert(lines, { text = tooltip, color = "text_dim" })
        end

        -- Calculate tooltip dimensions
        local lineHeight = select(2, ImGui.CalcTextSize("X"))
        local lineSpacing = 3
        local padding = 6
        local tooltipH = #lines * (lineHeight + lineSpacing) - lineSpacing + padding * 2
        local maxW = 0
        for _, entry in ipairs(lines) do
            local w = select(1, ImGui.CalcTextSize(entry.text))
            if w > maxW then maxW = w end
        end
        local tooltipW = maxW + padding * 2

        -- Position at cursor with offset
        local mouseX, mouseY = ImGui.GetMousePos()
        local tooltipX = mouseX + 12
        local tooltipY = mouseY - tooltipH - 4

        -- Clamp to window bounds
        local winX, winY = ImGui.GetWindowPos()
        local winW, winH = ImGui.GetWindowSize()
        local screenMaxX = winX + winW
        local screenMaxY = winY + winH

        if tooltipX + tooltipW > screenMaxX then
            tooltipX = mouseX - tooltipW - 12  -- Flip to left side
        end
        if tooltipY < winY then
            tooltipY = mouseY + 16  -- Below cursor if no room above
        end
        if tooltipX < winX then tooltipX = winX + 2 end
        if tooltipY + tooltipH > screenMaxY then
            tooltipY = screenMaxY - tooltipH - 2
        end

        -- Use foreground draw list to render tooltip over everything
        local fgDrawList = ImGui.GetForegroundDrawList()
        if fgDrawList then
            -- Draw background and border on foreground layer
            ImGui.ImDrawListAddRectFilled(fgDrawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, tooltipBgColor, 4, 0)
            ImGui.ImDrawListAddRect(fgDrawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, tooltipBorderColor, 4, 0, 1)

            -- Draw each line on foreground layer
            local ty = tooltipY + padding
            local colorMap = {
                primary = tooltipLabelColor,
                text = tooltipValueColor,
                muted = tooltipDefaultColor,
                text_dim = tooltipDescColor,
            }
            for _, entry in ipairs(lines) do
                local lineColor = colorMap[entry.color] or tooltipValueColor
                ImGui.ImDrawListAddText(fgDrawList, tooltipX + padding, ty, lineColor, entry.text)
                ty = ty + lineHeight + lineSpacing
            end
        else
            -- Fallback: draw on window draw list
            drawRoundRect(drawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, tooltipBgColor, 4, 0)
            drawRoundRect(drawList, tooltipX, tooltipY, tooltipX + tooltipW, tooltipY + tooltipH, tooltipBorderColor, 4, 1)
            local ty = tooltipY + padding
            local colorMap = {
                primary = tooltipLabelColor,
                text = tooltipValueColor,
                muted = tooltipDefaultColor,
                text_dim = tooltipDescColor,
            }
            for _, entry in ipairs(lines) do
                local lineColor = colorMap[entry.color] or tooltipValueColor
                drawText(drawList, tooltipX + padding, ty, lineColor, entry.text)
                ty = ty + lineHeight + lineSpacing
            end
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
    -- Tooltip
    -- ====================================================================
    if tooltip and tooltip ~= "" and not state.dragging then
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

-- ============================================================================
-- Theme Dropdown
-- ============================================================================

--- Theme selector dropdown
-- @param label Label text
-- @param currentTheme Current theme name
-- @param themes Array of theme name strings
-- @param onChange Callback function(newTheme)
-- @return string newTheme, boolean changed
function M.ThemeDropdown(label, currentTheme, themes, onChange)
    label = label or ""
    currentTheme = currentTheme or "Dark"
    themes = themes or {}

    local changed = false
    local newTheme = currentTheme

    if ImGui.BeginCombo(label, currentTheme) then
        for _, themeName in ipairs(themes) do
            local isSelected = (themeName == currentTheme)
            if ImGui.Selectable(themeName, isSelected) then
                newTheme = themeName
                changed = true

                if _theme and _theme.SetTheme then
                    _theme.SetTheme(themeName)
                end

                if onChange and type(onChange) == "function" then
                    onChange(themeName)
                end
            end
        end
        ImGui.EndCombo()
    end

    return newTheme, changed
end

-- ============================================================================
-- ComboBox
-- ============================================================================

--- Generic dropdown combo box
-- @param label Label text
-- @param items Array of display strings
-- @param selectedIndex Current selected index
-- @param onChange Callback function(newIndex, newLabel)
-- @return number newIndex, boolean changed
function M.ComboBox(label, items, selectedIndex, onChange)
    label = label or ""
    items = items or {}
    selectedIndex = selectedIndex or 1

    local preview = items[selectedIndex] or ""
    local changed = false
    local newIndex = selectedIndex

    if ImGui.BeginCombo(label, preview) then
        for i, item in ipairs(items) do
            local isSelected = (i == selectedIndex)
            if ImGui.Selectable(item, isSelected) then
                newIndex = i
                changed = true

                if onChange and type(onChange) == "function" then
                    onChange(i, item)
                end
            end
        end
        ImGui.EndCombo()
    end

    return newIndex, changed
end

return M
