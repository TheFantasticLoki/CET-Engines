# CET ImGui — Layout & Windows

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## Windows

```lua
-- Basic window (returns shouldDraw)
shouldDraw = ImGui.Begin("Name")
shouldDraw = ImGui.Begin("Name", ImGuiWindowFlags.NoMove)
open, shouldDraw = ImGui.Begin("Name", open)
open, shouldDraw = ImGui.Begin("Name", open, ImGuiWindowFlags.NoMove)
ImGui.End()
```

## Child Windows

```lua
-- New API (preferred)
shouldDraw = ImGui.BeginChild("Name")
shouldDraw = ImGui.BeginChild("Name", 100)
shouldDraw = ImGui.BeginChild("Name", 100, 200)
shouldDraw = ImGui.BeginChild("Name", 100, 200, ImGuiChildFlags.Border)
shouldDraw = ImGui.BeginChild("Name", 100, 200, ImGuiChildFlags.Border, ImGuiWindowFlags.NoMove)
ImGui.EndChild()

-- Deprecated but still works
shouldDraw = ImGui.BeginChild("Name", 100, 200, true)  -- border=true
```

## Layout & Spacing

```lua
ImGui.Separator()
ImGui.SameLine()                        -- same line, no offset
ImGui.SameLine(100)                     -- offset 100px from start
ImGui.SameLine(100, 5)                  -- offset 100px, spacing 5px
ImGui.NewLine()
ImGui.Spacing()
ImGui.Dummy(100, 200)                   -- empty space
ImGui.Indent()                          -- indent
ImGui.Indent(10)
ImGui.Unindent()                        -- unindent
ImGui.Unindent(-10)
```

## Groups

```lua
ImGui.BeginGroup()
-- ... elements ...
ImGui.EndGroup()
```

## Cursor Position

```lua
x, y = ImGui.GetCursorPos()
x = ImGui.GetCursorPosX()
y = ImGui.GetCursorPosY()
ImGui.SetCursorPos(10, 10)
ImGui.SetCursorPosX(10)
ImGui.SetCursorPosY(10)
x, y = ImGui.GetCursorStartPos()
x, y = ImGui.GetCursorScreenPos()
ImGui.SetCursorScreenPos(10, 10)
```

## Text Sizing

```lua
ImGui.AlignTextToFramePadding()
height = ImGui.GetTextLineHeight()
height = ImGui.GetTextLineHeightWithSpacing()
height = ImGui.GetFrameHeight()
height = ImGui.GetFrameHeightWithSpacing()
```

## Columns (Legacy — prefer Tables API)

```lua
ImGui.Columns()
ImGui.Columns(2)
ImGui.Columns(2, "MyOtherColumn")
ImGui.Columns(3, "MyColumnWithBorder", true)
ImGui.NextColumn()
width = ImGui.GetColumnWidth()
width = ImGui.GetColumnWidth(2)
ImGui.SetColumnWidth(2, 100)
offset = ImGui.GetColumnOffset()
offset = ImGui.GetColumnOffset(2)
ImGui.SetColumnOffset(2, 10)
count = ImGui.GetColumnsCount()
index = ImGui.GetColumnIndex()
```
