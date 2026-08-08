# Settings Schema System

## Overview

The Settings Schema System defines how settings are structured, validated, and rendered in the Config-Engine. It supports both automatic schema-driven rendering and custom code for complex UIs.

## Schema Structure

A schema defines a mod's settings with metadata and setting definitions:

```lua
{
    name = "My Mod",
    version = "1.0.0",
    author = "Author Name",
    description = "Description of the mod",
    settings = {
        -- Setting definitions here
    }
}
```

## Setting Types

### Basic Types

| Type | Description | Required Fields |
|------|-------------|-----------------|
| `toggle` | Boolean checkbox | `label`, `default` |
| `slider` | Float slider | `label`, `min`, `max`, `default` |
| `int_slider` | Integer slider | `label`, `min`, `max`, `default` |
| `combo` | Dropdown selection | `label`, `options`, `default` |
| `multi_combo` | Multi-select dropdown | `label`, `options`, `default` |
| `text` | Text input | `label`, `default` |
| `number` | Float input | `label`, `default` |
| `color` | Color picker | `label`, `default` |
| `keybind` | Keybind display | `label`, `default` |
| `header` | Section separator | `label` |
| `group` | Collapsible section | `label`, `settings` |
| `info` | Informational text | `text` |
| `button` | Action button | `label`, `action` |
| `custom` | Custom render function | `render` |

### Layout Types (New)

| Type | Description | Required Fields |
|------|-------------|-----------------|
| `section` | Wraps settings in a styled SectionCard | `label`, `settings` |
| `divider` | Visual separator line | (none) |
| `spacer` | Vertical space | `height` (optional, default: 8) |
| `custom_section` | Section with custom render function | `label`, `render` |

## Examples

### Section with Nested Settings

```lua
settings = {
    theme_section = {
        type = "section",
        label = "THEME",
        settings = {
            currentTheme = {
                type = "combo",
                label = "Theme",
                options = { "Dark", "Light" },
                default = "Dark",
            },
        },
    },
}
```

### Custom Section with Render Function

```lua
settings = {
    advanced_section = {
        type = "section",
        label = "ADVANCED",
        render = function(settings, key)
            -- Full ImGui control here
            ImGui.Text("Custom UI")
            -- Return true if any setting changed
            return false
        end
    },
}
```

### Divider and Spacer

```lua
settings = {
    setting1 = { type = "toggle", ... },
    sep1 = { type = "divider" },
    spacer1 = { type = "spacer", height = 16 },
    setting2 = { type = "slider", ... },
}
```

## Rendering

The SettingsRenderer automatically renders settings from schemas:

```lua
local renderer = require("cfg/settings_renderer")
renderer.init({ core = Core, events = Events, components = Components })
renderer.renderSettings(modId, spec, settings)
```

The renderer handles:
- All basic types with appropriate ImGui widgets
- Section cards with styled backgrounds and titles
- Dividers and spacers
- Custom sections with render functions
- Conditional visibility via `visible` function
- Undo/redo integration
- Value validation

## Custom Rendering

For complex UIs that don't fit the schema model, use the `custom_section` type or the `renderMode = "custom"` in your mod spec:

```lua
-- In mod registration
spec = {
    renderMode = "custom",  -- or "hybrid" for schema + custom
    draw = function(ctx)
        -- Full ImGui control
        -- ctx provides access to ImGui functions
    end
}
```

## Validation

The schema system validates:
- Required fields for each type
- Type-specific constraints (min/max for sliders, options for combos)
- Custom validation functions via `validate` field

Validation errors are logged and reported to the user.
