# Config-Engine

**Version:** v0.1.0  
**Author:** 0-Loki  
**CET Mod Name:** `0-Engine-Config`

## Overview

Config-Engine is a unified mod configuration manager that provides a settings UI for all engines and mods in the CET Engine workspace. It supports schema-based settings, undo/redo, presets, and categories.

## Architecture

```
Config-Engine
├── Core (state store)
├── ModManager (registration, lifecycle)
├── SettingsSchema (type definitions, validation)
├── SettingsRenderer (schema → ImGui widgets)
├── SettingsResolver (merge defaults + saved)
├── UndoRedo (command pattern, ring buffer)
└── StateSync (auto-save, persistence)
```

## Public API

```lua
local ConfigEngine = GetMod("0-Engine-Config")

-- Registration
ConfigEngine.Register(modId, spec)      -- Register a mod
ConfigEngine.Unregister(modId)          -- Unregister
ConfigEngine.GetMod(modId)              -- Get mod info
ConfigEngine.GetMods()                  -- List all mod IDs

-- Settings
ConfigEngine.GetSettings(modId)         -- Get settings
ConfigEngine.SetSettings(modId, data)   -- Update settings
ConfigEngine.ResetSettings(modId)       -- Reset to defaults

-- Undo/Redo
ConfigEngine.Undo()                     -- Undo last change
ConfigEngine.Redo()                     -- Redo last undone
ConfigEngine.CanUndo()                  -- Check if undo available
ConfigEngine.CanRedo()                  -- Check if redo available

-- Categories
ConfigEngine.SetCategory(modId, cat, subcat)
ConfigEngine.GetCategory(modId)

-- Window
ConfigEngine.IsManaged(modId)           -- Check if registered
ConfigEngine.DetachMod(modId)           -- Detach to window
ConfigEngine.ReattachMod(modId)         -- Reattach window
```

## Window Layout

When you open the CET overlay (F4), Config-Engine shows:

```
┌─────────────────────────────────────────────────────┐
│ Config Engine                              [Edit] [View] │
├──────────┬──────────────────────────────────────────┤
│ Engines  │ Selected Mod                            │
│ ──────── │ ──────────                              │
│ [UI]     │ Mod Name v1.0                           │
│ [Log]    │ Author: ...                             │
│ [Config] │ Description: ...                        │
│ ──────── │ ──────────                              │
│ Search...│ [Setting 1: ___]                        │
│ ──────── │ [Setting 2: ===]                        │
│ Mod 1    │ [Setting 3: ☑]                          │
│ Mod 2    │ ──────────                              │
│ Mod 3    │ [Reset to Defaults]                     │
└──────────┴──────────────────────────────────────────┘
```

## How to Register a Mod

### 1. Schema-Based Registration (Recommended)

```lua
local ConfigEngine = GetMod("0-Engine-Config")

ConfigEngine.Register("my-mod", {
    name = "My Mod",
    version = "1.0.0",
    author = "Author",
    description = "Description of my mod",
    category = "Gameplay",
    subcategory = "Combat",

    settings = {
        enabled = {
            type = "toggle",
            default = true,
            label = "Enable Mod",
            tooltip = "Master toggle",
        },
        volume = {
            type = "slider",
            min = 0, max = 100, step = 1,
            default = 50,
            label = "Volume",
            format = "%d%%",
        },
        mode = {
            type = "combo",
            options = { "Classic", "Modern", "Auto" },
            default = "Auto",
            label = "Mode",
        },
    },
})
```

### 2. Custom Draw Registration

```lua
ConfigEngine.Register("my-mod", {
    name = "My Mod",
    version = "1.0.0",
    draw = function(ctx)
        -- Custom ImGui drawing
        ctx.Text("Hello from my mod!")
        if ctx.Button("Click me") then
            print("Clicked!")
        end
    end,
})
```

### 3. Hybrid Registration

```lua
ConfigEngine.Register("my-mod", {
    name = "My Mod",
    version = "1.0.0",
    settings = { /* schema */ },
    draw = function(ctx)
        -- Additional custom UI
    end,
})
```

## Setting Types

| Type | Widget | Parameters |
|------|--------|------------|
| `toggle` | Checkbox | `default`, `label`, `tooltip` |
| `slider` | SliderFloat | `min`, `max`, `step`, `default`, `format`, `label`, `tooltip` |
| `int_slider` | SliderInt | `min`, `max`, `step`, `default`, `label`, `tooltip` |
| `combo` | ComboBox | `options`, `default`, `label`, `tooltip`, `searchable` |
| `multi_combo` | MultiSelect | `options`, `default`, `label`, `tooltip` |
| `text` | InputText | `placeholder`, `default`, `label`, `tooltip`, `multiline` |
| `number` | InputFloat | `min`, `max`, `step`, `default`, `format`, `label`, `tooltip` |
| `color` | ColorPicker | `default`, `label`, `tooltip`, `alpha` |
| `keybind` | KeyBind | `default`, `label`, `tooltip`, `allowMouse` |
| `header` | Separator | `label` |
| `group` | CollapsingSection | `settings`, `label`, `tooltip`, `collapsed` |
| `info` | TextWrapped | `text` |
| `button` | Button | `label`, `action`, `tooltip` |
| `custom` | Custom | `render` function |

## Engine Integration

Config-Engine automatically registers the following engines:

| Engine | Mod ID | Version |
|--------|--------|---------|
| UI-Engine | `0-Engine-UI` | v0.5.0-phase4 |
| Log-Engine | `0-Engine-Log` | v1.1.0 |
| Config-Engine | `0-Engine-Config` | v0.1.0 |

Engine schemas are defined in `config/engine_schemas.lua`.

## Undo/Redo System

All settings changes are tracked in an undo/redo stack:
- **50 undo steps** (configurable)
- **Batch operations** supported
- **Commands**: setting change, preset apply, reset to defaults

## Persistence

Settings are persisted via UI-Engine's Storage module:
- **Auto-save** with 30-frame debounce
- **Flush on overlay close** and shutdown
- **Atomic writes** (temp → backup → primary)

## CET Compatibility

- **Lua 5.1 only** — no `goto`, `__gc`, `table.pack/unpack`
- **Single `pcall`** — all ImGui calls wrapped in one pcall
- **`GetMod()` deferred** — called in `onInit`, not at top level
- **`registerForEvent`** — required for CET callbacks

## File Structure

```
engines/Config-Engine/
├── init.lua                    # Entry point, CET callbacks, public API
├── core.lua                    # State store
├── modules/
│   ├── mod_manager.lua         # Registration, lifecycle
│   ├── settings_schema.lua     # Type definitions, validation
│   ├── settings_renderer.lua   # Schema → ImGui widgets
│   ├── settings_resolver.lua   # Merge defaults + saved
│   ├── render_mode.lua         # Detect render mode
│   ├── undo_redo.lua           # Undo/redo system
│   └── state_sync.lua          # Auto-save, persistence
├── config/
│   ├── default_config.lua      # Default values
│   ├── categories.lua          # Built-in categories
│   └── engine_schemas.lua      # Engine configuration schemas
├── ui/
│   ├── window.lua              # Main window (unused, inline in init)
│   ├── sidebar.lua             # Sidebar (unused, inline in init)
│   └── content_area.lua        # Content area (unused, inline in init)
└── README.md                   # This file
```
