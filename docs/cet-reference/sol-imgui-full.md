# Full sol_imgui Binding Reference

Source: github.com/maximegmd/cyberenginetweaks/blob/master/src/sol_imgui/README.md

This is the complete list of ImGui functions available in CET's Lua bindings.
Functions are bound via sol2 and follow the Dear ImGui C++ API closely.

## Windows
- `ImGui.Begin(name, [open], [flags])` → shouldDraw | open, shouldDraw
- `ImGui.End()`
- `ImGui.BeginChild(id, [size_x], [size_y], [child_flags], [window_flags])` → shouldDraw
- `ImGui.EndChild()`

## Layout
- `ImGui.Separator()`
- `ImGui.SameLine([offset], [spacing])`
- `ImGui.NewLine()`
- `ImGui.Spacing()`
- `ImGui.Dummy(w, h)`
- `ImGui.Indent([w])`
- `ImGui.Unindent([w])`
- `ImGui.BeginGroup()`
- `ImGui.EndGroup()`
- `ImGui.AlignTextToFramePadding()`

## Cursor
- `ImGui.GetCursorPos()` → x, y
- `ImGui.GetCursorPosX()` → x
- `ImGui.GetCursorPosY()` → y
- `ImGui.SetCursorPos(x, y)`
- `ImGui.SetCursorPosX(x)`
- `ImGui.SetCursorPosY(y)`
- `ImGui.GetCursorStartPos()` → x, y
- `ImGui.GetCursorScreenPos()` → x, y
- `ImGui.SetCursorScreenPos(x, y)`

## Text Sizing
- `ImGui.GetTextLineHeight()` → height
- `ImGui.GetTextLineHeightWithSpacing()` → height
- `ImGui.GetFrameHeight()` → height
- `ImGui.GetFrameHeightWithSpacing()` → height

## Text
- `ImGui.Text(str)`
- `ImGui.TextColored(r, g, b, a, str)`
- `ImGui.TextDisabled(str)`
- `ImGui.TextWrapped(str)`
- `ImGui.SeparatorText(str)`
- `ImGui.BulletText(str)`
- `ImGui.Value(prefix, val [, fmt])`

## Buttons
- `ImGui.Button(label [, w, h])` → clicked
- `ImGui.SmallButton(label)` → clicked
- `ImGui.InvisibleButton(id, w, h)` → clicked
- `ImGui.ArrowButton(id, dir)` → clicked

## Inputs
- `ImGui.InputText(label, text, buf_size [, flags])` → text, changed
- `ImGui.InputTextWithHint(label, hint, text, buf_size [, flags])` → text, changed
- `ImGui.InputTextMultiline(label, text, buf_size [, w, h, flags])` → text, changed
- `ImGui.InputInt(label, val [, step, step_fast, flags])` → val, changed
- `ImGui.InputInt2(label, vals [, flags])` → vals, changed
- `ImGui.InputInt3(label, vals [, flags])` → vals, changed
- `ImGui.InputInt4(label, vals [, flags])` → vals, changed
- `ImGui.InputFloat(label, val [, step, step_fast, format, flags])` → val, changed
- `ImGui.InputFloat2(label, vals [, format, flags])` → vals, changed
- `ImGui.InputFloat3(label, vals [, format, flags])` → vals, changed
- `ImGui.InputFloat4(label, vals [, format, flags])` → vals, changed
- `ImGui.SetKeyboardFocusHere([offset])`

## Sliders
- `ImGui.SliderFloat(label, val, min, max [, format, flags])` → val, used
- `ImGui.SliderFloat2(label, vals, min, max [, format, flags])` → vals, used
- `ImGui.SliderFloat3(label, vals, min, max [, format, flags])` → vals, used
- `ImGui.SliderFloat4(label, vals, min, max [, format, flags])` → vals, used
- `ImGui.SliderInt(label, val, min, max [, format, flags])` → val, used
- `ImGui.SliderInt2(label, vals, min, max [, format, flags])` → vals, used
- `ImGui.SliderInt3(label, vals, min, max [, format, flags])` → vals, used
- `ImGui.SliderInt4(label, vals, min, max [, format, flags])` → vals, used
- `ImGui.SliderAngle(label, val_rad [, deg_min, deg_max, format, flags])` → val_rad, used

## Drag
- `ImGui.DragFloat(label, val [, speed, min, max, format, flags])` → val, used
- `ImGui.DragFloat2(label, vals [, speed, min, max, format, flags])` → vals, used
- `ImGui.DragFloat3(label, vals [, speed, min, max, format, flags])` → vals, used
- `ImGui.DragFloat4(label, vals [, speed, min, max, format, flags])` → vals, used
- `ImGui.DragInt(label, val [, speed, min, max, format, flags])` → val, used
- `ImGui.DragInt2(label, vals [, speed, min, max, format, flags])` → vals, used
- `ImGui.DragInt3(label, vals [, speed, min, max, format, flags])` → vals, used
- `ImGui.DragInt4(label, vals [, speed, min, max, format, flags])` → vals, used

## Color
- `ImGui.ColorEdit3(label, col [, flags])` → col, used
- `ImGui.ColorEdit4(label, col [, flags])` → col, used
- `ImGui.ColorPicker3(label, col [, flags])` → col, used
- `ImGui.ColorPicker4(label, col [, flags])` → col, used
- `ImGui.ColorButton(id, col [, flags, w, h])` → pressed
- `ImGui.SetColorEditOptions(flags)`

## Trees
- `ImGui.TreeNode(label [, text])` → open
- `ImGui.TreeNodeEx(label [, flags, text])` → open
- `ImGui.TreePush(id)`
- `ImGui.TreePop()`
- `ImGui.CollapsingHeader(label [, flags])` → open
- `ImGui.CollapsingHeader(label, open [, flags])` → open, open
- `ImGui.SetNextItemOpen(open [, cond])`
- `ImGui.GetTreeNodeToLabelSpacing()` → spacing
- `ImGui.IsItemToggledOpen()` → toggled

## Tables
- `ImGui.BeginTable(id, cols [, flags, w, h, inner_w])` → bool
- `ImGui.EndTable()`
- `ImGui.TableNextRow([flags, min_row_height])`
- `ImGui.TableNextColumn()` → visible
- `ImGui.TableSetColumnIndex(idx)` → visible
- `ImGui.TableSetupColumn(label [, flags, init_width_or_weight, user_id])`
- `ImGui.TableSetupScrollFreeze(cols, rows)`
- `ImGui.TableHeadersRow()`
- `ImGui.TableHeader(label)`
- `ImGui.TableGetSortSpecs()` → specs
- `ImGui.TableGetColumnCount()` → count
- `ImGui.TableGetColumnIndex()` → index
- `ImGui.TableGetRowIndex()` → index
- `ImGui.TableGetColumnName([col])` → name
- `ImGui.TableGetColumnFlags([col])` → flags
- `ImGui.TableSetBgColor(target, color [, col])`

## Columns (Legacy)
- `ImGui.Columns([count, id, border])`
- `ImGui.NextColumn()`
- `ImGui.GetColumnIndex()` → index
- `ImGui.GetColumnWidth([col])` → width
- `ImGui.SetColumnWidth(col, w)`
- `ImGui.GetColumnOffset([col])` → offset
- `ImGui.SetColumnOffset(col, offset)`
- `ImGui.GetColumnsCount()` → count

## ListBox
- `ImGui.ListBox(label, current, items [, count_items])` → current, clicked
- `ImGui.BeginListBox(label [, w, h])` → open
- `ImGui.EndListBox()`

## Menus
- `ImGui.BeginMenu(label [, enabled])` → open
- `ImGui.EndMenu()`
- `ImGui.MenuItem(label [, shortcut, selected, enabled])` → activated | selected, activated
- `ImGui.BeginMainMenuBar()` → open
- `ImGui.EndMainMenuBar()`
- `ImGui.BeginMenuBar()` → open
- `ImGui.EndMenuBar()`

## Popups
- `ImGui.OpenPopup(id)`
- `ImGui.BeginPopup(id [, flags])` → open
- `ImGui.BeginPopupModal(id [, open, flags])` → open
- `ImGui.EndPopup()`
- `ImGui.CloseCurrentPopup()`
- `ImGui.BeginPopupContextItem([id, flags])` → open
- `ImGui.BeginPopupContextWindow([id, flags])` → open
- `ImGui.BeginPopupContextVoid([id, flags])` → open
- `ImGui.OpenPopupContextItem([id, flags])` → open
- `ImGui.OpenPopupContextWindow([id, flags])` → open
- `ImGui.OpenPopupContextVoid([id, flags])` → open

## Tooltips
- `ImGui.BeginTooltip()` → bool
- `ImGui.EndTooltip()`
- `ImGui.SetTooltip(fmt, ...)`

## Tab Bars
- `ImGui.BeginTabBar(id [, flags])` → open
- `ImGui.EndTabBar()`
- `ImGui.BeginTabItem(label [, open, flags])` → open | open, selected
- `ImGui.EndTabItem()`
- `ImGui.EndTabBar()`

## Item Queries
- `ImGui.IsItemVisible()` → bool
- `ImGui.IsItemActive()` → bool
- `ImGui.IsItemHovered()` → bool
- `ImGui.IsItemClicked()` → bool
- `ImGui.IsItemFocused()` → bool
- `ImGui.IsItemToggledOpen()` → bool

## Focus
- `ImGui.SetKeyboardFocusHere([offset])`
