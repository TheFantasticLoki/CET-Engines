# CET ImGui — Main Widgets

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## Buttons

```lua
clicked = ImGui.Button("Label")
clicked = ImGui.Button("Label", 100, 50)
clicked = ImGui.SmallButton("Label")
clicked = ImGui.InvisibleButton("Label", 100, 50)
clicked = ImGui.ArrowButton("ID", ImGuiDir.Down)
```

## Checkbox

```lua
value, pressed = ImGui.Checkbox("My Checkbox", value)
```

## RadioButton

```lua
pressed = ImGui.RadioButton("Click me", pressed == true)
value, pressed = ImGui.RadioButton("Click me too", value, 2)
```

## ProgressBar

```lua
ImGui.ProgressBar(0.5)
ImGui.ProgressBar(0.5, 100, 25)
ImGui.ProgressBar(0.5, 100, 25, "Loading Failed. Sike. - 50%")
```

## Bullet

```lua
ImGui.Bullet()
```

## Value Display

```lua
ImGui.Value("Prefix", true)
ImGui.Value("Prefix", -5)
ImGui.Value("Prefix", 5)
ImGui.Value("Prefix", 5.0)
ImGui.Value("Prefix", 5.0, "%.2f")
```
