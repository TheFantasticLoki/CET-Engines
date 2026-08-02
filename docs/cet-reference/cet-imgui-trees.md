# CET ImGui — Trees & Collapsing Headers

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## TreeNode

```lua
open = ImGui.TreeNode("Label")
open = ImGui.TreeNode("Label", "Some Text")
```

## TreeNodeEx

```lua
open = ImGui.TreeNodeEx("Label")
open = ImGui.TreeNodeEx("Label", ImGuiTreeNodeFlags.Selected)
open = ImGui.TreeNodeEx("Label", ImGuiTreeNodeFlags.Selected, "Some Text")
```

## TreePush / TreePop

```lua
ImGui.TreePush("String ID")
-- ... nested content ...
ImGui.TreePop()
```

## CollapsingHeader

```lua
notCollapsed = ImGui.CollapsingHeader("Label")
notCollapsed = ImGui.CollapsingHeader("Label", ImGuiTreeNodeFlags.Selected)
open, notCollapsed = ImGui.CollapsingHeader("Label", open)
open, notCollapsed = ImGui.CollapsingHeader("Label", open, ImGuiTreeNodeFlags.Selected)
```

## SetNextItemOpen

```lua
ImGui.SetNextItemOpen(true)
ImGui.SetNextItemOpen(true, ImGuiCond.Always)
```

## GetTreeNodeToLabelSpacing

```lua
spacing = ImGui.GetTreeNodeToLabelSpacing()
```

## IsItemToggledOpen

```lua
toggled_open = ImGui.IsItemToggledOpen()
```
