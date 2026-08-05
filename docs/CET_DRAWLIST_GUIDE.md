# CET DrawList API Guide

## Critical CET Quirk: No Bracket Indexing on Userdata

CET's LuaJIT bindings do **NOT** support bracket indexing on userdata objects. This means:

```lua
-- ❌ BROKEN in CET
drawList:AddRectFilled(...)          -- Method call syntax
drawList["AddRectFilled"](...)       -- Bracket indexing
drawList.AddRectFilled(...)          -- Dot notation

-- ✅ CORRECT in CET
ImGui.ImDrawListAddRectFilled(drawList, ...)   -- Static function pattern
```

All DrawList functions must be called as static functions on the `ImGui` table, passing the draw list as the first argument.

---

## Getting a DrawList

```lua
-- Window draw list (most common)
local drawList = ImGui.GetWindowDrawList()

-- Foreground draw list (renders above everything - use for tooltips, popups)
local fgDrawList = ImGui.GetForegroundDrawList()

-- Background draw list (renders below everything)
local bgDrawList = ImGui.GetBackgroundDrawList()
```

---

## Available DrawList Functions

### Rectangles

```lua
-- Filled rectangle (no border)
ImGui.ImDrawListAddRectFilled(drawList, x1, y1, x2, y2, color, rounding, flags)

-- Rectangle with border
ImGui.ImDrawListAddRect(drawList, x1, y1, x2, y2, color, rounding, flags, thickness)
```

### Circles

```lua
-- Filled circle
ImGui.ImDrawListAddCircleFilled(drawList, centerX, centerY, radius, color, segments)

-- Circle with border
ImGui.ImDrawListAddCircle(drawList, centerX, centerY, radius, color, segments, thickness)
```

### Lines

```lua
-- Simple line
ImGui.ImDrawListAddLine(drawList, x1, y1, x2, y2, color, thickness)
```

### Text

```lua
-- Add text at position
ImGui.ImDrawListAddText(drawList, x, y, color, text)

-- Add text with font
ImGui.ImDrawListAddText(drawList, fontPtr, fontSize, x, y, color, text)
```

---

## Color Format

Colors must be packed into a 32-bit unsigned integer using `IM_COL32` format:

```lua
-- Helper function to pack RGBA colors
local function packColor(r, g, b, a)
    r = math.floor(r * 255 + 0.5)
    g = math.floor(g * 255 + 0.5)
    b = math.floor(b * 255 + 0.5)
    a = math.floor((a or 1) * 255 + 0.5)
    -- ImGui IM_COL32: ABGR byte order
    return a * 16777216 + b * 65536 + g * 256 + r
end

-- Usage
local white = packColor(1, 1, 1, 1)     -- Opaque white
local red = packColor(1, 0, 0, 0.5)      -- Semi-transparent red
```

---

## Rounding Flags

For rounded rectangles, you can specify which corners to round:

```lua
-- Standard ImGui rounding flags (values may vary by CET version)
local IM_DRAW_FLAGS_ROUND_CORNERS_ALL = 0x0F
local IM_DRAW_FLAGS_ROUND_CORNERS_LEFT = 0x05  -- Top-left + Bottom-left
local IM_DRAW_FLAGS_ROUND_CORNERS_RIGHT = 0x0A -- Top-right + Bottom-right
local IM_DRAW_FLAGS_ROUND_CORNERS_NONE = 0x00

-- Usage
ImGui.ImDrawListAddRectFilled(drawList, x1, y1, x2, y2, color, rounding,
    IM_DRAW_FLAGS_ROUND_CORNERS_LEFT)
```

---

## Complete Example: Custom Slider

```lua
local function drawCustomSlider(value, min, max, x, y, width, height)
    local drawList = ImGui.GetWindowDrawList()
    if not drawList then return value end

    -- Colors
    local trackBg = packColor(0.2, 0.2, 0.2, 1.0)
    local fill = packColor(0.4, 0.6, 1.0, 1.0)
    local handle = packColor(1.0, 1.0, 1.0, 1.0)

    -- Calculate position
    local pos = (value - min) / (max - min)
    local handleX = x + pos * width

    -- Draw track (filled rectangle with rounding)
    ImGui.ImDrawListAddRectFilled(drawList, x, y, x + width, y + height,
        trackBg, height / 2, 0)

    -- Draw fill (only round left corners)
    if pos > 0.001 then
        ImGui.ImDrawListAddRectFilled(drawList, x, y, handleX, y + height,
            fill, height / 2, 0x05)  -- RoundCornersLeft
    end

    -- Draw handle (filled circle)
    local handleRadius = height / 2 + 2
    ImGui.ImDrawListAddCircleFilled(drawList, handleX, y + height / 2,
        handleRadius, handle, 0)

    -- Draw handle border
    ImGui.ImDrawListAddCircle(drawList, handleX, y + height / 2,
        handleRadius, packColor(0.5, 0.5, 0.5, 1.0), 0, 1)

    return value
end
```

---

## Complete Example: Rich Tooltip

```lua
local function drawTooltip(text, x, y)
    local fgDrawList = ImGui.GetForegroundDrawList()
    if not fgDrawList then return end

    -- Calculate text size
    local textW, textH = ImGui.CalcTextSize(text)
    local padding = 6
    local bgW = textW + padding * 2
    local bgH = textH + padding * 2

    -- Position tooltip
    local tooltipX = x + 12
    local tooltipY = y - bgH - 4

    -- Clamp to window bounds
    local winX, winY = ImGui.GetWindowPos()
    local winW, winH = ImGui.GetWindowSize()
    if tooltipX + bgW > winX + winW then
        tooltipX = x - bgW - 12
    end
    if tooltipY < winY then
        tooltipY = y + 16
    end

    -- Draw background
    ImGui.ImDrawListAddRectFilled(fgDrawList, tooltipX, tooltipY,
        tooltipX + bgW, tooltipY + bgH, packColor(0.1, 0.1, 0.1, 0.95), 4, 0)

    -- Draw border
    ImGui.ImDrawListAddRect(fgDrawList, tooltipX, tooltipY,
        tooltipX + bgW, tooltipY + bgH, packColor(0.4, 0.6, 1.0, 0.5), 4, 0, 1)

    -- Draw text
    ImGui.ImDrawListAddText(fgDrawList, tooltipX + padding, tooltipY + padding,
        packColor(1, 1, 1, 1), text)
end
```

---

## Common Pitfalls

1. **Don't use bracket indexing on draw lists** - Always use `ImGui.ImDrawListAddXxx(drawList, ...)`
2. **Colors must be packed** - Use `packColor()` helper, not raw RGBA values
3. **Foreground draw list for tooltips** - Use `GetForegroundDrawList()` to render above everything
4. **Rounding flags are integers** - Pass as raw numbers, not enum names
5. **Segments = 0 for circles** - Let ImGui auto-calculate segment count
