# CET ImGui — Sliders & Drag

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## SliderFloat

```lua
value, used = ImGui.SliderFloat("Label", value, 0.0, 100.0)
value, used = ImGui.SliderFloat("Label", value, 0.0, 100.0, "%.1f")
value, used = ImGui.SliderFloat("Label", value, 0.0, 100.0, "%.1f", ImGuiSliderFlags.Logarithmic)
```

## SliderFloat2/3/4

```lua
values, used = ImGui.SliderFloat2("Label", values, -10, 10)
values, used = ImGui.SliderFloat3("Label", values, -10, 10)
values, used = ImGui.SliderFloat4("Label", values, 0.01, -10, 10, "%.1f", ImGuiSliderFlags.Logarithmic)
```

## SliderInt

```lua
value, used = ImGui.SliderInt("Label", value, -10, 10)
value, used = ImGui.SliderInt("Label", value, -10, 10, "%d")
value, used = ImGui.SliderInt("Label", value, -10, 10, "%d", ImGuiSliderFlags.Logarithmic)
```

## SliderInt2/3/4

```lua
values, used = ImGui.SliderInt2("Label", values, -10, 10)
values, used = ImGui.SliderInt3("Label", values, -10, 10)
values, used = ImGui.SliderInt4("Label", values, -10, 10)
```

## SliderAngle

```lua
v_rad, used = ImGui.SliderAngle("Label", v_rad)
v_rad, used = ImGui.SliderAngle("Label", v_rad, -255)
v_rad, used = ImGui.SliderAngle("Label", v_rad, -255, 360)
v_rad, used = ImGui.SliderAngle("Label", v_rad, -255, 360, "%.0f deg")
v_rad, used = ImGui.SliderAngle("Label", v_rad, -255, 360, "%.0f deg", ImGuiSliderFlags.Logarithmic)
```

## DragInt

```lua
value, used = ImGui.DragInt("Label", value)
value, used = ImGui.DragInt("Label", value, 1)
value, used = ImGui.DragInt("Label", value, 1, -100)
value, used = ImGui.DragInt("Label", value, 1, -100, 100)
value, used = ImGui.DragInt("Label", value, 1, -100, 100, "%d")
```

## DragFloat

```lua
value, used = ImGui.DragFloat("Label", value)
value, used = ImGui.DragFloat("Label", value, 0.01)
value, used = ImGui.DragFloat("Label", value, 0.01, -10)
value, used = ImGui.DragFloat("Label", value, 0.01, -10, 10)
value, used = ImGui.DragFloat("Label", value, 0.01, -10, 10, "%.1f")
```

## DragFloat2/3/4

```lua
values, used = ImGui.DragFloat2("Label", values)
values, used = ImGui.DragFloat2("Label", values, 0.01)
values, used = ImGui.DragFloat2("Label", values, 0.01, -10)
values, used = ImGui.DragFloat2("Label", values, 0.01, -10, 10)
values, used = ImGui.DragFloat2("Label", values, 0.01, -10, 10, "%.1f")
values, used = ImGui.DragFloat2("Label", values, 0.01, -10, 10, "%.1f", ImGuiSliderFlags.Logarithmic)
```

## DragInt2/3/4

```lua
values, used = ImGui.DragInt2("Label", values)
values, used = ImGui.DragInt3("Label", values)
values, used = ImGui.DragInt4("Label", values)
```
