# CET ImGui — Menus

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## BeginMenu / EndMenu

```lua
shouldDraw = ImGui.BeginMenu("Label")
shouldDraw = ImGui.BeginMenu("Label", true)  -- enabled
ImGui.EndMenu()
```

## MenuItem

```lua
activated = ImGui.MenuItem("Label")
activated = ImGui.MenuItem("Label", "ALT+F4")
selected, activated = ImGui.MenuItem("Label", "ALT+F4", selected)
selected, activated = ImGui.MenuItem("Label", "ALT+F4", selected, true)  -- enabled
```

## MainMenuBar

```lua
if ImGui.BeginMainMenuBar() then
    if ImGui.BeginMenu("File") then
        if ImGui.MenuItem("Open") then end
        if ImGui.MenuItem("Save") then end
        ImGui.EndMenu()
    end
    ImGui.EndMainMenuBar()
end
```

## MenuBar (inside a window)

```lua
if ImGui.Begin("Window") then
    if ImGui.BeginMenuBar() then
        if ImGui.BeginMenu("Options") then
            if ImGui.MenuItem("Settings") then end
            ImGui.EndMenu()
        end
        ImGui.EndMenuBar()
    end
    -- window content...
    ImGui.End()
end
```
