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

#### `ctx.MultiSelect(label, items, selected, options)`

Multi-select dropdown with checkboxes for selecting multiple items.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `label` | string | yes | Label text |
| `items` | table | yes | Array of strings or `{label, value}` pairs |
| `selected` | table | yes | Table of selected indices |
| `options` | table | no | `{ placeholder, tooltip, width, maxVisible, searchable }` |

**Returns:** `table newSelected, boolean changed`

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

#### `ctx.Card(spec)`

Card container with header, body, and footer sections.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `spec` | table | yes | Card specification table |

**`spec` fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | no | Card title |
| `subtitle` | string | no | Subtitle text |
| `icon` | string | no | Icon glyph |
| `headerRight` | function | no | Content for header right side |
| `body` | function | no | Body content function |
| `footer` | function | no | Footer content function |
| `onClick` | function | no | Click handler |
| `selected` | boolean | no | Selected state (highlighted border) |

**Returns:** `boolean clicked`

### Advanced

#### `ctx.AdvancedSlider(label, value, options)`

Advanced DrawList-rendered slider with modifier keys, animations, and default indicator.

**Supports two call styles:**
- `ctx.AdvancedSlider(label, value, options)` — new style (recommended)
- `ctx.AdvancedSlider(spec)` — legacy style `{label, value, min, max, ...}`

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `label` | string | yes | Unique label/ID string |
| `value` | number | yes | Current value |
| `options` | table | no | Configuration options (see below) |

**Core Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `min` | number | 0 | Range minimum |
| `max` | number | 100 | Range maximum |
| `default` | number | (min+max)/2 | Default value for indicator |
| `step` | number | (max-min)/100 | Base step for buttons |
| `format` | string | "%.2f" | Value format string |
| `onChange` | function | nil | Callback: `onChange(newValue)` |

**Display Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | string | nil | Display name for tooltip |
| `description` | string | nil | Optional description for tooltip |
| `tooltip` | string | nil | Additional tooltip text |
| `width` | number | 256 | Total component width |
| `height` | number | 36 | Component height |

**Toggle Options (set `false` to disable):**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `showButtons` | boolean | true | Show ± buttons |
| `showTooltip` | boolean | true | Show value tooltip |
| `showDefaultLine` | boolean | true | Show default indicator |
| `showTicks` | boolean | true | Show position ticks |

**Style Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `handleStyle` | string | "rect" | Handle style: "rect" or "circle" |
| `valueDisplay` | string | "auto" | Value position: "auto", "inside", "button", "none" |

**Sizing Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `trackHeight` | number | 18 | Track height in pixels |
| `trackRounding` | number | trackHeight/2 | Track corner rounding |
| `handleWidth` | number | 6 | Rect handle width |
| `handleHoverWidth` | number | 7 | Rect handle width on hover |
| `handleRadius` | number | 10 | Circle handle radius |
| `handleHoverRadius` | number | 12 | Circle handle radius on hover |
| `buttonWidth` | number | 20 | Button width |
| `buttonHeight` | number | 18 | Button height |
| `buttonSpacing` | number | 4 | Space between button and track |

**Indicator Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `indicatorShort` | number | 4 | Length at default position |
| `indicatorLong` | number | 14 | Length away from default |
| `indicatorThickness` | number | 2 | Line thickness |

**Tick Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `majorTicks` | number | 4 | Major tick count |
| `minorTicks` | number | 2 | Minor ticks between majors |

**Color Options (accept role strings like `"primary"` or `{r,g,b}` tables):**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `trackColor` | string/table | "panel" | Track background color |
| `fillColor` | string/table | "primary" | Fill color |
| `handleColor` | string/table | "primary" | Handle color |
| `buttonColor` | string/table | "panel" | Button color |
| `indicatorColor` | string/table | "text" | Default indicator color |
| `valueTextColor` | string/table | "text" | Value text color |
| `tooltipBgColor` | string/table | "background" | Tooltip background |

**Behavior Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `modifierShiftMult` | number | 0.1 | Shift drag multiplier |
| `modifierCtrlMult` | number | 0.01 | Ctrl drag multiplier |
| `modifierAltMult` | number | 10 | Alt drag multiplier |
| `animationDuration` | number | 0.12 | Animation duration (seconds) |

**Returns:** `number newValue, boolean changed`

**Example:**
```lua
local value = ctx.AdvancedSlider("##brightness", 50, {
    min = 0, max = 100, default = 50,
    label = "Brightness",
    description = "Display brightness level",
    handleStyle = "circle",
    trackHeight = 24,
    showTicks = true,
    majorTicks = 10,
    minorTicks = 5,
    fillColor = {r = 0.2, g = 0.8, b = 0.4},
    modifierShiftMult = 0.25,
})
```

#### `ctx.ThemeDropdown(label, currentTheme, themes, onChange)`

Theme selector dropdown.

#### `ctx.ComboBox(label, items, selected, onChange)`

Dropdown combo box.

#### `ctx.SearchableComboBox(label, items, selectedIndex, options)`

Dropdown with text filter input for searching through items.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `label` | string | yes | Label text |
| `items` | table | yes | Array of strings or `{label, value}` pairs |
| `selectedIndex` | number | yes | Current selected index (0 = none) |
| `options` | table | no | `{ placeholder, tooltip, width, maxVisible }` |

**Returns:** `number newIndex, boolean changed`

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