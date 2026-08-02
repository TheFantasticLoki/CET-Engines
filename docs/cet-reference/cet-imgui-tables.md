# CET ImGui — Tables

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

## BeginTable / EndTable

```lua
ImGui.BeginTable("Table1", 3)
ImGui.BeginTable("Table1", 3, ImGuiTableFlags.Resizable)
ImGui.BeginTable("Table1", 3, ImGuiTableFlags.Resizable, 200, 150)
ImGui.BeginTable("Table1", 3, ImGuiTableFlags.Resizable, 200, 150, 10)
ImGui.EndTable()
```

## TableNextRow / TableNextColumn

```lua
ImGui.TableNextRow()
ImGui.TableNextRow(ImGuiTableRowFlags.Headers)
ImGui.TableNextRow(ImGuiTableRowFlags.Headers, 25)
visible = ImGui.TableNextColumn()
visible = ImGui.TableSetColumnIndex(2)
```

## TableSetupColumn

```lua
ImGui.TableSetupColumn("Column1")
ImGui.TableSetupColumn("Column1", ImGuiTableColumnFlags.WidthFixed)
ImGui.TableSetupColumn("Column1", ImGuiTableColumnFlags.WidthFixed, 60)
```

## TableSetupScrollFreeze

```lua
ImGui.TableSetupScrollFreeze(3, 1)  -- freeze 3 cols, 1 row
```

## TableHeadersRow / TableHeader

```lua
ImGui.TableHeadersRow()
ImGui.TableHeader("Header")
```

## Table Info Queries

```lua
ImGui.TableGetSortSpecs()
cols = ImGui.TableGetColumnCount()
col_index = ImGui.TableGetColumnIndex()
row_index = ImGui.TableGetRowIndex()
col_name = ImGui.TableGetColumnName()
col_name = ImGui.TableGetColumnName(2)
col_flags = ImGui.TableGetColumnFlags()
col_flags = ImGui.TableGetColumnFlags(2)
```

## TableSetBgColor

```lua
ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, 0xF42069FF)
ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, 0xF42069FF, 2)
ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, 1, 0, 0, 1)
ImGui.TableSetBgColor(ImGuiTableBgTarget.CellBg, 1, 0, 0, 1, 2)
```

## ListBox

```lua
current_item, clicked = ImGui.ListBox("Label", current_item, { "Item 1", "Item 2", 2 })
current_item, clicked = ImGui.ListBox("Label", current_item, { "Item 1", "Item 2", 2 }, 5)
open = ImGui.BeginListBox("Label")
open = ImGui.BeginListBox("Label", 100.0, 100.0)
ImGui.EndListBox()
```
