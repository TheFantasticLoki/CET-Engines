# CET ImGui — Input Widgets

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## InputText

```lua
text, selected = ImGui.InputText("Label", text, 100)
text, selected = ImGui.InputText("Label", text, 100, ImGuiInputTextFlags.ReadOnly)
```

## InputTextWithHint

```lua
text, selected = ImGui.InputTextWithHint("Label", "Hint", text, 100)
text, selected = ImGui.InputTextWithHint("Label", "Hint", text, 100, ImGuiInputTextFlags.ReadOnly)
```

## InputTextMultiline

```lua
text, selected = ImGui.InputTextMultiline("Label", text, 100)
text, selected = ImGui.InputTextMultiline("Label", text, 100, 200, 35)
text, selected = ImGui.InputTextMultiline("Label", text, 100, 200, 35, ImGuiInputTextFlags.ReadOnly)
```

## InputInt

```lua
value, used = ImGui.InputInt("Label", value)
value, used = ImGui.InputInt("Label", value, 1)
value, used = ImGui.InputInt("Label", value, 1, 10)
value, used = ImGui.InputInt("Label", value, 1, 10, ImGuiInputTextFlags.None)
```

## InputInt2/3/4

```lua
values, used = ImGui.InputInt2("Label", values)
values, used = ImGui.InputInt2("Label", values, ImGuiInputTextFlags.None)
values, used = ImGui.InputInt3("Label", values)
values, used = ImGui.InputInt3("Label", values, ImGuiInputTextFlags.None)
values, used = ImGui.InputInt4("Label", values)
values, used = ImGui.InputInt4("Label", values, ImGuiInputTextFlags.None)
```

## InputFloat

```lua
value, used = ImGui.InputFloat("Label", value)
value, used = ImGui.InputFloat("Label", value, 1)
value, used = ImGui.InputFloat("Label", value, 1, 10)
value, used = ImGui.InputFloat("Label", value, 1, 10, "%.1f")
value, used = ImGui.InputFloat("Label", value, 1, 10, "%.1f", ImGuiInputTextFlags.None)
```

## InputFloat2/3/4

```lua
values, used = ImGui.InputFloat2("Label", values)
values, used = ImGui.InputFloat2("Label", values, "%.1f")
values, used = ImGui.InputFloat2("Label", values, "%.1f", ImGuiInputTextFlags.None)
values, used = ImGui.InputFloat3("Label", values)
values, used = ImGui.InputFloat3("Label", values, "%.1f")
values, used = ImGui.InputFloat3("Label", values, "%.1f", ImGuiInputTextFlags.None)
values, used = ImGui.InputFloat4("Label", values)
values, used = ImGui.InputFloat4("Label", values, "%.1f")
values, used = ImGui.InputFloat4("Label", values, "%.1f", ImGuiInputTextFlags.None)
```

## Keyboard Focus

```lua
ImGui.SetKeyboardFocusHere()
ImGui.SetKeyboardFocusHere(1)  -- offset
```
