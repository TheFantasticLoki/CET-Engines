# UI-Engine

**Version:** v0.5.0-phase4  
**Author:** 0-Loki  
**CET Mod Name:** `0-Engine-UI`

## Overview

UI-Engine is the core UI framework for the CET Engine workspace. It provides a component library, theme system, events pub/sub, mod registration, and window management for Cyberpunk 2077 mod configuration interfaces.

## Architecture

```
UI-Engine
├── Core (state store)
├── Events (pub/sub)
├── Theme (push/pop, 16 themes)
├── Components (50+ widgets)
├── Registry (mod registration)
├── Context (ctx proxy)
├── Windows (standalone windows)
├── Storage (persistence)
├── Logger (ring buffer, overlay)
└── Tokens (design tokens)
```

## Public API

```lua
local UIEngine = GetMod("0-Engine-UI")

-- Registration
UIEngine.Register(id, spec)        -- Register a mod
UIEngine.Unregister(id)            -- Unregister a mod
UIEngine.GetContext(id)            -- Get ctx object for a mod

-- Theme
UIEngine.GetTheme()                -- Get current theme name
UIEngine.SetTheme(name)            -- Set theme (returns bool)
UIEngine.GetThemeList()            -- Get list of theme names

-- Events
UIEngine.On(event, handler)        -- Subscribe to event
UIEngine.Emit(event, ...)          -- Emit event
UIEngine.Off(event, handler)       -- Unsubscribe

-- Status
UIEngine.IsRegistered(id)          -- Check if mod is registered
UIEngine.GetRegisteredMods()       -- Get all registered mod IDs
UIEngine.GetVersion()              -- Get version string
UIEngine.IsOverlayOpen()           -- Check if CET overlay is open
```

## Configuration

UI-Engine is configurable via Config-Engine. Settings include:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `currentTheme` | combo | "Dark" | Global UI theme |
| `accentColor` | color | {0.4, 0.6, 1.0} | Accent color |
| `contrastLevel` | int_slider | 1 | Accessibility contrast (1=normal, 2=high) |
| `autoSave` | toggle | true | Auto-save settings |
| `autoSaveDelay` | slider | 0.5 | Delay before auto-save (seconds) |
| `showLoggerOverlay` | toggle | false | Show logger overlay |
| `maxDebugPerFrame` | int_slider | 5 | Max debug messages/frame |

## Module Loading

Modules are loaded in strict order during `onInit()`:

1. **Phase 1:** Core, Logger, Storage, Events, Utils
2. **Phase 2:** ThemeDefs, ColorEngine, Tokens, DefaultConfig, Theme
3. **Phase 3:** Window, Components, Registry, Context
4. **Phase 4:** Windows

All modules use `SafeRequire` for graceful degradation.

## CET Compatibility

- **Lua 5.1 only** — no `goto`, `__gc`, `table.pack/unpack`
- **Single `pcall`** — all ImGui calls wrapped in one pcall in `onDraw`
- **No `_G`** — CET sandboxed environment; use direct assignment
- **`registerForEvent`** — required for CET callbacks (global `onInit` doesn't work)

## Integration with Config-Engine

UI-Engine automatically registers with Config-Engine if available. This enables:
- Theme selection via Config-Engine UI
- Accent color customization
- Logger overlay toggle
- Auto-save configuration

## File Structure

```
engines/UI-Engine/
├── init.lua              # Entry point, CET callbacks, public API
├── core.lua              # Centralized state store
├── api/
│   ├── events.lua        # Pub/sub event system
│   ├── registry.lua      # Mod registration
│   ├── context.lua       # ctx proxy for components
│   └── windows.lua       # Standalone window management
├── modules/
│   ├── logger.lua        # Ring buffer logging
│   └── storage.lua       # Atomic JSON persistence
├── ui/
│   ├── components/       # 50+ widget components
│   ├── theme.lua         # Push/pop theme engine
│   ├── tokens.lua        # Design tokens
│   ├── color_engine.lua  # WCAG color science
│   ├── utils.lua         # Shared utilities
│   └── window.lua        # Main window orchestrator
├── config/
│   ├── default_config.lua # Default values
│   └── themes.lua        # 16 theme definitions
└── README.md             # This file
```
