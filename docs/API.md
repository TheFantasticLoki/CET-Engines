# API Reference — UI-Engine

## Overview

UI-Engine exposes its public API through `_G.UIEngine`. Consumer mods access UI components through a `ctx` (context) object returned by `UIEngine.GetContext(id)`.

---

## Global API — `_G.UIEngine`

### Registration

#### `UIEngine.Register(id, spec)`

Register a mod panel in the UI-Engine sidebar.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `id` | string | yes | Unique mod identifier (e.g., `"my-mod"`) |
| `spec` | table | yes | Mod specification table |

**`spec` fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | yes | Display name in sidebar |
| `draw` | function | yes | `draw(ctx)` called each frame when selected |
| `version` | string | no | Mod version (displayed in card header) |
| `icon` | string | no | Icon glyph name for sidebar |
| `onInit` | function | no | Called when mod is registered |
| `onShutdown` | function | no | Called when mod is unregistered |

**Returns:** `true, nil` on success; `false, errorString` on failure.

```lua
local ok, err = UIEngine.Register("my-mod", {
    title = "My Mod",
    version = "1.0.0",
    draw = function(ctx)
        ctx.Text("Hello from My Mod!")
    end
})

if not ok then
    print("Registration failed: " .. err)
end
```

#### `UIEngine.RegisterWindow(id, spec)`

Register a standalone window (not in sidebar).

**Parameters:** Same as `Register()`.

**Returns:** `true, nil` on success; `false, errorString` on failure.

#### `UIEngine.Unregister(id)`

Remove a mod from UI-Engine. Cleans up events, state, and context.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `id` | string | yes | Mod identifier to unregister |

---

### Context

#### `UIEngine.GetContext(id)`

Get the context object for a registered mod.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `id` | string | yes | Mod identifier |

**Returns:** `ctx` object (table with metatable proxy) or `nil` if not registered.

---

### Theme

#### `UIEngine.GetTheme()`

Get the current theme name.

**Returns:** string (theme name, e.g., `"Red"`, `"Cyan"`, `"Dark"`).

#### `UIEngine.SetTheme(themeName)`

Set the current theme.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `themeName` | string | yes | Theme name (must be a registered theme) |

**Returns:** `true, nil` on success; `false, errorString` on failure.

#### `UIEngine.GetThemeList()`

Get all available theme names.

**Returns:** table of theme name strings.

---

### Events

#### `UIEngine.On(event, handler, source)`

Subscribe to an event.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `event` | string | yes | Event name |
| `handler` | function | yes | Callback function |
| `source` | string | no | Source label for debugging |

#### `UIEngine.Emit(event, ...)`

Emit an event to all subscribers.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `event` | string | yes | Event name |
| `...` | any | no | Event arguments |

#### `UIEngine.Off(event, handler)`

Unsubscribe from an event.

---

### Utility

#### `UIEngine.Deprecated(name, alternative)`

Log a deprecation warning. Use when changing public API.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | yes | Deprecated function/method name |
| `alternative` | string | no | Suggested replacement |

---

## Context API — `ctx`

The `ctx` object is the sole interface for consumer mods to access UI components. It uses metatables to delegate to the component library, composition layer, core state, and raw ImGui.

### Component Access

All UI-Engine components are available directly on `ctx`:

```lua
ctx.draw = function(ctx)
    if ctx.Button("Click Me") then
        print("Button clicked!")
    end

    local value = ctx.SliderFloat("My Slider", value, 0, 100)

    if ctx.ToggleButton("Enable Feature", value) then
        -- toggle state
    end
end
```

### Buttons

#### `ctx.Button(label, width, height, tooltip)`

Themed button. Returns `true` if clicked.

#### `ctx.ToggleButton(label, value, tooltip)`

ON/OFF toggle with color-coded state. Returns new value.

#### `ctx IconButton(icon, size, tooltip)`

Icon-only button. Returns `true` if clicked.

### Inputs

#### `ctx.Checkbox(label, value, tooltip)`

Checkbox. Returns new value.

#### `ctx.RadioButton(label, group, value, tooltip)`

Radio button within a group. Returns `true` if selected.

#### `ctx.InputText(label, value, placeholder, tooltip)`

Text input. Returns new value.

#### `ctx.InputInt(label, value, tooltip)`

Integer input. Returns new value.

#### `ctx.InputFloat(label, value, format, tooltip)`

Float input. Returns new value.

#### `ctx.KeyBind(label, key, tooltip)`

Key binding input. Returns new key value.

### Sliders

#### `ctx.SliderFloat(label, value, min, max, format, tooltip)`

Float slider. Returns new value.

#### `ctx.SliderInt(label, value, min, max, tooltip)`

Integer slider. Returns new value.

#### `ctx.DragInt(label, value, min, max, speed, tooltip)`

Drag integer. Returns new value.

#### `ctx.DragFloat(label, value, min, max, speed, format, tooltip)`

Drag float. Returns new value.

#### `ctx.StepSlider(label, value, min, max, step, format, tooltip)`

Fixed-width slider with +/- buttons. Returns new value.

#### `ctx.ColorPicker(label, color, tooltip)`

Color picker. Returns new color table `{r, g, b, a}`.

### Display

#### `ctx.Text(text)`

Display text.

#### `ctx.TextColored(color, text)`

Display colored text.

#### `ctx.TextWrapped(text)`

Display word-wrapped text.

#### `ctx.TextDisabled(text)`

Display grayed-out text.

#### `ctx.StatusBadge(label, color)`

Colored status indicator badge.

#### `ctx.InfoRow(label, value)`

Label:value pair display.

#### `ctx.Banner(text)`

Full-width notification banner.

#### `ctx.ProgressBar(value, label)`

Progress bar with optional label.

#### `ctx.Plot(label, data, min, max, width, tooltip)`

Simple line plot.

#### `ctx.Histogram(label, data, min, max, width, tooltip)`

Histogram display.

#### `ctx.Notification(text, type, duration)`

Popup notification system.

### Containers

#### `ctx.CollapsingSection(label, defaultOpen, buildFn, group)`

Collapsible section with persisted open/close state.

#### `ctx.TreeNode(label, buildFn)`

Tree node.

#### `ctx.CustomTreeNode(label, icon, buildFn)`

Sidebar category tree node variant.

### Advanced

#### `ctx.AdvancedSlider(spec)`

DrawList custom slider with +/- buttons, modifier keys (Alt/Shift/Ctrl), tick marks, inline input.

#### `ctx.ThemeDropdown(label, currentTheme, themes, onChange)`

Theme selector dropdown.

#### `ctx.ComboBox(label, items, selected, onChange)`

Dropdown combo box.

### Layout

#### `ctx.Separator(label)`

Optional labeled separator.

#### `ctx.Spacing()`

Vertical spacing.

#### `ctx.Indent(depth)`

Indent content.

#### `ctx.Columns(count, widths)`

Column layout.

#### `ctx.ScrollableRegion(height, buildFn)`

Scrollable content region.

### Console

#### `ctx.ConsoleOutput(entries, height)`

Searchable log viewer.

#### `ctx.RichInput(prompt, onSubmit, history)`

Input with history and shortcuts.

#### `ctx.ConsoleToolbar(actions)`

Toolbar buttons.

### Tables

#### `ctx.BeginTable(id, columns, flags)`

ImGui table wrapper.

### Icons

#### `ctx.GetIcon(name)`

Access CET's IconGlyphs.

#### `ctx.DrawCenteredText(text, size, color)`

Centered text helper.

### Composition Primitives

#### `ctx.Row(buildFn)`

Horizontal layout.

#### `ctx.Column(buildFn)`

Vertical layout.

#### `ctx.Stack(buildFn)`

Overlapping layout.

#### `ctx.Flex(direction, buildFn)`

Flexible layout.

#### `ctx.Box(buildFn)`

Box container.

#### `ctx.Padded(padding, buildFn)`

Padded container.

#### `ctx.Centered(buildFn)`

Centered container.

#### `ctx.Spacer(width, height)`

Spacer element.

#### `ctx.Divider()`

Visual divider.

#### `ctx.ErrorBoundary(buildFn, fallback)`

Error boundary — catches errors per-mod.

### State Access

#### `ctx.getSectionState(sectionId)`

Get persisted section open/close state.

#### `ctx.setSectionState(sectionId, value)`

Set persisted section open/close state.

#### `ctx.GetImGui()`

Raw ImGui access (escape hatch).

#### `ctx.GetDrawList()`

Current ImGui draw list.

#### `ctx.GetAvailableWidth()`

Available content width.

#### `ctx.GetState()`

Get mod-specific state table.

---

## Event System

### Standard Events

| Event | When | Arguments |
|-------|------|-----------|
| `uiengine:initComplete` | After initialization | none |
| `uiengine:registered` | After mod registration | `id, spec` |
| `uiengine:unregistered` | After mod unregistration | `id` |
| `uiengine:themeChanged` | After theme change | `themeName` |
| `uiengine:settingsChanged` | After settings change | `key, value` |
| `uiengine:draw` | Before each frame draw | none |

### Custom Events

Consumer mods can define and emit custom events:

```lua
-- In Mod A:
UIEngine.On("mymod:dataReady", function(data)
    print("Received data:", data)
end, "mymod")

-- In Mod B:
UIEngine.Emit("mymod:dataReady", { name = "test" })
```

---

## Registration API — Detailed

### Spec Validation

The `Register()` function validates the spec table strictly:

**Required fields:**
- `title` must be a non-empty string
- `draw` must be a function

**Optional fields:**
- `version` must be a string
- `icon` must be a string
- `onInit` must be a function
- `onShutdown` must be a function

**Validation failure examples:**
```lua
UIEngine.Register("", {})              -- false, "title is required"
UIEngine.Register("mod", { title="x" }) -- false, "draw is required"
UIEngine.Register("mod", { title="x", draw="notfunc" }) -- false, "draw must be a function"
```

### Idempotent Registration

Calling `Register()` twice with the same ID updates the existing registration:

```lua
UIEngine.Register("my-mod", { title = "V1", draw = drawV1 })
UIEngine.Register("my-mod", { title = "V2", draw = drawV2 })
-- Result: "my-mod" is now registered with V2 spec
```

---

## Primitives

### `ClipboardCopy(text)`

Copy text to clipboard.

### `SafeSelectable(label, selected)`

Selectable item with CET hover-state workaround (fixes unclickable options bug).

### `ContextMenu(label, buildFn)`

Right-click context menu.

### `SelectableEntry(label, selected, tooltip)`

Selectable with tooltip.