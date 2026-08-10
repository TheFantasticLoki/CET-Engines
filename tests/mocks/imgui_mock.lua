--[[
    ImGui API Mock — Comprehensive CET-Compatible Implementation

    Provides stubs for ALL ImGui API functions used in CET.
    Based on CET_ImGui_lua_type_defines/ImGui.lua from dependencies/lua-libs/.

    Used in unit tests to run without the game.
    Returns sensible defaults for all functions.
]]

if _G.IMGUI_MOCK_LOADED then
    return
end
_G.IMGUI_MOCK_LOADED = true

-- ============================================================================
-- Core Types
-- ============================================================================

---@class ImVec2
---@field x number
---@field y number
ImVec2 = {}
function ImVec2.new(x, y)
    return { x = x or 0, y = y or 0 }
end

---@class ImVec4
---@field x number
---@field y number
---@field z number
---@field w number
ImVec4 = {}
function ImVec4.new(x, y, z, w)
    return { x = x or 0, y = y or 0, z = z or 0, w = w or 0 }
end

---@class ImGuiStyle
ImGuiStyle = {
    Alpha = 1.0,
    WindowPadding = { x = 8, y = 8 },
    WindowRounding = 0,
    FramePadding = { x = 4, y = 3 },
    FrameRounding = 0,
    ItemSpacing = { x = 8, y = 4 },
    ItemInnerSpacing = { x = 4, y = 4 },
    IndentSpacing = 21,
    ScrollbarSize = 16,
    GrabMinSize = 10,
}
function ImGuiStyle.ScaleAllSizes(scale_factor)
    -- no-op for mock
end

---@class ImGuiListClipper
ImGuiListClipper = {}
function ImGuiListClipper.new()
    return {
        StartIndex = 0,
        EndIndex = 0,
        ItemsCount = 0,
        ItemsHeight = 0,
    }
end
function ImGuiListClipper.Begin(self, items_count, items_height)
    self.ItemsCount = items_count or 0
    self.ItemsHeight = items_height or 0
    self.StartIndex = 0
    self.EndIndex = math.min(items_count or 0, 100)
end
function ImGuiListClipper.End(self)
    -- no-op
end
function ImGuiListClipper.Step(self)
    return false
end

-- ============================================================================
-- ImGui Enums (Constants)
-- ============================================================================

---@enum ImGuiWindowFlags
ImGuiWindowFlags = {
    None = 0,
    NoTitleBar = 1,
    NoResize = 2,
    NoMove = 4,
    NoScrollbar = 8,
    NoScrollWithMouse = 16,
    NoCollapse = 32,
    AlwaysAutoResize = 64,
    NoBackground = 128,
    NoSavedSettings = 256,
    NoMouseInputs = 512,
    MenuBar = 1024,
    HorizontalScrollbar = 2048,
    NoFocusOnAppearing = 4096,
    NoBringToFrontOnFocus = 8192,
    AlwaysVerticalScrollbar = 16384,
    AlwaysHorizontalScrollbar = 32768,
    AlwaysUseWindowPadding = 65536,
    NoNavInputs = 131072,
    NoNavFocus = 262144,
    UnsavedDocument = 524288,
    NoNav = 4194304,
    NoDecoration = 8388608,
    NoInputs = 16777216,
    ChildWindow = 1048576,
    Tooltip = 2097152,
    Popup = 4194304,
    Modal = 8388608,
    ChildMenu = 16777216,
}

---@enum ImGuiCond
ImGuiCond = {
    None = 0,
    Always = 1,
    Once = 2,
    FirstUseEver = 3,
    Appearing = 4,
}

---@enum ImGuiCol
ImGuiCol = {
    Text = 0,
    TextDisabled = 1,
    WindowBg = 2,
    ChildBg = 3,
    PopupBg = 4,
    Border = 5,
    BorderShadow = 6,
    FrameBg = 7,
    FrameBgHovered = 8,
    FrameBgActive = 9,
    TitleBg = 10,
    TitleBgActive = 11,
    TitleBgCollapsed = 12,
    MenuBarBg = 13,
    ScrollbarBg = 14,
    ScrollbarGrab = 15,
    ScrollbarGrabHovered = 16,
    ScrollbarGrabActive = 17,
    CheckMark = 18,
    SliderGrab = 19,
    SliderGrabActive = 20,
    Button = 21,
    ButtonHovered = 22,
    ButtonActive = 23,
    Header = 24,
    HeaderHovered = 25,
    HeaderActive = 26,
    Separator = 27,
    SeparatorHovered = 28,
    SeparatorActive = 29,
    ResizeGrip = 30,
    ResizeGripHovered = 31,
    ResizeGripActive = 32,
    Tab = 33,
    TabHovered = 34,
    TabActive = 35,
    TabUnfocused = 36,
    TabUnfocusedActive = 37,
    PlotLines = 38,
    PlotLinesHovered = 39,
    PlotHistogram = 40,
    PlotHistogramHovered = 41,
    TableHeaderBg = 42,
    TableBorderStrong = 43,
    TableBorderLight = 44,
    TableRowBg = 45,
    TableRowBgAlt = 46,
    TextSelectedBg = 47,
    DragDropTarget = 48,
    NavHighlight = 49,
    NavWindowingHighlight = 50,
    NavWindowingDimBg = 51,
    ModalWindowDimBg = 52,
    COUNT = 53,
}

---@enum ImGuiStyleVar
ImGuiStyleVar = {
    Alpha = 0,
    DisabledAlpha = 1,
    WindowPadding = 2,
    WindowRounding = 3,
    WindowBorderSize = 4,
    WindowMinSize = 5,
    WindowTitleAlign = 6,
    ChildRounding = 7,
    ChildBorderSize = 8,
    PopupRounding = 9,
    PopupBorderSize = 10,
    FramePadding = 11,
    FrameRounding = 12,
    FrameBorderSize = 13,
    ItemSpacing = 14,
    ItemInnerSpacing = 15,
    IndentSpacing = 16,
    CellPadding = 17,
    ScrollbarSize = 18,
    ScrollbarRounding = 19,
    GrabMinSize = 20,
    GrabRounding = 21,
    TabRounding = 22,
    SelectableTextAlign = 23,
    ButtonTextAlign = 24,
    COUNT = 25,
}

---@enum ImGuiDir
ImGuiDir = {
    None = 0,
    Left = 1,
    Right = 2,
    Up = 3,
    Down = 4,
    COUNT = 5,
}

---@enum ImGuiMouseButton
ImGuiMouseButton = {
    Left = 0,
    Right = 1,
    Middle = 2,
    COUNT = 3,
}

---@enum ImGuiFocusedFlags
ImGuiFocusedFlags = {
    None = 0,
    ChildWindows = 1,
    RootWindow = 2,
    AnyWindow = 3,
    RootAndChildWindows = 4,
}

---@enum ImGuiHoveredFlags
ImGuiHoveredFlags = {
    None = 0,
    ChildWindows = 1,
    RootWindow = 2,
    AnyWindow = 3,
    AllowWhenBlockedByPopup = 4,
    AllowWhenBlockedByActiveItem = 5,
    AllowWhenOverlapped = 6,
    AllowWhenDisabled = 7,
    RectOnly = 8,
    RootAndChildWindows = 9,
}

---@enum ImGuiInputTextFlags
ImGuiInputTextFlags = {
    None = 0,
    CharsDecimal = 1,
    CharsHexadecimal = 2,
    CharsUppercase = 4,
    CharsNoBlank = 8,
    AutoSelectAll = 16,
    EnterReturnsTrue = 32,
    CallbackCompletion = 64,
    CallbackHistory = 128,
    CallbackAlways = 256,
    CallbackCharFilter = 512,
    AllowTabInput = 1024,
    CtrlEnterForNewLine = 2048,
    NoHorizontalScroll = 4096,
    AlwaysOverwrite = 8192,
    ReadOnly = 16384,
    Password = 32768,
    NoUndoRedo = 65536,
    CharsScientific = 131072,
    CallbackResize = 262144,
    CallbackEdit = 524288,
}

---@enum ImGuiSliderFlags
ImGuiSliderFlags = {
    None = 0,
    ClampOnInput = 1,
    Logarithmic = 2,
    NoRoundToFormat = 4,
    NoInput = 8,
}

---@enum ImGuiColorEditFlags
ImGuiColorEditFlags = {
    None = 0,
    NoAlpha = 1,
    NoPicker = 2,
    NoOptions = 4,
    NoSmallPreview = 8,
    NoInputs = 16,
    NoTooltip = 32,
    NoLabel = 64,
    NoSidePreview = 128,
    NoDragDrop = 256,
    NoBorder = 512,
    AlphaBar = 1024,
    AlphaPreview = 2048,
    AlphaPreviewHalf = 4096,
    HDR = 8192,
    DisplayRGB = 16384,
    DisplayHSV = 32768,
    DisplayHex = 65536,
    Uint8 = 131072,
    Float = 262144,
    PickerHueBar = 524288,
    PickerHueWheel = 1048576,
    InputRGB = 2097152,
    InputHSV = 4194304,
}

---@enum ImGuiTreeNodeFlags
ImGuiTreeNodeFlags = {
    None = 0,
    Selected = 1,
    Framed = 2,
    AllowItemOverlap = 4,
    NoTreePushOnOpen = 8,
    NoAutoOpenOnLog = 16,
    DefaultOpen = 32,
    OpenOnDoubleClick = 64,
    OpenOnArrow = 128,
    Leaf = 256,
    Bullet = 512,
    FramePadding = 1024,
    SpanAvailWidth = 2048,
    SpanFullWidth = 4096,
    NavLeftJumpsBackHere = 8192,
    CollapsingHeader = 26,
}

---@enum ImGuiSelectableFlags
ImGuiSelectableFlags = {
    None = 0,
    DontClosePopups = 1,
    SpanAllColumns = 2,
    AllowDoubleClick = 4,
    Disabled = 8,
    AllowItemOverlap = 16,
}

---@enum ImGuiPopupFlags
ImGuiPopupFlags = {
    None = 0,
    MouseButtonLeft = 0,
    MouseButtonRight = 1,
    MouseButtonMiddle = 2,
    MouseButtonMask_ = 0x1F,
    MouseButtonDefault_ = 1,
    NoOpenOverExistingPopup = 8,
    NoOpenOverItems = 16,
    AnyPopupId = 32,
    AnyPopupLevel = 64,
    AnyPopup = 96,
}

---@enum ImGuiComboFlags
ImGuiComboFlags = {
    None = 0,
    PopupAlignLeft = 1,
    HeightSmall = 2,
    HeightRegular = 3,
    HeightLarge = 4,
    HeightLargest = 5,
    NoArrowButton = 6,
    NoPreview = 7,
    HeightMask = 15,
}

---@enum ImGuiTableFlags
ImGuiTableFlags = {
    None = 0,
    Resizable = 1,
    Reorderable = 2,
    Hideable = 4,
    Sortable = 8,
    NoSavedSettings = 16,
    ContextMenuInBody = 32,
    RowBg = 64,
    BordersInnerH = 128,
    BordersOuterH = 256,
    BordersInnerV = 512,
    BordersOuterV = 1024,
    BordersH = 384,
    BordersV = 1536,
    BordersInner = 640,
    BordersOuter = 1280,
    Borders = 1920,
    NoBordersInBody = 2048,
    NoBordersInBodyUntilResize = 4096,
    SizingFixedFit = 8192,
    SizingFixedSame = 16384,
    SizingStretchProp = 24576,
    SizingStretchSame = 32768,
    NoHostExtendX = 65536,
    NoHostExtendY = 131072,
    NoKeepColumnsVisible = 262144,
    PreciseWidths = 524288,
    NoClip = 1048576,
    PadOuterX = 2097152,
    NoPadOuterX = 4194304,
    NoPadInnerX = 8388608,
    ScrollX = 16777216,
    ScrollY = 33554432,
    SortMulti = 67108864,
    SortTristate = 134217728,
}

---@enum ImGuiTableRowFlags
ImGuiTableRowFlags = {
    None = 0,
    Headers = 1,
}

---@enum ImGuiTableColumnFlags
ImGuiTableColumnFlags = {
    None = 0,
    Disabled = 1,
    DefaultHide = 2,
    DefaultSort = 4,
    WidthStretch = 8,
    WidthFixed = 16,
    NoResize = 32,
    NoReorder = 64,
    NoHide = 128,
    NoClip = 256,
    NoSort = 512,
    NoSortAscending = 1024,
    NoSortDescending = 2048,
    NoHeaderLabel = 4096,
    NoHeaderWidth = 8192,
    PreferSortAscending = 16384,
    PreferSortDescending = 32768,
    IndentEnable = 65536,
    IndentDisable = 131072,
}

---@enum ImGuiTableBgTarget
ImGuiTableBgTarget = {
    None = 0,
    RowBg0 = 1,
    RowBg1 = 2,
    CellBg = 3,
}

---@enum ImDrawFlags
ImDrawFlags = {
    None = 0,
    Closed = 1,
    RoundCornersTopLeft = 2,
    RoundCornersTopRight = 4,
    RoundCornersBottomLeft = 8,
    RoundCornersBottomRight = 16,
    RoundCornersNone = 32,
    RoundCornersTop = 6,
    RoundCornersBottom = 24,
    RoundCornersLeft = 10,
    RoundCornersRight = 20,
    RoundCornersAll = 30,
    RoundCornersMask_ = 62,
}

---@enum ImDrawCornerFlags (legacy)
ImDrawCornerFlags = {
    None = 0,
    TopLeft = 1,
    TopRight = 2,
    BotLeft = 4,
    BotRight = 8,
    Top = 3,
    Bot = 12,
    Left = 5,
    Right = 10,
    All = 15,
}

---@enum ImGuiTabBarFlags
ImGuiTabBarFlags = {
    None = 0,
    Reorderable = 1,
    AutoSelectNewTabs = 2,
    TabListPopupButton = 4,
    NoCloseWithMiddleMouseButton = 8,
    NoTabListScrollingButtons = 16,
    NoTooltip = 32,
    FittingPolicyResizeDown = 64,
    FittingPolicyScroll = 128,
    FittingPolicyMask_ = 192,
    FittingPolicyDefault_ = 64,
}

---@enum ImGuiTabItemFlags
ImGuiTabItemFlags = {
    None = 0,
    UnsavedDocument = 1,
    SetSelected = 2,
    NoCloseWithMiddleMouseButton = 4,
    NoPushId = 8,
    NoTooltip = 16,
    NoReorder = 32,
    NoLeading = 64,
    NoTrailing = 128,
}

---@enum ImGuiKey
ImGuiKey = {
    Tab = 0,
    LeftArrow = 1,
    RightArrow = 2,
    UpArrow = 3,
    DownArrow = 4,
    PageUp = 5,
    PageDown = 6,
    Home = 7,
    End = 8,
    Insert = 9,
    Delete = 10,
    Backspace = 11,
    Space = 12,
    Enter = 13,
    Escape = 14,
    KeyPadEnter = 15,
    A = 16,
    C = 17,
    V = 18,
    X = 19,
    Y = 20,
    Z = 21,
    LeftShift = 22,
    LeftCtrl = 23,
    LeftAlt = 24,
    LeftSuper = 25,
    RightShift = 26,
    RightCtrl = 27,
    RightAlt = 28,
    RightSuper = 29,
    COUNT = 30,
}

-- ============================================================================
-- ImGui Global Table
-- ============================================================================

if not _G.ImGui then
    _G.ImGui = {}
end

local ImGui = _G.ImGui

-- Track push/pop balance for testing
ImGui._pushCount = 0
ImGui._popCount = 0
ImGui._stylePushCount = 0
ImGui._stylePopCount = 0

--- Reset push/pop counters (call in test setup)
function ImGui._resetCounters()
    ImGui._pushCount = 0
    ImGui._popCount = 0
    ImGui._stylePushCount = 0
    ImGui._stylePopCount = 0
end

--- Get push/pop balance (should be 0 when balanced)
function ImGui._getBalance()
    return ImGui._stylePushCount - ImGui._stylePopCount
end

-- ============================================================================
-- Window Functions
-- ============================================================================

function ImGui.Begin(name, open, flags)
    return true
end

function ImGui.End()
end

function ImGui.BeginChild(id, sizeX, sizeY, border, flags)
    return true
end

function ImGui.EndChild()
end

function ImGui.IsWindowAppearing()
    return false
end

function ImGui.IsWindowCollapsed()
    return false
end

function ImGui.IsWindowFocused(flags)
    return false
end

function ImGui.IsWindowHovered(flags)
    return false
end

function ImGui.GetWindowDrawList()
    return ImGui._mockDrawList
end

function ImGui.GetWindowPos()
    return 0, 0
end

function ImGui.GetWindowSize()
    return 800, 600
end

function ImGui.GetWindowWidth()
    return 800
end

function ImGui.GetWindowHeight()
    return 600
end

function ImGui.SetNextWindowPos(posX, posY, cond, pivotX, pivotY)
end

function ImGui.SetNextWindowSize(sizeX, sizeY, cond)
end

function ImGui.SetNextWindowSizeConstraints(minX, minY, maxX, maxY)
end

function ImGui.SetNextWindowContentSize(sizeX, sizeY)
end

function ImGui.SetNextWindowCollapsed(collapsed, cond)
end

function ImGui.SetNextWindowFocus()
end

function ImGui.SetNextWindowBgAlpha(alpha)
end

function ImGui.SetWindowPos(posX, posY, cond, name)
end

function ImGui.SetWindowSize(sizeX, sizeY, cond, name)
end

function ImGui.SetWindowCollapsed(collapsed, cond, name)
end

function ImGui.SetWindowFocus(name)
end

function ImGui.SetWindowFontScale(scale)
end

-- ============================================================================
-- Layout & Spacing Functions
-- ============================================================================

function ImGui.Separator()
end

function ImGui.SameLine(offsetFromStartX, spacing)
end

function ImGui.NewLine()
end

function ImGui.Spacing()
end

function ImGui.Dummy(sizeX, sizeY)
end

function ImGui.Indent(indentW)
end

function ImGui.Unindent(indentW)
end

function ImGui.BeginGroup()
end

function ImGui.EndGroup()
end

function ImGui.PushItemWidth(itemWidth)
end

function ImGui.PopItemWidth()
end

function ImGui.SetNextItemWidth(itemWidth)
end

function ImGui.CalcItemWidth()
    return 200
end

function ImGui.PushTextWrapPos(wrapLocalPosX)
end

function ImGui.PopTextWrapPos()
end

function ImGui.PushClipRect(min_x, min_y, max_x, max_y, intersect_current)
end

function ImGui.PopClipRect()
end

-- ============================================================================
-- Cursor & Positioning Functions
-- ============================================================================

function ImGui.GetCursorPos()
    return 0, 0
end

function ImGui.GetCursorPosX()
    return 0
end

function ImGui.GetCursorPosY()
    return 0
end

function ImGui.SetCursorPos(localX, localY)
end

function ImGui.SetCursorPosX(localX)
end

function ImGui.SetCursorPosY(localY)
end

function ImGui.GetCursorStartPos()
    return 0, 0
end

function ImGui.GetCursorScreenPos()
    return 0, 0
end

function ImGui.SetCursorScreenPos(posX, posY)
end

-- ============================================================================
-- Text Display Functions
-- ============================================================================

function ImGui.Text(text)
end

function ImGui.TextUnformatted(text)
end

function ImGui.TextColored(colR, colG, colB, colA, text)
end

function ImGui.TextDisabled(text)
end

function ImGui.TextWrapped(text)
end

function ImGui.LabelText(label, text)
end

function ImGui.BulletText(text)
end

function ImGui.CalcTextSize(text, hide_text_after_double_hash, wrap_width)
    return 100, 14
end

-- ============================================================================
-- Interactive Widget Functions
-- ============================================================================

function ImGui.Button(label, sizeX, sizeY)
    return false
end

function ImGui.SmallButton(label)
    return false
end

function ImGui.InvisibleButton(stringID, sizeX, sizeY)
    return false
end

function ImGui.ArrowButton(stringID, dir)
    return false
end

function ImGui.Checkbox(label, v)
    return false, v
end

function ImGui.RadioButton(label, active, vButton)
    if vButton then
        return active, false
    end
    return false, active
end

function ImGui.ProgressBar(fraction, sizeX, sizeY, overlay)
end

function ImGui.Bullet()
end

function ImGui.Selectable(label, selected, flags, sizeX, sizeY)
    return false
end

-- ============================================================================
-- Combo Box Functions
-- ============================================================================

function ImGui.BeginCombo(label, previewValue, flags)
    return false
end

function ImGui.EndCombo()
end

function ImGui.Combo(label, currentItem, items, itemsCount_or_popupMaxHeightInItems)
    return currentItem, false
end

-- ============================================================================
-- Slider, Drag & Input Functions
-- ============================================================================

function ImGui.DragFloat(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragFloat2(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragFloat3(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragFloat4(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragInt(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragInt2(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragInt3(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.DragInt4(label, v, v_speed, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderFloat(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderFloat2(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderFloat3(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderFloat4(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderAngle(label, v_rad, v_degrees_min, v_degrees_max, format, flags)
    return false, v_rad
end

function ImGui.SliderInt(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderInt2(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderInt3(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.SliderInt4(label, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.VSliderFloat(label, sizeX, sizeY, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.VSliderInt(label, sizeX, sizeY, v, v_min, v_max, format, flags)
    return false, v
end

function ImGui.InputText(label, text, buf_size, flags, callback, user_data)
    return false, text
end

function ImGui.InputTextMultiline(label, text, buf_size, sizeX, sizeY, flags, callback, user_data)
    return false, text
end

function ImGui.InputTextWithHint(label, hint, text, buf_size, flags, callback, user_data)
    return false, text
end

function ImGui.InputFloat(label, v, step, step_fast, format, flags)
    return false, v
end

function ImGui.InputFloat2(label, v, format, flags)
    return false, v
end

function ImGui.InputFloat3(label, v, format, flags)
    return false, v
end

function ImGui.InputFloat4(label, v, format, flags)
    return false, v
end

function ImGui.InputInt(label, v, step, step_fast, flags)
    return false, v
end

function ImGui.InputInt2(label, v, flags)
    return false, v
end

function ImGui.InputInt3(label, v, flags)
    return false, v
end

function ImGui.InputInt4(label, v, flags)
    return false, v
end

function ImGui.InputDouble(label, v, step, step_fast, format, flags)
    return false, v
end

-- ============================================================================
-- Color Widget Functions
-- ============================================================================

function ImGui.ColorEdit3(label, col, flags)
    return false, col
end

function ImGui.ColorEdit4(label, col, flags)
    return false, col
end

function ImGui.ColorPicker3(label, col, flags)
    return false, col
end

function ImGui.ColorPicker4(label, col, flags)
    return false, col
end

function ImGui.ColorButton(desc_id, col, flags, sizeX, sizeY)
    return false
end

function ImGui.SetColorEditOptions(flags)
end

function ImGui.ColorConvertU32ToFloat4(in_val)
    return { 1, 1, 1, 1 }
end

function ImGui.ColorConvertFloat4ToU32(rgba)
    return 0xFFFFFFFF
end

function ImGui.ColorConvertRGBtoHSV(r, g, b)
    return 0, 0, 0
end

function ImGui.ColorConvertHSVtoRGB(h, s, v)
    return 1, 1, 1
end

-- ============================================================================
-- Tree & Node Functions
-- ============================================================================

function ImGui.TreeNode(label, fmt)
    return false
end

function ImGui.TreeNodeEx(label, flags, fmt)
    return false
end

function ImGui.TreePush(str_id)
end

function ImGui.TreePop()
end

function ImGui.GetTreeNodeToLabelSpacing()
    return 20
end

function ImGui.CollapsingHeader(label, flags, open)
    if type(flags) == "boolean" then
        -- CollapsingHeader(label, open) variant
        return true, flags
    end
    return true
end

function ImGui.SetNextItemOpen(is_open, cond)
end

-- ============================================================================
-- Tab Bar & Tab Functions
-- ============================================================================

function ImGui.BeginTabBar(str_id, flags)
    return false
end

function ImGui.EndTabBar()
end

function ImGui.BeginTabItem(label, flags, open)
    return false
end

function ImGui.EndTabItem()
end

function ImGui.SetTabItemClosed(tab_or_docked_window_label)
end

-- ============================================================================
-- Table Functions
-- ============================================================================

function ImGui.BeginTable(str_id, columns, flags, outer_sizeX, outer_sizeY, inner_width)
    return true
end

function ImGui.EndTable()
end

function ImGui.TableNextRow(flags, min_row_height)
    return true
end

function ImGui.TableNextColumn()
    return true
end

function ImGui.TableSetColumnIndex(column_n)
    return true
end

function ImGui.TableSetupColumn(label, flags, init_width_or_weight, user_id)
end

function ImGui.TableSetupScrollFreeze(cols, rows)
end

function ImGui.TableHeadersRow()
end

function ImGui.TableHeader(label)
end

function ImGui.TableGetSortSpecs()
    return nil
end

function ImGui.TableGetColumnCount()
    return 0
end

function ImGui.TableGetColumnIndex()
    return 0
end

function ImGui.TableGetRowIndex()
    return 0
end

function ImGui.TableGetColumnName(column_n)
    return ""
end

function ImGui.TableGetColumnFlags(column_n)
    return 0
end

function ImGui.TableSetBgColor(target, color, column_n)
end

-- ============================================================================
-- Menu Functions
-- ============================================================================

function ImGui.BeginMenuBar()
    return false
end

function ImGui.EndMenuBar()
end

function ImGui.BeginMainMenuBar()
    return false
end

function ImGui.EndMainMenuBar()
end

function ImGui.BeginMenu(label, enabled)
    return false
end

function ImGui.EndMenu()
end

function ImGui.MenuItem(label, shortcut, selected, enabled)
    if selected ~= nil then
        return false, selected
    end
    return false
end

-- ============================================================================
-- Tooltip Functions
-- ============================================================================

function ImGui.BeginTooltip()
end

function ImGui.EndTooltip()
end

function ImGui.SetTooltip(fmt)
end

-- ============================================================================
-- Popup Functions
-- ============================================================================

function ImGui.BeginPopup(str_id, flags)
    return false
end

function ImGui.BeginPopupModal(name, flags, open)
    if type(flags) == "boolean" then
        return false, flags
    end
    return false
end

function ImGui.EndPopup()
end

function ImGui.OpenPopup(str_id, popup_flags)
end

function ImGui.CloseCurrentPopup()
end

function ImGui.BeginPopupContextItem(str_id, popup_flags)
    return false
end

function ImGui.BeginPopupContextWindow(str_id, popup_flags)
    return false
end

function ImGui.BeginPopupContextVoid(str_id, popup_flags)
    return false
end

function ImGui.IsPopupOpen(str_id, popup_flags)
    return false
end

-- ============================================================================
-- Drawing Functions (ImDrawList)
-- ============================================================================

-- Mock draw list (flat float args — matches CET's sol2 bindings)
ImGui._mockDrawList = "mock_drawlist_userdata"

function ImGui.ImDrawListAddLine(drawList, p1X, p1Y, p2X, p2Y, col, thickness)
end

function ImGui.ImDrawListAddRect(drawList, p_minX, p_minY, p_maxX, p_maxY, col, rounding, flags, thickness)
end

function ImGui.ImDrawListAddRectFilled(drawList, p_minX, p_minY, p_maxX, p_maxY, col, rounding, flags)
end

function ImGui.ImDrawListAddRectFilledMultiColor(drawList, p_minX, p_minY, p_maxX, p_maxY, col_upr_left, col_upr_right, col_bot_right, col_bot_left)
end

function ImGui.ImDrawListAddCircle(drawList, centerX, centerY, radius, col, num_segments, thickness)
end

function ImGui.ImDrawListAddCircleFilled(drawList, centerX, centerY, radius, col, num_segments)
end

function ImGui.ImDrawListAddQuad(drawList, p1X, p1Y, p2X, p2Y, p3X, p3Y, p4X, p4Y, col, thickness)
end

function ImGui.ImDrawListAddQuadFilled(drawList, p1X, p1Y, p2X, p2Y, p3X, p3Y, p4X, p4Y, col)
end

function ImGui.ImDrawListAddTriangle(drawList, p1X, p1Y, p2X, p2Y, p3X, p3Y, col, thickness)
end

function ImGui.ImDrawListAddTriangleFilled(drawList, p1X, p1Y, p2X, p2Y, p3X, p3Y, col)
end

function ImGui.ImDrawListAddText(drawList, font_size_or_posX, posX_or_posY, posY_or_col, col_or_text, text_or_wrap, wrap_width)
    -- Handle both call signatures:
    -- ImDrawListAddText(drawList, posX, posY, col, text, wrap_width)
    -- ImDrawListAddText(drawList, font_size, posX, posY, col, text, wrap_width)
end

function ImGui.ImDrawListAddBezierCubic(drawList, p1X, p1Y, p2X, p2Y, p3X, p3Y, p4X, p4Y, col, thickness, num_segments)
end

function ImGui.ImDrawListAddBezierQuadratic(drawList, p1X, p1Y, p2X, p2Y, p3X, p3Y, col, thickness, num_segments)
end

function ImGui.ImDrawListAddNgon(drawList, centerX, centerY, radius, col, num_segments, thickness)
end

function ImGui.ImDrawListAddNgonFilled(drawList, centerX, centerY, radius, col, num_segments)
end

function ImGui.ImDrawListAddImage(drawList, texture_id, p_minX, p_minY, p_maxX, p_maxY, uv_minX, uv_minY, uv_maxX, uv_maxY, tint_col)
end

-- ============================================================================
-- Image & Texture Functions
-- ============================================================================

function ImGui.LoadTexture(path)
    return {
        size = { x = 64, y = 64 },
        Release = function() end,
    }
end

function ImGui.Image(texture, size, uv0, uv1, tint_col, border_col)
end

function ImGui.ImageButton(str_id, texture, size, uv0, uv1, tint_col, border_col)
    return false
end

-- ============================================================================
-- Item State Query Functions
-- ============================================================================

function ImGui.IsItemHovered(flags)
    return false
end

function ImGui.IsItemActive()
    return false
end

function ImGui.IsItemFocused()
    return false
end

function ImGui.IsItemClicked(button)
    return false
end

function ImGui.IsItemVisible()
    return true
end

function ImGui.IsItemEdited()
    return false
end

function ImGui.IsItemActivated()
    return false
end

function ImGui.IsItemDeactivated()
    return false
end

function ImGui.IsItemDeactivatedAfterEdit()
    return false
end

function ImGui.IsItemToggledOpen()
    return false
end

function ImGui.IsAnyItemHovered()
    return false
end

function ImGui.IsAnyItemActive()
    return false
end

function ImGui.IsAnyItemFocused()
    return false
end

function ImGui.GetItemRectMin()
    return 0, 0
end

function ImGui.GetItemRectMax()
    return 100, 20
end

function ImGui.GetItemRectSize()
    return 100, 20
end

function ImGui.SetItemAllowOverlap()
end

-- ============================================================================
-- Mouse & Input Functions
-- ============================================================================

function ImGui.GetMousePos()
    return 0, 0
end

function ImGui.GetMousePosOnOpeningCurrentPopup()
    return 0, 0
end

function ImGui.IsMouseDragging(button, lock_threshold)
    return false
end

function ImGui.GetMouseDragDelta(button, lock_threshold)
    return 0, 0
end

function ImGui.ResetMouseDragDelta(button)
end

function ImGui.IsMouseDown(button)
    return false
end

function ImGui.IsMouseHoveringRect(min_x, min_y, max_x, max_y, clip)
    return false
end

function ImGui.IsKeyDown(key)
    return false
end

function ImGui.IsAnyItemActive()
    return false
end

function ImGui.SetKeyboardFocusHere(offset)
end

-- ============================================================================
-- Clipboard Functions
-- ============================================================================

function ImGui.GetClipboardText()
    return ""
end

function ImGui.SetClipboardText(text)
end

-- ============================================================================
-- Global Query Functions
-- ============================================================================

function ImGui.GetTime()
    return 0
end

function ImGui.GetFrameCount()
    return 0
end

function ImGui.GetBackgroundDrawList()
    return ImGui._mockDrawList
end

function ImGui.GetForegroundDrawList()
    return ImGui._mockDrawList
end

function ImGui.GetStyle()
    return ImGuiStyle
end

function ImGui.GetStyleColorName(idx)
    return "Unknown"
end

function ImGui.GetStyleColorVec4(idx)
    return 1, 1, 1, 1
end

function ImGui.IsRectVisible(sizeX, sizeY)
    return true
end

function ImGui.IsRectVisible2(minX, minY, maxX, maxY)
    return true
end

-- ============================================================================
-- Measurement Functions
-- ============================================================================

function ImGui.GetTextLineHeight()
    return 14
end

function ImGui.GetTextLineHeightWithSpacing()
    return 18
end

function ImGui.GetFrameHeight()
    return 20
end

function ImGui.GetFrameHeightWithSpacing()
    return 24
end

function ImGui.GetContentRegionAvail()
    return 400, 300
end

function ImGui.GetContentRegionMax()
    return 400, 300
end

function ImGui.GetWindowContentRegionMin()
    return 0, 0
end

function ImGui.GetWindowContentRegionMax()
    return 800, 600
end

function ImGui.GetWindowContentRegionWidth()
    return 800
end

function ImGui.GetFontSize()
    return 14
end

function ImGui.GetFont()
    return nil
end

function ImGui.GetFontTexUvWhitePixel()
    return 0, 0
end

function ImGui.GetColorU32(idx_or_r, alphaMul_or_g, b, a)
    return 0xFFFFFFFF
end

function ImGui.GetColumnIndex()
    return 0
end

function ImGui.GetColumnWidth(column_index)
    return 100
end

function ImGui.SetColumnWidth(column_index, width)
end

function ImGui.GetColumnOffset(column_index)
    return 0
end

function ImGui.SetColumnOffset(column_index, offset_x)
end

function ImGui.GetColumnsCount()
    return 1
end

function ImGui.GetTreeNodeToLabelSpacing()
    return 20
end

-- ============================================================================
-- Scroll Functions
-- ============================================================================

function ImGui.GetScrollX()
    return 0
end

function ImGui.GetScrollY()
    return 0
end

function ImGui.GetScrollMaxX()
    return 0
end

function ImGui.GetScrollMaxY()
    return 0
end

function ImGui.SetScrollX(scrollX)
end

function ImGui.SetScrollY(scrollY)
end

function ImGui.SetScrollHereX(centerXRatio)
end

function ImGui.SetScrollHereY(centerYRatio)
end

function ImGui.SetScrollFromPosX(localX, centerXRatio)
end

function ImGui.SetScrollFromPosY(localY, centerYRatio)
end

-- ============================================================================
-- ID Functions
-- ============================================================================

function ImGui.PushID(stringID_or_intID)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopID()
    ImGui._popCount = ImGui._popCount + 1
end

function ImGui.GetID(stringID)
    return 0
end

-- ============================================================================
-- Style Push/Pop Functions
-- ============================================================================

function ImGui.PushStyleColor(idx, col_or_r, g, b, a)
    ImGui._stylePushCount = ImGui._stylePushCount + 1
end

function ImGui.PopStyleColor(count)
    count = count or 1
    ImGui._stylePopCount = ImGui._stylePopCount + count
end

function ImGui.PushStyleVar(idx, val_or_x, y)
    ImGui._stylePushCount = ImGui._stylePushCount + 1
end

function ImGui.PopStyleVar(count)
    count = count or 1
    ImGui._stylePopCount = ImGui._stylePopCount + count
end

function ImGui.PushFont(font)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopFont()
    ImGui._popCount = ImGui._popCount + 1
end

function ImGui.PushAllowKeyboardFocus(allowKeyboardFocus)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopAllowKeyboardFocus()
    ImGui._popCount = ImGui._popCount + 1
end

function ImGui.PushButtonRepeat(repeat_val)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.PopButtonRepeat()
    ImGui._popCount = ImGui._popCount + 1
end

function ImGui.BeginDisabled(disabled)
    ImGui._pushCount = ImGui._pushCount + 1
end

function ImGui.EndDisabled()
    ImGui._popCount = ImGui._popCount + 1
end

-- ============================================================================
-- Column Functions (Legacy)
-- ============================================================================

function ImGui.Columns(count, id, border)
end

function ImGui.NextColumn()
end

function ImGui.GetColumnIndex()
    return 0
end

function ImGui.GetColumnWidth(column_index)
    return 100
end

function ImGui.SetColumnWidth(column_index, width)
end

function ImGui.GetColumnOffset(column_index)
    return 0
end

function ImGui.SetColumnOffset(column_index, offset_x)
end

function ImGui.GetColumnsCount()
    return 1
end

-- ============================================================================
-- ListBox Functions
-- ============================================================================

function ImGui.ListBox(label, current_item, items, items_count, height_in_items)
    return current_item, false
end

function ImGui.BeginListBox(label, sizeX, sizeY)
    return false
end

function ImGui.EndListBox()
end

-- ============================================================================
-- Value Display Functions
-- ============================================================================

function ImGui.Value(prefix, b_or_v, float_format)
end

-- ============================================================================
-- Child Frame Functions
-- ============================================================================

function ImGui.BeginChildFrame(id, sizeX, sizeY, flags)
    return false
end

function ImGui.EndChildFrame()
end

-- ============================================================================
-- Misc Functions
-- ============================================================================

function ImGui.AlignTextToFramePadding()
end

function ImGui.SetItemDefaultFocus()
end

function ImGui.GetStyleColorName(idx)
    return "Unknown"
end

function ImGui.GetStyleColorVec4(idx)
    return 1, 1, 1, 1
end

-- ============================================================================
-- Backward Compatibility Aliases
-- ============================================================================

-- Old-style color constants (used by some legacy code)
ImGui.Col_Text = ImGuiCol.Text
ImGui.Col_TextDisabled = ImGuiCol.TextDisabled
ImGui.Col_WindowBg = ImGuiCol.WindowBg
ImGui.Col_ChildBg = ImGuiCol.ChildBg
ImGui.Col_PopupBg = ImGuiCol.PopupBg
ImGui.Col_Border = ImGuiCol.Border
ImGui.Col_BorderShadow = ImGuiCol.BorderShadow
ImGui.Col_FrameBg = ImGuiCol.FrameBg
ImGui.Col_FrameBgHovered = ImGuiCol.FrameBgHovered
ImGui.Col_FrameBgActive = ImGuiCol.FrameBgActive
ImGui.Col_TitleBg = ImGuiCol.TitleBg
ImGui.Col_TitleBgActive = ImGuiCol.TitleBgActive
ImGui.Col_MenuBarBg = ImGuiCol.MenuBarBg
ImGui.Col_ScrollbarBg = ImGuiCol.ScrollbarBg
ImGui.Col_ScrollbarGrab = ImGuiCol.ScrollbarGrab
ImGui.Col_ScrollbarGrabHovered = ImGuiCol.ScrollbarGrabHovered
ImGui.Col_ScrollbarGrabActive = ImGuiCol.ScrollbarGrabActive
ImGui.Col_CheckMark = ImGuiCol.CheckMark
ImGui.Col_SliderGrab = ImGuiCol.SliderGrab
ImGui.Col_SliderGrabActive = ImGuiCol.SliderGrabActive
ImGui.Col_Button = ImGuiCol.Button
ImGui.Col_ButtonHovered = ImGuiCol.ButtonHovered
ImGui.Col_ButtonActive = ImGuiCol.ButtonActive
ImGui.Col_Header = ImGuiCol.Header
ImGui.Col_HeaderHovered = ImGuiCol.HeaderHovered
ImGui.Col_HeaderActive = ImGuiCol.HeaderActive
ImGui.Col_Separator = ImGuiCol.Separator
ImGui.Col_SeparatorHovered = ImGuiCol.SeparatorHovered
ImGui.Col_SeparatorActive = ImGuiCol.SeparatorActive
ImGui.Col_ResizeGrip = ImGuiCol.ResizeGrip
ImGui.Col_ResizeGripHovered = ImGuiCol.ResizeGripHovered
ImGui.Col_ResizeGripActive = ImGuiCol.ResizeGripActive
ImGui.Col_Tab = ImGuiCol.Tab
ImGui.Col_TabHovered = ImGuiCol.TabHovered
ImGui.Col_TabActive = ImGuiCol.TabActive
ImGui.Col_TabUnfocused = ImGuiCol.TabUnfocused
ImGui.Col_TabUnfocusedActive = ImGuiCol.TabUnfocusedActive
ImGui.Col_PlotLines = ImGuiCol.PlotLines
ImGui.Col_PlotLinesHovered = ImGuiCol.PlotLinesHovered
ImGui.Col_PlotHistogram = ImGuiCol.PlotHistogram
ImGui.Col_PlotHistogramHovered = ImGuiCol.PlotHistogramHovered
ImGui.Col_TableHeaderBg = ImGuiCol.TableHeaderBg
ImGui.Col_TableBorderStrong = ImGuiCol.TableBorderStrong
ImGui.Col_TableBorderLight = ImGuiCol.TableBorderLight
ImGui.Col_TableRowBg = ImGuiCol.TableRowBg
ImGui.Col_TableRowBgAlt = ImGuiCol.TableRowBgAlt
ImGui.Col_TextSelectedBg = ImGuiCol.TextSelectedBg
ImGui.Col_DragDropTarget = ImGuiCol.DragDropTarget
ImGui.Col_NavHighlight = ImGuiCol.NavHighlight
ImGui.Col_NavWindowingHighlight = ImGuiCol.NavWindowingHighlight
ImGui.Col_NavWindowingDimBg = ImGuiCol.NavWindowingDimBg
ImGui.Col_ModalWindowDimBg = ImGuiCol.ModalWindowDimBg

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

-- --- Plot functions ---

function ImGui.PlotLines(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
end

function ImGui.PlotHistogram(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
end

-- --- Measurement functions ---

function ImGui.GetTextLineHeight()
    return 14
end

function ImGui.GetTextLineHeightWithSpacing()
    return 18
end

function ImGui.GetFrameHeight()
    return 20
end

function ImGui.GetFrameHeightWithSpacing()
    return 24
end

function ImGui.GetContentRegionAvailWidth()
    return 400
end

function ImGui.GetWindowWidth()
    return 600
end

function ImGui.GetWindowHeight()
    return 400
end

-- --- Interaction functions ---

function ImGui.IsItemClicked()
    return false
end

function ImGui.IsItemHovered()
    return false
end

function ImGui.IsItemActive()
    return false
end

function ImGui.IsItemDeactivated()
    return false
end

-- --- Style functions ---

-- PushStyleColor can be called as:
--   PushStyleColor(idx, color) -- single color table
--   PushStyleColor(idx, r, g, b, a) -- individual components
function ImGui.PushStyleColor(idx, r, g, b, a)
    ImGui._stylePushCount = ImGui._stylePushCount + 1
end

function ImGui.PopStyleColor(count)
    count = count or 1
    ImGui._stylePopCount = ImGui._stylePopCount + count
end

-- PushStyleVar can be called as:
--   PushStyleVar(idx, val) -- single value
--   PushStyleVar(idx, x, y) -- 2D value (for WindowPadding, etc.)
function ImGui.PushStyleVar(idx, x, y)
    ImGui._stylePushCount = ImGui._stylePushCount + 1
end

function ImGui.PopStyleVar(count)
    count = count or 1
    ImGui._stylePopCount = ImGui._stylePopCount + count
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

-- Mock draw list (flat float args — matches CET's sol2 bindings)
ImGui._mockDrawList = "mock_drawlist userdata"

function ImGui.ImDrawListAddLine(drawList, p1X, p1Y, p2X, p2Y, color, thickness) end
function ImGui.ImDrawListAddRect(drawList, p_minX, p_minY, p_maxX, p_maxY, color, rounding, flags, thickness) end
function ImGui.ImDrawListAddRectFilled(drawList, p_minX, p_minY, p_maxX, p_maxY, color, rounding, flags) end
function ImGui.ImDrawListAddCircle(drawList, centerX, centerY, radius, color, num_segments, thickness) end
function ImGui.ImDrawListAddCircleFilled(drawList, centerX, centerY, radius, color, num_segments) end
function ImGui.ImDrawListAddText(drawList, posX, posY, color, text, wrap_width) end
function ImGui.ImDrawListAddTextWrapped(drawList, pos, color, text, wrap_width) end
function ImGui.ImDrawListAddImage(drawList, texture_id, p_min, p_max, uv_min, uv_max, tint_col) end
function ImGui.ImDrawListAddBezierCubic(drawList, p1, p2, p3, p4, color, thickness, num_segments) end

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

function ImGui.IsKeyDown(key)
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

-- --- ImGuiKey enum (for IsKeyDown) ---

ImGuiKey = {
    LeftShift = 340,
    RightShift = 344,
    LeftCtrl = 341,
    RightCtrl = 345,
    LeftAlt = 342,
    RightAlt = 346,
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