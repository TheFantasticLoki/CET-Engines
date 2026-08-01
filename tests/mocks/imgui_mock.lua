--[[
    ImGui API Mock

    Provides stubs for ImGui API functions used in CET.
    Used in unit tests to run without the game.

    ImGui is the immediate-mode GUI library used by CET.
    This mock provides no-op implementations that return sensible defaults.
]]

if _G.IMGUI_MOCK_LOADED then
    return
end
_G.IMGUI_MOCK_LOADED = true

-- Ensure ImGui table exists
if not _G.ImGui then
    _G.ImGui = {}
end

local ImGui = _G.ImGui

-- Track push/pop balance for testing
ImGui._pushCount = 0
ImGui._popCount = 0

--- Reset push/pop counters (call in test setup)
function ImGui._resetCounters()
    ImGui._pushCount = 0
    ImGui._popCount = 0
end

--- Get push/pop balance (should be 0 when balanced)
function ImGui._getBalance()
    return ImGui._pushCount - ImGui._popCount
end

-- --- Window functions ---

function ImGui.Begin(name, open, flags)
    return true
end

function ImGui.End()
end

function ImGui.BeginChild(id, size, border, flags)
    return true
end

function ImGui.EndChild()
end

function ImGui.BeginPopup(id, flags)
    return false
end

function ImGui.EndPopup()
end

function ImGui.OpenPopup(id)
end

function ImGui.BeginMainMenuBar()
    return false
end

function ImGui.EndMainMenuBar()
end

function ImGui.BeginMenuBar()
    return false
end

function ImGui.EndMenuBar()
end

function ImGui.BeginTabBar(id, flags)
    return false
end

function ImGui.EndTabBar()
end

function ImGui.BeginTabItem(label, open, flags)
    return false
end

function ImGui.EndTabItem()
end

function ImGui.BeginTooltip()
end

function ImGui.EndTooltip()
end

function ImGui.SetTooltip(text)
end

-- --- Layout functions ---

function ImGui.Separator()
end

function ImGui.SameLine(offset, spacing)
end

function ImGui.Spacing()
end

function ImGui.Indent(indent_w)
end

function ImGui.Unindent(indent_w)
end

function ImGui.Columns(count, id, border)
end

function ImGui.NextColumn()
end

function ImGui.SeparatorText(text)
end

function ImGui.Dummy(width, height)
end

function ImGui.NewLine()
end

function ImGui.AlignTextToFramePadding()
end

function ImGui.TextColored(col, text)
end

function ImGui.TextDisabled(text)
end

function ImGui.TextWrapped(text)
end

function ImGui.BulletText(text)
end

function ImGui.TreePush(id)
end

function ImGui.TreePop()
end

function ImGui.CollapsingHeader(label, flags)
    return true
end

function ImGui.Selectable(label, selected, flags, size)
    return false, false
end

function ImGui.TreeNode(label)
    return false
end

function ImGui.EndTreeNode()
end

-- --- Widget functions ---

function ImGui.Button(label, size)
    return false
end

function ImGui.SmallButton(label)
    return false
end

function ImGui.InvisibleButton(id, size)
    return false
end

function ImGui.Checkbox(label, value)
    return false, value
end

function ImGui.RadioButton(label, active)
    return false, active
end

function ImGui.InputText(label, value, flags, callback, user_data)
    return false, value
end

function ImGui.InputTextMultiline(label, value, size, flags, callback, user_data)
    return false, value
end

function ImGui.InputTextWithHint(label, hint, value, flags, callback, user_data)
    return false, value
end

function ImGui.InputFloat(label, value, step, step_fast, format, flags)
    return false, value
end

function ImGui.InputFloat2(label, value, format, flags)
    return false, value
end

function ImGui.InputInt(label, value, step, step_fast, flags)
    return false, value
end

function ImGui.InputInt2(label, value, flags)
    return false, value
end

function ImGui.SliderFloat(label, value, min, max, format, flags)
    return false, value
end

function ImGui.SliderFloat2(label, value, min, max, format, flags)
    return false, value
end

function ImGui.SliderInt(label, value, min, max, format, flags)
    return false, value
end

function ImGui.SliderInt2(label, value, min, max, format, flags)
    return false, value
end

function ImGui.DragFloat(label, value, speed, min, max, format, flags)
    return false, value
end

function ImGui.DragFloat2(label, value, speed, min, max, format, flags)
    return false, value
end

function ImGui.DragInt(label, value, speed, min, max, format, flags)
    return false, value
end

function ImGui.DragInt2(label, value, speed, min, max, format, flags)
    return false, value
end

function ImGui.ColorEdit3(label, color, flags)
    return false, color
end

function ImGui.ColorEdit4(label, color, flags)
    return false, color
end

function ImGui.ColorPicker3(label, color, flags)
    return false, color
end

function ImGui.ColorPicker4(label, color, flags)
    return false, color
end

function ImGui.Combo(label, current_item, items, items_count, height_in_items)
    return false, current_item
end

function ImGui.BeginCombo(label, preview_value, flags)
    return false
end

function ImGui.EndCombo()
end

function ImGui.ListBox(label, current_item, items, items_count, height_in_items)
    return false, current_item
end

function ImGui.ProgressBar(fraction, size, overlay)
end

function ImGui.Image(texture_id, size, uv0, uv1, tint_col, border_col)
end

function ImGui.ImageButton(str_id, texture_id, size, uv0, uv1, tint_col, border_col)
    return false
end

-- --- Style functions ---

function ImGui.PushStyleColor(idx, col)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopStyleColor(count)
    count = count or 1
    ImGui._popCount = ImGui._popCount + count
end

function ImGui.PushStyleVar(idx, val)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopStyleVar(count)
    count = count or 1
    ImGui._popCount = ImGui._popCount + count
end

function ImGui.PushFont(font)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopFont()
    ImGui._popCount = ImGui._popCount + 1
end

function ImGui.PushID(id)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopID()
    ImGui._popCount = ImGui._popCount + 1
end

function ImGui.GetID(id)
    return 0
end

-- --- Query functions ---

function ImGui.IsItemHovered(flags)
    return false
end

function ImGui.IsItemActive()
    return false
end

function ImGui.IsItemClicked(button)
    return false
end

function ImGui.IsItemVisible()
    return true
end

function ImGui.IsWindowFocused(flags)
    return false
end

function ImGui.IsWindowHovered(flags)
    return false
end

-- --- Text functions ---

function ImGui.Text(text)
end

function ImGui.GetContentRegionAvail()
    return 200, 200
end

function ImGui.GetCursorScreenPos()
    return 0, 0
end

function ImGui.SetCursorScreenPos(pos)
end

function ImGui.GetWindowSize()
    return 400, 300
end

function ImGui.GetWindowPos()
    return 0, 0
end

function ImGui.GetFrameHeight()
    return 20
end

function ImGui.GetFontSize()
    return 14
end

function ImGui.GetContentRegionMax()
    return 200, 200
end

function ImGui.GetCursorPos()
    return 0, 0
end

function ImGui.SetCursorPos(x, y)
end

function ImGui.GetCursorPosX()
    return 0
end

function ImGui.GetCursorPosY()
    return 0
end

-- --- Drawing functions ---

function ImGui.GetWindowDrawList()
    return ImGui._mockDrawList
end

function ImGui.GetForegroundDrawList()
    return ImGui._mockDrawList
end

function ImGui.GetBackgroundDrawList()
    return ImGui._mockDrawList
end

-- Mock draw list
ImGui._mockDrawList = {
    AddLine = function() end,
    AddRect = function() end,
    AddRectFilled = function() end,
    AddCircle = function() end,
    AddCircleFilled = function() end,
    AddText = function() end,
    AddTextWrapped = function() end,
    AddImage = function() end,
    AddBezierCubic = function() end,
    PathLineTo = function() end,
    PathStroke = function() end,
    PathFillConvex = function() end,
}

-- --- Clipboard ---

function ImGui.SetClipboardText(text)
end

function ImGui.GetClipboardText()
    return ""
end

-- --- IO ---

function ImGui.GetIO()
    return {
        DeltaTime = 0.016,
        DisplaySize = { x = 1920, y = 1080 },
    }
end

function ImGui.GetMousePos()
    return 0, 0
end

function ImGui.IsMouseDown(button)
    return false
end

function ImGui.IsAnyItemActive()
    return false
end

function ImGui.IsAnyItemFocused()
    return false
end

function ImGui.SetKeyboardFocusHere(offset)
end

-- --- Table functions ---

function ImGui.BeginTable(id, column, flags, outer_size, inner_width)
    return true
end

function ImGui.EndTable()
end

function ImGui.TableNextRow(flags, min_row_height)
end

function ImGui.TableNextColumn()
    return true
end

function ImGui.TableSetupColumn(label, flags, init_width_or_weight, user_id)
end

function ImGui.TableHeadersRow()
end

function ImGui.TableGetColumnCount()
    return 0
end

function ImGui.TableGetColumnIndex()
    return 0
end

function ImGui.TableGetColumnName(column_index)
    return ""
end

-- --- Color constants ---

ImGui.Col_Text = 0
ImGui.Col_TextDisabled = 1
ImGui.Col_WindowBg = 2
ImGui.Col_ChildBg = 3
ImGui.Col_PopupBg = 4
ImGui.Col_Border = 5
ImGui.Col_BorderShadow = 6
ImGui.Col_FrameBg = 7
ImGui.Col_FrameBgHovered = 8
ImGui.Col_FrameBgActive = 9
ImGui.Col_TitleBg = 10
ImGui.Col_TitleBgActive = 11
ImGui.Col_MenuBarBg = 12
ImGui.Col_ScrollbarBg = 13
ImGui.Col_ScrollbarGrab = 14
ImGui.Col_ScrollbarGrabHovered = 15
ImGui.Col_ScrollbarGrabActive = 16
ImGui.Col_CheckMark = 17
ImGui.Col_SliderGrab = 18
ImGui.Col_SliderGrabActive = 19
ImGui.Col_Button = 20
ImGui.Col_ButtonHovered = 21
ImGui.Col_ButtonActive = 22
ImGui.Col_Header = 23
ImGui.Col_HeaderHovered = 24
ImGui.Col_HeaderActive = 25
ImGui.Col_Separator = 26
ImGui.Col_SeparatorHovered = 27
ImGui.Col_SeparatorActive = 28
ImGui.Col_ResizeGrip = 29
ImGui.Col_ResizeGripHovered = 30
ImGui.Col_ResizeGripActive = 31
ImGui.Col_Tab = 32
ImGui.Col_TabHovered = 33
ImGui.Col_TabActive = 34

-- --- StyleVar constants ---

ImGui.StyleVar_Alpha = 0
ImGui.StyleVar_WindowPadding = 1
ImGui.StyleVar_WindowRounding = 2
ImGui.StyleVar_WindowBorderSize = 3
ImGui.StyleVar_ChildRounding = 4
ImGui.StyleVar_ChildBorderSize = 5
ImGui.StyleVar_PopupRounding = 6
ImGui.StyleVar_PopupBorderSize = 7
ImGui.StyleVar_FramePadding = 8
ImGui.StyleVar_FrameRounding = 9
ImGui.StyleVar_FrameBorderSize = 10
ImGui.StyleVar_ItemSpacing = 11
ImGui.StyleVar_ItemInnerSpacing = 12
ImGui.StyleVar_IndentSpacing = 13
ImGui.StyleVar_ScrollbarSize = 14
ImGui.StyleVar_ScrollbarRounding = 15
ImGui.StyleVar_GrabMinSize = 16
ImGui.StyleVar_GrabRounding = 17
ImGui.StyleVar_TabRounding = 18

-- --- Flags ---

ImGui.InputTextFlags_None = 0
ImGui.InputTextFlags_CharsDecimal = 1
ImGui.InputTextFlags_CharsHexadecimal = 2
ImGui.InputTextFlags_CharsScientific = 4
ImGui.InputTextFlags_CallbackAlways = 8

ImGui.ColorEditFlags_None = 0
ImGui.ColorEditFlags_NoAlpha = 1
ImGui.ColorEditFlags_NoPicker = 2
ImGui.ColorEditFlags_NoOptions = 4
ImGui.ColorEditFlags_NoSmallPreview = 8
ImGui.ColorEditFlags_NoInputs = 16
ImGui.ColorEditFlags_NoTooltip = 32
ImGui.ColorEditFlags_NoLabel = 64
ImGui.ColorEditFlags_NoSidePreview = 128

ImGui.SliderFlags_None = 0
ImGui.SliderFlags_AlwaysClamp = 4
ImGui.SliderFlags_Logarithmic = 8

ImGui.TreeNodeFlags_None = 0
ImGui.TreeNodeFlags_Selected = 1
ImGui.TreeNodeFlags_Framed = 2
ImGui.TreeNodeFlags_AllowOverlap = 4
ImGui.TreeNodeFlags_NoTreePushOnOpen = 8
ImGui.TreeNodeFlags_NoAutoOpenOnLog = 16

ImGui.SelectableFlags_None = 0
ImGui.SelectableFlags_AllowDoubleClick = 1

ImGui.TabBarFlags_None = 0
ImGui.TabBarFlags_NoTooltip = 1
ImGui.TabBarFlags_NoCloseWithMiddleMouseButton = 2

ImGui.PopupFlags_None = 0

ImGui.WindowFlags_None = 0
ImGui.WindowFlags_NoTitleBar = 1
ImGui.WindowFlags_NoResize = 2
ImGui.WindowFlags_NoMove = 4
ImGui.WindowFlags_NoScrollbar = 8
ImGui.WindowFlags_NoCollapse = 16
ImGui.WindowFlags_NoBackground = 32

ImGui.ColFlags_None = 0
ImGui.ColFlags_NoBorder = 1
ImGui.ColFlags_NoResizeX = 2
ImGui.ColFlags_NoResizeY = 4
ImGui.ColFlags_NoSort = 8

ImGui.ComboFlags_None = 0

-- --- ImGuiCol namespace (for ImGuiCol.Button, etc.) ---

ImGuiCol = {
    Button = ImGui.Col_Button,
    ButtonHovered = ImGui.Col_ButtonHovered,
    ButtonActive = ImGui.Col_ButtonActive,
    FrameBg = ImGui.Col_FrameBg,
    FrameBgHovered = ImGui.Col_FrameBgHovered,
    FrameBgActive = ImGui.Col_FrameBgActive,
    Text = ImGui.Col_Text,
    TextDisabled = ImGui.Col_TextDisabled,
    WindowBg = ImGui.Col_WindowBg,
    ChildBg = ImGui.Col_ChildBg,
    Border = ImGui.Col_Border,
    Header = ImGui.Col_Header,
    HeaderHovered = ImGui.Col_HeaderHovered,
    HeaderActive = ImGui.Col_HeaderActive,
    SliderGrab = ImGui.Col_SliderGrab,
    SliderGrabActive = ImGui.Col_SliderGrabActive,
    CheckMark = ImGui.Col_CheckMark,
    ScrollbarGrab = ImGui.Col_ScrollbarGrab,
    ScrollbarGrabHovered = ImGui.Col_ScrollbarGrabHovered,
    ScrollbarGrabActive = ImGui.Col_ScrollbarGrabActive,
    ResizeGrip = ImGui.Col_ResizeGrip,
    ResizeGripHovered = ImGui.Col_ResizeGripHovered,
    ResizeGripActive = ImGui.Col_ResizeGripActive,
    Tab = ImGui.Col_Tab,
    TabHovered = ImGui.Col_TabHovered,
    TabActive = ImGui.Col_TabActive,
    TitleBg = ImGui.Col_TitleBg,
    TitleBgActive = ImGui.Col_TitleBgActive,
}

-- --- ImGuiStyleVar namespace ---

ImGuiStyleVar = {
    WindowPadding = ImGui.StyleVar_WindowPadding,
    FramePadding = ImGui.StyleVar_FramePadding,
    ItemSpacing = ImGui.StyleVar_ItemSpacing,
    WindowRounding = ImGui.StyleVar_WindowRounding,
    ChildRounding = ImGui.StyleVar_ChildRounding,
    FrameRounding = ImGui.StyleVar_FrameRounding,
    GrabRounding = ImGui.StyleVar_GrabRounding,
    TabRounding = ImGui.StyleVar_TabRounding,
    WindowBorderSize = ImGui.StyleVar_WindowBorderSize,
    ChildBorderSize = ImGui.StyleVar_ChildBorderSize,
}

-- --- ImGui.Cond namespace ---

ImGuiCond = {
    Always = 1,
    Once = 2,
    FirstUseEver = 4,
    Appearing = 8,
}

-- --- ImGui.WindowFlags namespace ---

ImGui.WindowFlags = {
    None = 0,
    NoDecoration = 1,
    NoScrollbar = 8,
    NoFocusOnAppearing = 0,
    NoNav = 0,
}

-- --- ImGui.InputTextFlags namespace ---

ImGui.InputTextFlags = {
    None = 0,
    EnterReturnsTrue = 4,
    CharsDecimal = 1,
    CharsHexadecimal = 2,
    CharsScientific = 4,
}

-- --- ImGui.TableFlags namespace ---

ImGui.TableFlags = {
    None = 0,
    Borders = 1,
    BordersH = 2,
    BordersV = 4,
    RowBg = 8,
}

-- --- ImGui.Key namespace ---

ImGui.Key = {
    UpArrow = 0,
    DownArrow = 1,
    LeftArrow = 2,
    RightArrow = 3,
}

-- --- ImGuiTreeNodeFlags namespace ---

ImGui.TreeNodeFlags = {
    None = 0,
    Selected = 1,
    Framed = 2,
    AllowOverlap = 4,
    NoTreePushOnOpen = 8,
    NoAutoOpenOnLog = 16,
    DefaultOpen = 32,
}

-- Global alias for ImGuiTreeNodeFlags (used by some CET mods)
ImGuiTreeNodeFlags = ImGui.TreeNodeFlags

-- --- Text functions ---

function ImGui.Text(text)
end

function ImGui.TextColored(r, g, b, a, text)
end

function ImGui.TextDisabled(text)
end

function ImGui.TextWrapped(text)
end

function ImGui.BulletText(text)
end

function ImGui.SeparatorText(text)
end

-- --- Widget functions ---

function ImGui.SetNextItemWidth(width)
end

function ImGui.CalcTextSize(text)
    if text then
        return #text * 8, 16
    end
    return 0, 0
end

function ImGui.MenuItem(label, selected, enabled)
    return false
end

function ImGui.SetColumnWidth(index, width)
end

function ImGui.SetCursorPosX(x)
end

function ImGui.SetScrollHereY(center_y_ratio)
end

function ImGui.SetNextWindowPos(pos_x, pos_y, cond)
end

function ImGui.SetNextWindowSize(size_x, size_y, cond)
end

function ImGui.IsKeyPressed(key, repeat_flag)
    return false
end

-- --- Popup functions ---

function ImGui.BeginPopupContextWindow(id, flags)
    return false
end