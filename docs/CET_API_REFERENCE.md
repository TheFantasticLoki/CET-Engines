# CET API Reference — AI Agent Quick Reference

> **Purpose**: Comprehensive reference of the Cyber Engine Tweaks (CET) Lua API surface,
> compiled from the type definition libraries in `dependencies/lua-libs/`.
> This document is auto-loaded by `AGENTS.md` to educate AI agents about CET modding.

---

## Table of Contents

1. [CET Version & Constraints](#cet-version--constraints)
2. [Event System (Lifecycle)](#event-system-lifecycle)
3. [Observer & Override System](#observer--override-system)
4. [CET Utility Functions](#cet-utility-functions)
5. [Logging (spdlog)](#logging-spdlog)
6. [TweakDB API](#tweakdb-api)
7. [GameOptions API](#gameoptions-api)
8. [Entity Spawning](#entity-spawning)
9. [Game Singleton (ScriptGameInstance)](#game-singleton)
10. [Core Value Types](#core-value-types)
11. [LuaJIT bit32 Library](#luajit-bit32-library)
12. [ImGui API (CET Bindings)](#imgui-api-cet-bindings)
13. [Icon Glyphs](#icon-glyphs)
14. [Type System Overview](#type-system-overview)
15. [Common Patterns](#common-patterns)

---

## CET Version & Constraints

- **CET Version**: 1.27.1
- **Game Version**: Cyberpunk 2077 v2.01
- **Lua Runtime**: LuaJIT (Lua 5.1 compatible)
- **Sandbox**: CET sandboxes the Lua environment — no `_G`, no `io`, no `os` (except `os.clock`, `os.date`, `os.difftime`, `os.time`)

### Lua 5.1 Hard Constraints

| Rule | Details |
|------|---------|
| No `goto` | Lua 5.2+ only — use `if/elseif/else` or early returns |
| No `__gc` | Cannot use `__gc` in metatables |
| No `table.pack` / `table.unpack` | Lua 5.2+ — use manual table construction or `select()` |
| No `bit32` built-in | Must use `bit32` from `dependencies/lua-libs/` (LuaJIT provides it) |
| `_G` not exposed | CET sandbox doesn't expose `_G` — use direct global assignment |
| `GetMod()` timing | Can only call AFTER `registerForEvent('onInit', ...)` is registered |

---

## Event System (Lifecycle)

CET mods register callbacks for lifecycle events. All callbacks are registered via `registerForEvent`.

```lua
registerForEvent(event: string, callback: function)
```

### Available Events

| Event | Callback Signature | When It Fires |
|-------|-------------------|---------------|
| `onInit` | `function()` | Mod loaded, all mods available for `GetMod()` |
| `onShutdown` | `function()` | Mod being unloaded |
| `onUpdate` | `function(delta: number)` | Every frame — `delta` is seconds since last frame |
| `onDraw` | `function()` | Every frame during overlay draw — ALL ImGui calls go here |
| `onOverlayOpen` | `function()` | CET overlay (F2) opened |
| `onOverlayClose` | `function()` | CET overlay (F2) closed |

### Handler Type Aliases

```lua
---@alias CETEventHandler fun(): void | fun(delta: number): void
---@alias CETHotkeyHandler fun(): void
---@alias CETInputHandler fun(isDown: boolean): void
```

### Hotkey & Input Registration

```lua
registerHotkey(id: string, description: string, callback: function)  -- keyboard hotkey
registerInput(id: string, description: string, callback: function)   -- input action (gets isDown bool)
IsBound(id: string) -> boolean                                        -- check if input is bound
GetBind(id: string) -> string                                         -- get key binding string
```

---

## Observer & Override System

Hook into Redscript (game) functions at runtime. All return a `string` handle for cleanup.

```lua
-- Hook AFTER a method runs (get return value, modify if needed)
Observe(typeName: string, funcName: string, callback: function) -> string

-- Hook BEFORE a method runs
ObserveBefore(typeName: string, funcName: string, callback: function) -> string

-- Hook AFTER a method runs
ObserveAfter(typeName: string, funcName: string, callback: function) -> string

-- Replace a method entirely (callback must return the original return value)
Override(typeName: string, funcName: string, callback: function) -> string
```

### Callback Patterns

```lua
-- Observe/ObserveAfter: receive the same args as the original function
Observe("PlayerPuppet", "OnAction", function(self, action)
    spdlog.info("Player action: " .. dump(action))
end)

-- ObserveBefore: runs before the original
ObserveBefore("PlayerPuppet", "OnAction", function(self, action)
    -- can modify state before original runs
end)

-- Override: must return original return value
Override("PlayerPuppet", "OnAction", function(self, action)
    local result = Game.PlayerPuppet.OnAction(self, action)
    spdlog.info("Overrode OnAction")
    return result  -- must return what original returned
end)
```

---

## CET Utility Functions

```lua
-- Object creation & singletons
NewObject(typeName: string) -> T           -- Create new Redscript object
GetSingleton(typeName: string) -> T        -- Get singleton instance

-- Cross-mod communication
GetMod(name: string) -> any               -- Get reference to another CET mod (use in onInit only)

-- Version & display
GetVersion() -> string                     -- CET version string
GetDisplayResolution() -> number, number   -- Screen width, height

-- Debugging
GameDump(object: any) -> any              -- Deep dump game object to string
Dump(object: any, detailed: boolean) -> any   -- Dump any object
DumpType(name: string, detailed: boolean) -> any  -- Dump a type definition
DumpAllTypeNames()                         -- Print all registered type names

-- Filesystem (sandboxed)
dir(path: string) -> table                -- List directory contents
ModArchiveExists(name: string) -> boolean  -- Check if mod archive exists
```

---

## Logging (spdlog)

Global `spdlog` object with standard log levels:

```lua
spdlog.trace(message: string)
spdlog.debug(message: string)
spdlog.info(message: string)
spdlog.warning(message: string)
spdlog.error(message: string)
spdlog.critical(message: string)
```

**Game-side logging** (via `Game` global):

```lua
Game.Log(message)
Game.LogError(message)
Game.LogWarning(message)
Game.LogChannel(channel, message)
Game.FTLog(message)       -- File + trace log
Game.FTLogError(message)
Game.FTLogWarning(message)
```

---

## TweakDB API

Full CRUD on the game's database (TweakDB). All methods available on the `TweakDB` global.

### Record Operations

```lua
TweakDB:GetRecords(recordType: string) -> table          -- All records of a type
TweakDB:GetRecord(path_or_id) -> userdata                -- Single record (string path or TweakDBID)
TweakDB:Query(path_or_id) -> userdata                    -- Query by path/ID
TweakDB:CreateRecord(path: string, recordType: string) -> boolean
TweakDB:CloneRecord(path: string, clonedPath_or_id) -> boolean
TweakDB:DeleteRecord(path: string) -> boolean
```

### Flat Value Operations

```lua
TweakDB:GetFlat(flatPath_or_id) -> boolean               -- Get a flat value
TweakDB:SetFlat(flatPath_or_id, flatData) -> boolean     -- Set + auto-update
TweakDB:SetFlatNoUpdate(flatPath_or_id, flatData) -> boolean  -- Set without update
TweakDB:SetFlats(recordID, recordData: table) -> boolean -- Set multiple flats at once
TweakDB:Update(recordPath_or_id_or_record) -> boolean    -- Force record update
```

---

## GameOptions API

Runtime manipulation of game engine options.

```lua
GameOptions.Print(category: string, name: string)
GameOptions.Get(category: string, name: string) -> string
GameOptions.GetBool(category: string, name: string) -> boolean
GameOptions.GetInt(category: string, name: string) -> int
GameOptions.GetFloat(category: string, name: string) -> float
GameOptions.Set(category: string, name: string, value: string)
GameOptions.SetBool(category: string, name: string, value: boolean)
GameOptions.SetInt(category: string, name: string, value: int)
GameOptions.SetFloat(category: string, name: string, value: float)
GameOptions.Toggle(category: string, name: string)
GameOptions.List(category: string)
GameOptions.Dump()
```

---

## Entity Spawning

```lua
exEntitySpawner.SpawnRecord(recordID, transform, [appearance]) -> entEntityID
exEntitySpawner.Spawn(entityPath, transform, [appearance, [recordID]]) -> entEntityID
exEntitySpawner.Despawn(entity)
```

### World Functional Tests

```lua
WorldFunctionalTests.SpawnEntity(entityPath, transform, unknown) -> entEntityID
WorldFunctionalTests.DespawnEntity(entity)
```

---

## Game Singleton

The `Game` global is an instance of `ScriptGameInstance`. Every method is also available as a top-level global function.

```lua
Game.SomeFunc(args...)  -- or just SomeFunc(args...) as a global
```

### Math Functions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `Abs(a)` | `int -> int` | Absolute value |
| `AbsF(a)` | `float -> float` | Absolute value (float) |
| `Clamp(v, min, max)` | `int -> int` | Clamp integer |
| `ClampF(v, min, max)` | `float -> float` | Clamp float |
| `LerpF(alpha, a, b, clamp?)` | `float -> float` | Linear interpolation |
| `Min(a, b)` | `int -> int` | Minimum |
| `MinF(a, b)` | `float -> float` | Minimum (float) |
| `Max(a, b)` | `int -> int` | Maximum |
| `MaxF(a, b)` | `float -> float` | Maximum (float) |
| `FloorF(a)` | `float -> float` | Floor |
| `CeilF(a)` | `float -> float` | Ceiling |
| `SqrtF(a)` | `float -> float` | Square root |
| `SinF(a)` | `float -> float` | Sine |
| `CosF(a)` | `float -> float` | Cosine |
| `TanF(a)` | `float -> float` | Tangent |
| `AcosF(a)` | `float -> float` | Arc cosine |
| `AsinF(a)` | `float -> float` | Arc sine |
| `AtanF(a, b?)` | `float -> float` | Arc tangent |
| `Deg2Rad(deg)` | `float -> float` | Degrees to radians |
| `Rad2Deg(rad)` | `float -> float` | Radians to degrees |
| `AngleApproach(target, cur, step)` | `float -> float` | Angle approach |
| `AngleDistance(target, current)` | `float -> float` | Angle distance |
| `AngleNormalize(a)` | `float -> float` | Normalize angle [0, 360) |
| `AngleNormalize180(a)` | `float -> float` | Normalize angle [-180, 180) |
| `WrapF(min, max, val)` | `float -> float` | Wrap float in range |
| `ExpF(a)` | `float -> float` | Exponential |
| `LogF(a)` | `float -> float` | Logarithm |

### String Conversion

```lua
Game.BoolToString(value) -> String
Game.FloatToString(value) -> String
Game.FloatToStringPrec(value, precision) -> String
Game.IntToString(value) -> String
Game.NameToString(name) -> String
Game.LocKeyToString(hashKey) -> String
Game.NoTrailZeros(value) -> String
Game.IsStringNumber(str) -> Bool
Game.IsStringValid(str) -> Bool
```

### Localization

```lua
Game.GetLocalizedText(textKey: string) -> String
Game.GetLocalizedTextByKey(hashKey) -> String
Game.GetLocalizedItemNameByCName(cname) -> String
Game.GetLocalizedItemNameByString(str) -> String
Game.GetLocalizedTextGanderDepened(textKey, isFemale) -> String
```

### Enum Utilities

```lua
Game.EnumGetMax(type) -> Int64
Game.EnumGetMin(type) -> Int64
Game.EnumValueFromName(enumName, enumValue) -> Int64
Game.EnumValueToName(enumName, enumValue) -> CName
Game.EnumValueFromString(enumName, strValue) -> Int64
Game.EnumValueToString(enumName, enumValue) -> String
```

### Type Casting (`Game.Cast`)

Massively overloaded — dozens of type-to-type conversions:

```lua
-- Numeric conversions
Game.Cast(value, 'Int8')   -- any numeric -> Int8
Game.Cast(value, 'Int32')  -- any numeric -> Int32
Game.Cast(value, 'Float')  -- any numeric -> Float
Game.Cast(value, 'Bool')   -- any numeric -> Bool

-- Entity ID conversions
Game.Cast(entEntityID, 'gamePersistentID')
Game.Cast(entEntityID, 'gameStatsObjectID')

-- Math conversions
Game.Cast(vector4, 'Vector3')   -- Vector4 -> Vector3
Game.Cast(vector3, 'Vector4')   -- Vector3 -> Vector4
```

### State Queries

```lua
Game.IsClient() -> Bool
Game.IsServer() -> Bool
Game.IsHost() -> Bool
Game.IsSingleplayer() -> Bool
Game.IsMultiplayer() -> Bool
Game.IsFinal() -> Bool
Game.IsEP1() -> Bool                              -- Phantom Liberty
Game.IsNameValid(name) -> Bool
Game.IsStringValid(str) -> Bool
Game.IsEntityInInteriorArea(entity) -> Bool
Game.IsLanguageVoicePackInstalled(lang) -> Bool
Game.IsNoInputIconsModeEnabled() -> Bool
```

### Logging Functions (Game global)

```lua
Game.Log(message)
Game.LogError(message)
Game.LogWarning(message)
Game.LogChannel(channel, message)
Game.LogChannelError(channel, message)
Game.LogChannelWarning(channel, message)
Game.FTLog(message)
Game.FTLogError(message)
Game.FTLogWarning(message)
```

---

## Core Value Types

All constructed via `TypeName.new()` or `ToTypeName(props_table)`.

### Primitives

| Type | Fields | Constructor | Notes |
|------|--------|-------------|-------|
| `CName` | `value: string`, `hash_lo: Uint32`, `hash_hi: Uint32` | `CName.new(name)`, `CName.new(hash)`, `CName.new(hashLo, hashHi)` | Cached string hash |
| `TweakDBID` | `hash: Uint32`, `length: Uint8` | `TweakDBID.new(name)`, `TweakDBID.new(base, name)`, `TweakDBID.new(hash, length)` | Database record ID |
| `ItemID` | `id: TweakDBID`, `rng_seed: Uint32`, `unknown: Uint16`, `maybe_type: Uint8` | `ItemID.new(id[, rngSeed[, unknown[, maybeType]]])` | Item instance |
| `CRUID` | `hash: Uint64` | `CRUID(hash)` | Content resource UID |
| `gamedataLocKeyWrapper` | `hash: Uint64` | `LocKey(hash)` | Localization key |

### Math Types

| Type | Fields | Constructor |
|------|--------|-------------|
| `Vector3` | `x, y, z: Float` | `Vector3.new(x, y, z)` or `Vector3.new(copy)` |
| `Vector4` | `x, y, z, w: Float` | `Vector4.new(x, y, z, w)` or `Vector4.new(copy)` |
| `EulerAngles` | `roll, pitch, yaw: Float` | `EulerAngles.new(roll, pitch, yaw)` or copy |
| `Quaternion` | `i, j, k, r: Float` | `Quaternion.new(i, j, k, r)` or copy |

### Conversion Functions

```lua
ToCName(props) -> CName
ToTweakDBID(props) -> TweakDBID
ToItemID(props) -> ItemID
ToVector3(props) -> Vector3
ToVector4(props) -> Vector4
ToEulerAngles(props) -> EulerAngles
ToQuaternion(props) -> Quaternion
```

### Utility Functions

```lua
ToVariant(value: any) -> Variant       -- Wrap any value as Variant
FromVariant(variant: Variant) -> any   -- Unwrap Variant
IsDefined(ref: any) -> boolean         -- Check if reference is valid
EnumInt(enum: any) -> number           -- Convert enum to integer
```

---

## LuaJIT bit32 Library

Since CET uses Lua 5.1, the `bit32` library must be loaded from `dependencies/lua-libs/`. All functions are on the global `bit32` table:

```lua
bit32.bnot(x) -> number            -- Bitwise NOT
bit32.band(...) -> number          -- Bitwise AND (variadic)
bit32.bor(...) -> number           -- Bitwise OR (variadic)
bit32.bxor(...) -> number          -- Bitwise XOR (variadic)
bit32.lshift(x, n) -> number      -- Left shift
bit32.rshift(x, n) -> number      -- Logical right shift
bit32.arshift(x, n) -> number     -- Arithmetic right shift
bit32.rol(x, n) -> number         -- Rotate left
bit32.ror(x, n) -> number         -- Rotate right
bit32.bswap(x) -> number          -- Byte swap
bit32.tobit(x) -> number          -- Normalize to 32-bit
bit32.tohex(x, n?) -> string      -- Convert to hex string
```

---

## ImGui API (CET Bindings)

CET exposes ImGui via a global `ImGui` table. All ImGui calls MUST be inside `onDraw` callback.
CET wraps ALL ImGui calls in a single pcall — do NOT wrap individual calls in pcall.

### ImGui Enums (Constants)

| Enum | Key Values |
|------|-----------|
| `ImGuiWindowFlags` | `None`, `NoTitleBar`, `NoResize`, `NoMove`, `AlwaysAutoResize`, `NoBackground`, `MenuBar`, `HorizontalScrollbar`, `NoNav` |
| `ImGuiCond` | `None`, `Always`, `Once`, `FirstUseEver`, `Appearing` |
| `ImGuiCol` | `Text`, `WindowBg`, `FrameBg`, `Button`, `Header`, `SliderGrab`, etc. (all ImGui color indices) |
| `ImGuiStyleVar` | `Alpha`, `WindowPadding`, `FrameRounding`, `ItemSpacing`, etc. |
| `ImGuiDir` | `None`, `Left`, `Right`, `Up`, `Down` |
| `ImGuiMouseButton` | `Left`, `Right`, `Middle` |
| `ImGuiFocusedFlags` | `ChildWindows`, `RootWindow`, `AnyWindow` |
| `ImGuiHoveredFlags` | `ChildWindows`, `RootWindow`, `AllowWhenBlockedByPopup`, `RectOnly` |
| `ImGuiInputTextFlags` | `CharsDecimal`, `Password`, `ReadOnly`, `CallbackResize` |
| `ImGuiSliderFlags` | `ClampOnInput`, `Logarithmic`, `NoRoundToFormat` |
| `ImGuiColorEditFlags` | `NoAlpha`, `DisplayRGB`, `PickerHueWheel` |
| `ImGuiTreeNodeFlags` | `Framed`, `DefaultOpen`, `Leaf`, `CollapsingHeader` |
| `ImGuiComboFlags` | `PopupAlignLeft`, `HeightSmall`, `NoArrowButton` |
| `ImGuiTableFlags` | `Resizable`, `Sortable`, `Borders`, `SizingFixedFit` |
| `ImGuiTabBarFlags` | `Reorderable`, `AutoSelectNewTabs` |
| `ImDrawFlags` | `Closed`, `RoundCornersAll` |
| `ImDrawCornerFlags` | `TopLeft`, `TopRight`, `BotLeft`, `BotRight`, `All` |

### Core Types

```lua
-- 2D vector
ImVec2.new(x?, y?) -> ImVec2
-- 4D vector (color RGBA)
ImVec4.new(x?, y?, z?, w?) -> ImVec4
-- Virtual scroll clipper
ImGuiListClipper.new() -> ImGuiListClipper
ImGuiListClipper:Begin(items_count, items_height?)
ImGuiListClipper:End()
ImGuiListClipper:Step()
-- Texture handle
ImguiTexture:Release()
```

### Window Management

```lua
ImGui.Begin(name, [flags], [open]) -> bool, [bool]    -- Returns (visible, [p_open])
ImGui.End()
ImGui.BeginChild(name, [sizeX, sizeY, border, flags]) -> bool
ImGui.EndChild()
ImGui.IsWindowAppearing() -> bool
ImGui.IsWindowCollapsed() -> bool
ImGui.IsWindowFocused([flags]) -> bool
ImGui.IsWindowHovered([flags]) -> bool
ImGui.GetWindowDrawList() -> ImDrawList
ImGui.GetWindowPos() -> float, float
ImGui.GetWindowSize() -> float, float
ImGui.GetWindowWidth() -> float
ImGui.GetWindowHeight() -> float
ImGui.SetNextWindowPos(posX, posY, [cond], [pivotX, pivotY])
ImGui.SetNextWindowSize(sizeX, sizeY, [cond])
ImGui.SetNextWindowSizeConstraints(minX, minY, maxX, maxY)
ImGui.SetNextWindowContentSize(sizeX, sizeY)
ImGui.SetNextWindowCollapsed(collapsed, [cond])
ImGui.SetNextWindowFocus()
ImGui.SetNextWindowBgAlpha(alpha)
ImGui.SetWindowPos(posX, posY, [cond], [name])
ImGui.SetWindowSize(sizeX, sizeY, [cond], [name])
ImGui.SetWindowCollapsed(collapsed, [cond], [name])
ImGui.SetWindowFocus([name])
ImGui.SetWindowFontScale(scale)
```

### Layout & Spacing

```lua
ImGui.Separator()
ImGui.SameLine([offsetFromStartX, spacing])
ImGui.NewLine()
ImGui.Spacing()
ImGui.Dummy(sizeX, sizeY)
ImGui.Indent([indentW])
ImGui.Unindent([indentW])
ImGui.BeginGroup()
ImGui.EndGroup()
ImGui.PushItemWidth(itemWidth)
ImGui.PopItemWidth()
ImGui.SetNextItemWidth(itemWidth)
ImGui.CalcItemWidth() -> float
ImGui.PushTextWrapPos([wrapLocalPosX])
ImGui.PopTextWrapPos()
ImGui.PushClipRect(min_x, min_y, max_x, max_y, intersect_current)
ImGui.PopClipRect()
```

### Cursor & Positioning

```lua
ImGui.GetCursorPos() -> float, float
ImGui.GetCursorPosX() -> float
ImGui.GetCursorPosY() -> float
ImGui.SetCursorPos(localX, localY)
ImGui.SetCursorPosX(localX)
ImGui.SetCursorPosY(localY)
ImGui.GetCursorStartPos() -> float, float
ImGui.GetCursorScreenPos() -> float, float
ImGui.SetCursorScreenPos(posX, posY)
```

### Text Display

```lua
ImGui.Text(text)
ImGui.TextUnformatted(text)
ImGui.TextColored(colR, colG, colB, colA, text)
ImGui.TextDisabled(text)
ImGui.TextWrapped(text)
ImGui.LabelText(label, text)
ImGui.BulletText(text)
ImGui.CalcTextSize(text, [hide_text_after_double_hash], [wrap_width]) -> float, float
```

### Interactive Widgets

```lua
ImGui.Button(label, [sizeX, sizeY]) -> bool
ImGui.SmallButton(label) -> bool
ImGui.InvisibleButton(stringID, sizeX, sizeY) -> bool
ImGui.ArrowButton(stringID, dir) -> bool
ImGui.Checkbox(label, v) -> bool, bool                          -- Returns (clicked, new_value)
ImGui.RadioButton(label, active, [vButton]) -> int, bool
ImGui.ProgressBar(fraction, [sizeX, sizeY, overlay])
ImGui.Bullet()
ImGui.Selectable(label, [selected, flags, sizeX, sizeY]) -> bool
```

### Combo Boxes

```lua
ImGui.BeginCombo(label, previewValue, [flags]) -> bool
ImGui.EndCombo()
ImGui.Combo(label, currentItem, items, [itemsCount_or_popupMaxHeightInItems]) -> int, bool
```

### Sliders, Drags & Inputs

```lua
-- Drag (value follows mouse when held)
ImGui.DragFloat(label, v, [v_speed, v_min, v_max, format, flags]) -> bool, float
ImGui.DragFloat2(label, v, ...) -> bool, float[]
ImGui.DragFloat3(label, v, ...) -> bool, float[]
ImGui.DragFloat4(label, v, ...) -> bool, float[]
ImGui.DragInt(label, v, ...) -> bool, int
ImGui.DragInt2/3/4(...)

-- Slider (fixed range)
ImGui.SliderFloat(label, v, v_min, v_max, [format, flags]) -> bool, float
ImGui.SliderFloat2/3/4(...)
ImGui.SliderAngle(label, v, [v_degrees_min, v_degrees_max, format, flags]) -> bool, float
ImGui.SliderInt(label, v, v_min, v_max, [format, flags]) -> bool, int
ImGui.SliderInt2/3/4(...)

-- Vertical slider
ImGui.VSliderFloat(label, sizeX, sizeY, v, v_min, v_max, [format, flags]) -> bool, float
ImGui.VSliderInt(...)

-- Text input
ImGui.InputText(label, buf, [buf_size, flags, callback, user_data]) -> bool, string
ImGui.InputTextMultiline(label, buf, [buf_size, sizeX, sizeY, flags, callback, user_data]) -> bool, string
ImGui.InputTextWithHint(label, hint, buf, [buf_size, flags, callback, user_data]) -> bool, string

-- Numeric input
ImGui.InputFloat(label, v, [step, step_fast, format, flags]) -> bool, float
ImGui.InputFloat2/3/4(...)
ImGui.InputInt(label, v, [step, step_fast, flags]) -> bool, int
ImGui.InputInt2/3/4(...)
ImGui.InputDouble(label, v, [step, step_fast, format, flags]) -> bool, double
```

### Color Widgets

```lua
ImGui.ColorEdit3(label, col, [flags]) -> float[], bool
ImGui.ColorEdit4(label, col, [flags]) -> float[], bool
ImGui.ColorPicker3(label, col, [flags]) -> float[], bool
ImGui.ColorPicker4(label, col, [flags]) -> float[], bool
ImGui.ColorButton(desc_id, col, [flags, sizeX, sizeY]) -> bool
ImGui.SetColorEditOptions(flags)
ImGui.ColorConvertU32ToFloat4(in) -> float[]
ImGui.ColorConvertFloat4ToU32(rgba) -> int
ImGui.ColorConvertRGBtoHSV(r, g, b) -> float, float, float
ImGui.ColorConvertHSVtoRGB(h, s, v) -> float, float, float
```

### Trees & Nodes

```lua
ImGui.TreeNode(label, [fmt]) -> bool
ImGui.TreeNodeEx(label, [flags, fmt]) -> bool
ImGui.TreePush(str_id)
ImGui.TreePop()
ImGui.GetTreeNodeToLabelSpacing() -> float
ImGui.CollapsingHeader(label, [flags], [open]) -> bool, [bool]
ImGui.SetNextItemOpen(is_open, [cond])
```

### Tab Bars & Tabs

```lua
ImGui.BeginTabBar(str_id, [flags]) -> bool
ImGui.EndTabBar()
ImGui.BeginTabItem(label, [flags, open]) -> bool, [bool]
ImGui.EndTabItem()
ImGui.SetTabItemClosed(tab_or_docked_window_label)
```

### Tables

```lua
ImGui.BeginTable(str_id, columns, [flags, outer_sizeX, outer_sizeY, inner_width]) -> bool
ImGui.EndTable()
ImGui.TableNextRow([flags, min_row_height]) -> bool
ImGui.TableNextColumn() -> bool
ImGui.TableSetColumnIndex(column_n) -> bool
ImGui.TableSetupColumn(label, [flags, init_width_or_weight, user_id])
ImGui.TableSetupScrollFreeze(cols, rows)
ImGui.TableHeadersRow()
ImGui.TableHeader(label)
ImGui.TableGetSortSpecs() -> ImGuiTableSortSpecs
ImGui.TableGetColumnName([column_n]) -> string
ImGui.TableSetBgColor(target, color, [column_n])
```

### Menus, Popups & Tooltips

```lua
ImGui.BeginMenuBar() / ImGui.EndMenuBar()
ImGui.BeginMainMenuBar() / ImGui.EndMainMenuBar()
ImGui.BeginMenu(label, [enabled]) / ImGui.EndMenu()
ImGui.MenuItem(label, [shortcut, selected, enabled]) -> bool, [bool]
ImGui.BeginTooltip() / ImGui.EndTooltip()
ImGui.SetTooltip(fmt)
ImGui.BeginPopup(str_id, [flags]) / ImGui.EndPopup()
ImGui.BeginPopupModal(name, [flags, open]) / ImGui.EndPopup()
ImGui.OpenPopup(str_id, [popup_flags])
ImGui.CloseCurrentPopup()
```

### Drawing (ImDrawList)

```lua
ImGui.ImDrawListAddLine(drawlist, p1X, p1Y, p2X, p2Y, col, [thickness])
ImGui.ImDrawListAddRect(drawlist, p_minX, p_minY, p_maxX, p_maxY, col, [rounding, flags, thickness])
ImGui.ImDrawListAddRectFilled(drawlist, p_minX, p_minY, p_maxX, p_maxY, col, [rounding, flags])
ImGui.ImDrawListAddCircle(drawlist, centerX, centerY, radius, col, [num_segments, thickness])
ImGui.ImDrawListAddCircleFilled(drawlist, centerX, centerY, radius, col, [num_segments])
ImGui.ImDrawListAddText(drawlist, [font_size,] posX, posY, col, text_begin, [wrap_width])
ImGui.ImDrawListAddBezierCubic(drawlist, ...)
ImGui.ImDrawListAddBezierQuadratic(drawlist, ...)
ImGui.ImDrawListAddTriangle(drawlist, ...)
ImGui.ImDrawListAddQuad(drawlist, ...)
```

### Images & Textures

```lua
ImGui.LoadTexture(path: string) -> ImguiTexture
ImGui.Image(texture, [size, uv0, uv1, tint_col, border_col])
```

### Item State Queries

```lua
ImGui.IsItemHovered([flags]) -> bool
ImGui.IsItemActive() -> bool
ImGui.IsItemFocused() -> bool
ImGui.IsItemClicked([target]) -> bool
ImGui.IsItemVisible() -> bool
ImGui.IsItemEdited() -> bool
ImGui.IsItemActivated() -> bool
ImGui.IsItemDeactivated() -> bool
ImGui.GetItemRectMin() -> float, float
ImGui.GetItemRectMax() -> float, float
ImGui.GetItemRectSize() -> float, float
```

### Mouse & Clipboard

```lua
ImGui.GetMousePos() -> float, float
ImGui.IsMouseDragging(button, [lock_threshold]) -> bool
ImGui.GetClipboardText() -> string
ImGui.SetClipboardText(text)
```

### Global Query

```lua
ImGui.GetTime() -> double
ImGui.GetFrameCount() -> int
ImGui.GetBackgroundDrawList() -> ImDrawList
ImGui.GetForegroundDrawList() -> ImDrawList
ImGui.GetStyle() -> ImGuiStyle
ImGui.IsRectVisible(sizeX, sizeY) -> bool
ImGui.IsRectVisible(minX, minY, maxX, maxY) -> bool
```

---

## Icon Glyphs

The `IconGlyphs` table provides Material Design icon constants for use in ImGui text:

```lua
-- Usage: ImGui.Text(IconGlyphs.Account .. " My Account")
-- Each icon is a Unicode escape sequence string

IconGlyphs.Account           -- \u{f0004}
IconGlyphs.AccountAlert      -- \u{f0005}
IconGlyphs.AccountBox        -- \u{f0006}
IconGlyphs.AccountCircle     -- \u{f0008}
IconGlyphs.Settings          -- \u{f08ba}
IconGlyphs.Search            -- \u{f0876}
-- ... thousands more
```

---

## Type System Overview

The type definitions library provides EmmyLua annotations (`---@meta`, `---@class`, `---@field`, `---@param`, `---@return`, `---@alias`) for IDE autocompletion.

### Library Structure

| Library | Structure | Purpose |
|---------|-----------|---------|
| `CET_ImGui_lua_type_defines` | 1 file per concern | ImGui bindings + icons |
| `cet-lua-a` | Flat files + per-class/enum files | Granular type definitions (5000+ class files) |
| `cet-lua-b` | Monolithic files | Same API surface, consolidated (fewer files) |

### Key Categories in Type Definitions

- **5000+ class files**: Every Redscript type with fields, methods, constructors
- **1000+ enum files**: Named integer values for game enums
- **25 bitfield files**: Bitmask flag constants
- **2000+ alias entries**: Short names mapped to full `gamedata*` types

### Most Important Game Classes

| Class | Purpose |
|-------|---------|
| `PlayerPuppet` / `NPCPuppet` / `ScriptedPuppet` | Player and NPC entities |
| `gameObject` / `entEntity` / `entGameEntity` | Base entity types |
| `inkWidget` / `inkTextWidget` / `inkImageWidget` | UI widget hierarchy |
| `inkGameController` / `inkMenuLogicController` | UI controller hierarchy |
| `gameBlackboardSystem` | Blackboard data access |
| `gameStatsSystem` | Stats/combat system |
| `gameInventoryManager` | Inventory management |
| `gameTimeSystem` | In-game time |
| `gameEffectSystem` | VFX/effects |
| `gameJournalManager` | Quest journal |

---

## Common Patterns

### Standard Mod Structure

```lua
local M = {}

function M.init()
    -- Register for CET events
    registerForEvent("onInit", function()
        -- Safe to call GetMod() here
        local otherMod = GetMod("SomeOtherMod")
        spdlog.info("MyMod initialized")
    end)

    registerForEvent("onDraw", function()
        -- All ImGui calls go here, wrapped in a single scope
        ImGui.Begin("My Window")
        -- ... ImGui calls ...
        ImGui.End()
    end)

    registerForEvent("onShutdown", function()
        -- Cleanup
    end)
end

return M
```

### ImGui Theme Push/Pop Pattern

```lua
registerForEvent("onDraw", function()
    -- Push colors before use
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, a)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, x, y)

    ImGui.Begin("Window")
    -- ... widgets ...
    ImGui.End()

    -- MUST match push/pop counts
    ImGui.PopStyleVar(1)
    ImGui.PopStyleColor(1)
end)
```

### Observer Pattern for Game Hooking

```lua
registerForEvent("onInit", function()
    -- Hook a game function
    Observe("PlayerPuppet", "OnAction", function(self, action)
        spdlog.info("Player action observed")
    end)

    -- Hook before a function
    ObserveBefore("PlayerPuppet", "OnHit", function(self, hitEvent)
        -- Can modify state before original
    end)

    -- Override a function completely
    Override("SomeClass", "SomeMethod", function(self, arg1)
        local result = Game.SomeClass.SomeMethod(self, arg1)
        -- post-processing
        return result  -- must return original return type
    end)
end)
```

### TweakDB Record Modification

```lua
registerForEvent("onInit", function()
    -- Read a record
    local record = TweakDB:GetRecord("Items.QianTMark3")
    local value = TweakDB:GetFlat("Items.QianTMark3.description")

    -- Modify a record
    TweakDB:SetFlat("Items.QianTMark3.description", "Custom description")
    TweakDB:Update("Items.QianTMark3")

    -- Create a new record
    TweakDB:CreateRecord("MyMod.Items.MyItem", "Item")
    TweakDB:SetFlats("MyMod.Items.MyItem", {
        {"displayName", LocKey("my-item-name")},
        {"quality", EnumInt(gamedataQuality.Legendary)},
    })
end)
```

### Entity Spawning

```lua
registerForEvent("onInit", function()
    -- Spawn at player position
    local player = Game.GetPlayer()
    local transform = player:GetWorldTransform()
    local entityID = exEntitySpawner.SpawnRecord(
        TweakDBID.new("Vehicle.vsport2_maelstrom"),
        transform
    )
end)
```

---

*Generated from `dependencies/lua-libs/` type definition libraries. Last updated: 2026-08-09.*
