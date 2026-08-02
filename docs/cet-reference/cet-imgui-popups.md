# CET ImGui — Popups, Modals & Tooltips

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## Popup

```lua
if ImGui.Button("Pop Button", 120, 0) then
    ImGui.OpenPopup("Delete?")
end

if ImGui.BeginPopup("Delete?") then
    ImGui.Text("Are you sure?")
    if ImGui.Button("Yes") then ImGui.CloseCurrentPopup() end
    if ImGui.Button("No") then ImGui.CloseCurrentPopup() end
    ImGui.EndPopup()
end
```

## Modal Popup

```lua
if ImGui.BeginPopupModal("Delete?", true, ImGuiWindowFlags.AlwaysAutoResize) then
    ImGui.Text("This is a modal popup")
    if ImGui.Button("Close") then ImGui.CloseCurrentPopup() end
    ImGui.EndPopup()
end
```

## OpenPopup

```lua
ImGui.OpenPopup("popup_id")
```

## CloseCurrentPopup

```lua
ImGui.CloseCurrentPopup()
```

## Context Popups (right-click menus)

```lua
-- On an item
if ImGui.BeginPopupContextItem("item_context_menu") then
    ImGui.Text("Right-clicked!")
    if ImGui.MenuItem("Action 1") then end
    ImGui.EndPopup()
end

-- On the window
open = ImGui.BeginPopupContextWindow()
open = ImGui.BeginPopupContextWindow("String ID")
open = ImGui.BeginPopupContextWindow("String ID", ImGuiPopupFlags.NoOpenOverExistingPopup)

-- On void (anywhere)
open = ImGui.BeginPopupContextVoid()
open = ImGui.BeginPopupContextVoid("String ID")
open = ImGui.BeginPopupContextVoid("String ID", ImGuiPopupFlags.NoOpenOverExistingPopup)
```

## OpenPopupContextItem

```lua
open = ImGui.OpenPopupContextItem()
open = ImGui.OpenPopupContextItem("String ID")
open = ImGui.OpenPopupContextItem("String ID", ImGuiPopupFlags.NoOpenOverExistingPopup)
```

## Tooltips

```lua
ImGui.Text("Hover me")
if ImGui.IsItemHovered() then
    ImGui.BeginTooltip()
    ImGui.Text("This is a tooltip")
    ImGui.EndTooltip()
end

-- Or with SetTooltip
ImGui.SetTooltip("This is a tooltip")
```
