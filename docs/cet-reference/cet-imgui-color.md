# CET ImGui — Color Widgets

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## ColorEdit3 (RGB)

```lua
col, used = ImGui.ColorEdit3("Label", col)
col, used = ImGui.ColorEdit3("Label", col, ImGuiColorEditFlags.NoTooltip)
```

## ColorEdit4 (RGBA)

```lua
col, used = ImGui.ColorEdit4("Label", col)
col, used = ImGui.ColorEdit4("Label", col, ImGuiColorEditFlags.NoTooltip)
```

## ColorPicker3 (RGB)

```lua
col, used = ImGui.ColorPicker3("Label", col)
col, used = ImGui.ColorPicker3("Label", col, ImGuiColorEditFlags.NoTooltip)
```

## ColorPicker4 (RGBA)

```lua
col, used = ImGui.ColorPicker4("Label", col)
col, used = ImGui.ColorPicker4("Label", col, ImGuiColorEditFlags.NoTooltip)
```

## ColorButton

```lua
pressed = ImGui.ColorButton("Desc ID", { 1, 0, 0, 1 })
pressed = ImGui.ColorButton("Desc ID", { 1, 0, 0, 1 }, ImGuiColorEditFlags.None)
pressed = ImGui.ColorButton("Desc ID", { 1, 0, 0, 1 }, ImGuiColorEditFlags.None, 100, 100)
```

## SetColorEditOptions

```lua
ImGui.SetColorEditOptions(ImGuiColorEditFlags.NoTooltip)
```
