# CET Engine Workspace — Chat Primer

> Copy this into new chat sessions to orient the agent quickly.

---

## What This Is

A **unified CET mod** called **0-Mod-Engine** for Cyberpunk 2077. It combines three subsystems into one mod:

- **UI-Engine** — Component library (~50+ ImGui widgets), theme system (16 themes), event bus, mod registration
- **Config-Engine** — Settings UI: schema-driven auto-rendering, sidebar, search, undo/redo, auto-save
- **Log-Engine** — File-based logging with ring buffers, rotation, deduplication

Everything lives under `engines/0-Mod-Engine/`.

---

## Hard Constraints (Non-Negotiable)

| Rule | Why |
|------|-----|
| **Lua 5.1 only** | CET uses Lua 5.1 — no `goto`, no `__gc`, no `table.pack`/`table.unpack` |
| **No `_G`** | CET sandbox doesn't expose `_G`. Use direct global assignment: `ModEngine = {}` |
| **Module pattern** | Every file: `local M = {} ... return M`. No exceptions. |
| **`local` everywhere** | Only public API symbols are global. Never pollute globals except intentionally. |
| **SafeRequire** | `pcall(require, path)` for all imports. One failed module must not crash the engine. |
| **Single pcall onDraw** | ALL ImGui calls in ONE pcall. CET FFI breaks with per-call pcall wrapping. |
| **Push/Pop balance** | Every `Theme.PushTheme()` must have a matching `PopTheme()`. Imbalance corrupts ImGui state. |
| **No silent failures** | Always log errors via Logger, never swallow them. |

---

## Where Things Are

```
engines/0-Mod-Engine/
├── init.lua                  # Entry point, CET callbacks, ModEngine global API
├── core.lua                  # Centralized state store (panels, windows, ui, theme, sidebar)
├── api/
│   ├── events.lua            # Pub/sub (on/emit/off/once/cleanup)
│   ├── registry.lua          # Mod registration with schema validation
│   ├── context.lua           # Per-mod ctx proxy for component access
│   └── windows.lua           # Standalone window management
├── ui/
│   ├── theme.lua             # Push/Pop theme engine (27 colors + 9 style vars)
│   ├── color_engine.lua      # RGB↔HSL, WCAG contrast, palette generation
│   ├── tokens.lua            # Design tokens (spacing, sizing, colors)
│   ├── animation.lua         # Easing, Lerp, Timer
│   ├── utils.lua             # Tooltip, SafeSelectable, DeepCopy, ResolveLogger
│   └── components/           # ~50+ widgets (buttons, sliders, inputs, advanced, etc.)
│       └── init.lua          # Barrel re-export — flattens all sub-modules
├── modules/
│   ├── logger.lua            # Legacy ring buffer logger (overlay, file rotation)
│   └── storage.lua           # Atomic JSON persistence (temp→bak→primary)
├── cfg/
│   ├── core.lua              # Config-Engine state (mods, categories, UI state)
│   ├── mod_manager.lua       # Registration, lifecycle, render mode detection
│   ├── settings_schema.lua   # 14 setting types with validation
│   ├── settings_resolver.lua # Merge defaults + saved, dot-path get/set
│   ├── settings_renderer.lua # Schema → ImGui auto-generation
│   ├── setting_applier.lua   # Apply settings to engine subsystems
│   ├── undo_redo.lua         # Command pattern, 50-step ring buffer, batch mode
│   ├── state_sync.lua        # Auto-save debounce (0.5s), load on init
│   ├── render_mode.lua       # Detects schema/custom/hybrid/external
│   ├── search_parser.lua     # Advanced search: substring + tag="x" filters
│   ├── test_runner.lua       # pcall-wrapped test execution
│   ├── test_results.lua      # In-memory results with history
│   └── ui/
│       ├── window.lua        # Main window orchestrator
│       ├── sidebar.lua       # Toolbar, search, categories, filters
│       └── content_area.lua  # Mode-switching: mod/settings/tests
├── config/
│   ├── themes.lua            # 16 theme definitions (accent + roles)
│   ├── engine_schemas.lua    # Built-in schemas for 0-Engine-UI/Log/Config
│   └── categories.lua        # 6 categories with subcategories
└── log/
    ├── init.lua              # Log-Engine entry point
    ├── config.lua            # Log configuration defaults
    ├── file_output.lua       # File rotation and output
    ├── logger.lua            # Logger instance logic
    └── stats.lua             # Log statistics and metrics
```

---

## Key Patterns

### Module init (idempotent)
```lua
local initialized = false
function M.init(deps)
    if initialized then return end
    initialized = true
    -- wire dependencies
end
```

### Late-breaking circular deps
Events and Core have a circular dependency. Broken via late-binding:
```lua
-- In Events.init():
core.setEventEmitter(M.emit)
```

### SafeRequire
```lua
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then return mod end
    print("[ModEngine] FAILED to load '" .. path .. "': " .. tostring(mod))
    return nil
end
```

### Settings schema (Config-Engine)
```lua
spec.settings = {
    myToggle = { type = "toggle", label = "My Toggle", default = true },
    mySlider = { type = "slider", label = "Speed", min = 0, max = 10, step = 0.1, default = 1.0 },
    myCombo  = { type = "combo",  label = "Mode", options = {"Fast","Slow"}, default = "Fast" },
}
```

14 types: `toggle`, `slider`, `int_slider`, `combo`, `multi_combo`, `text`, `number`, `color`, `keybind`, `header`, `group`, `info`, `button`, `custom`

### Public API (ModEngine global)
```lua
ModEngine.Register(id, spec)        -- UI-Engine registration
ModEngine.Unregister(id)            -- UI-Engine unregistration
ModEngine.GetContext(id)            -- Get ctx proxy
ModEngine.Enable(id) / Disable(id) -- Enable/disable a mod

ModEngine.RegisterMod(id, spec)     -- Config-Engine registration
ModEngine.UnregisterMod(id)         -- Config-Engine unregistration
ModEngine.GetMod(id)                -- Get Config-Engine mod info
ModEngine.GetModSettings(id)        -- Get current settings values
ModEngine.SetModSettings(id, val)   -- Update settings values
ModEngine.ResetModSettings(id)      -- Reset to schema defaults
ModEngine.Undo / Redo               -- Config undo/redo
ModEngine.CanUndo / CanRedo         -- Check undo/redo availability

ModEngine.On / Emit / Off           -- Events
ModEngine.GetTheme / SetTheme       -- Theme
ModEngine.GetThemeList              -- List available themes
ModEngine.GetContrastLevel / SetContrastLevel -- Accessibility

ModEngine.Core                      -- Direct state access
ModEngine.Storage                   -- Direct storage access
ModEngine.Theme                     -- Direct theme engine access
```

---

## Testing

```bash
./scripts/test.sh          # Run all unit tests (lua tests/init.lua)
./scripts/lint.sh          # Code quality checks
./scripts/deploy.sh        # Deploy to game folder
```

Tests live in `tests/unit/*_test.lua`. Each module has a corresponding test file. Mocks in `tests/mocks/` for CET, ImGui, GameUI.

---

## What NOT To Do

- Don't use `goto` or labels (Lua 5.2+)
- Don't use `table.pack` / `table.unpack` (Lua 5.2+)
- Don't use `__gc` in metatables (Lua 5.1 limitation)
- Don't call `GetMod()` at top level — only inside `onInit` handler
- Don't duplicate utility functions — put shared helpers in `ui/utils.lua`
- Don't wrap individual ImGui calls in pcall — use the single pcall pattern in onDraw
- Don't modify files in `dependencies/` or `reference/` — those are read-only
- Don't leave `PushTheme` without a matching `PopTheme`
- Don't create global variables unintentionally — use `local` everywhere
- Don't use `require("path/to/module")` — use `require("module")` relative to mod root
