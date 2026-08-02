# CET ImGui — Text & Display

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## Basic Text

```lua
ImGui.Text("Hello World")
ImGui.Text("Hello %s", "World")  -- formatted
```

## TextColored

```lua
ImGui.TextColored(1, 0, 0, 1, "Red text")
```

## TextDisabled

```lua
ImGui.TextDisabled("Greyed out text")
```

## TextWrapped

```lua
ImGui.TextWrapped("This text will wrap to the next line if it's too long for the window")
```

## SeparatorText

```lua
ImGui.SeparatorText("Section Header")
```

## BulletText

```lua
ImGui.BulletText("Bullet item")
```

## Item Visibility & State

```lua
visible = ImGui.IsItemVisible()      -- visible in clipping rect
active = ImGui.IsItemActive()        -- being interacted with (dragged/clicked)
hovered = ImGui.IsItemHovered()      -- mouse hovering
clicked = ImGui.IsItemClicked()      -- clicked
focused = ImGui.IsItemFocused()      -- has keyboard focus
