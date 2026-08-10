# File Map — CET Engine Workspace

## Overview

Complete directory structure with file descriptions and module relationships.

---

## Root Directory

```
├── AGENTS.md                    # AI agent guidelines (source of truth)
├── README.md                    # Workspace overview, quick start
└── .gitignore                   # Git ignore rules
```

| File | Purpose |
|------|---------|
| `AGENTS.md` | Comprehensive guidelines for AI agents working in this workspace. Covers code organization, API design, error handling, theme system, performance, testing, documentation, versioning, and CET compatibility. |
| `README.md` | Human-readable workspace overview, directory structure, quick start guide, and links to documentation. |
| `.gitignore` | Ignores `versions/`, `docs/plans/`, `deployment/game/`, `deployment/vortex/`, `dependencies/`, `patched/`, `reference/`. |

---

## `engines/0-Mod-Engine/` — Unified CET Mod

> All engines are consolidated into a single mod. Subdirectories: `api/`, `cfg/`, `config/`, `log/`, `modules/`, `ui/`.

### Entry Point

| File | Lines | Purpose |
|------|-------|---------|
| `init.lua` | ~950 | Unified entry point. SafeRequire pattern, module loading, CET callbacks, backward-compat globals. |

### Core Systems

| File | Lines | Purpose |
|------|-------|---------|
| `core.lua` | ~600 | Centralized state store for UI-Engine. Theme, accent, contrast, sidebar, dirty flag. |

### API Layer (`api/`)

| File | Purpose |
|------|---------|
| `api/events.lua` | Pub/sub event system with source labels, pcall-guarded dispatch, mod-scoped cleanup. |
| `api/registry.lua` | Register/RegisterWindow/Unregister API for mod panels. |
| `api/context.lua` | Themed `ctx` metatable proxy delegating to Components. |
| `api/windows.lua` | Standalone window management. |

### UI Layer (`ui/`)

| File | Purpose |
|------|---------|
| `ui/utils.lua` | Shared utilities: Tooltip, SafeSelectable, DeepCopy, ResolveLogger, GetThemeCacheKey. |
| `ui/theme.lua` | Theme push/pop engine with caching, validation, high contrast, overrides. |
| `ui/tokens.lua` | Design tokens: spacing, sizing, border radius, text size, theme-aware colors. |
| `ui/color_engine.lua` | WCAG color science: contrast ratios, color generation, accessibility validation. |
| `ui/animation.lua` | Easing functions, Lerp, Timer, color blending for smooth transitions. |
| `ui/components/` | Barrel re-export of ~50+ widget sub-modules (primitives, buttons, display, layout, etc.). |
| `ui/components/display.lua` | Notification system, progress bars, histograms, status indicators. |
| `ui/components/icon_browser.lua` | Searchable icon grid for browsing Material Design icons. |

### Config-Engine (`cfg/`)

| File | Purpose |
|------|---------|
| `cfg/core.lua` | Config-Engine state store: mods, categories, UI state, dirty flag, auto-save toggle. |
| `cfg/mod_manager.lua` | Mod discovery, registration, lifecycle, auto-categorization. |
| `cfg/settings_schema.lua` | Setting type definitions, validation, schema management. |
| `cfg/settings_resolver.lua` | Merges defaults with saved values, validates against schema. |
| `cfg/settings_renderer.lua` | Converts settings schemas to ImGui widgets automatically. |
| `cfg/undo_redo.lua` | Command pattern with ring buffer for settings changes. |
| `cfg/state_sync.lua` | Synchronizes Config-Engine state with Storage. Auto-save with debounce. |
| `cfg/render_mode.lua` | Detects render mode: schema, custom, hybrid, external. |
| `cfg/search_parser.lua` | Parses advanced search syntax from sidebar search bar. |
| `cfg/test_runner.lua` | Runs mod-registered tests with isolation and error handling. |
| `cfg/test_results.lua` | Stores and aggregates test results per mod. |
| `cfg/ui/window.lua` | Main Config-Engine window: orchestrates sidebar + content area. |
| `cfg/ui/sidebar.lua` | Toolbar, search, filters, categories, theme quick-switch. |
| `cfg/ui/content_area.lua` | Mod settings, engine settings, test results panels. |

### Config (`config/`)

| File | Purpose |
|------|---------|
| `config/default_config.lua` | Single source of default values for all modules. |
| `config/themes.lua` | 16 built-in theme definitions. |
| `config/engine_schemas.lua` | Built-in engine settings schemas. |
| `config/categories.lua` | Category definitions with icons and subcategories. |

### Modules (`modules/`)

| File | Purpose |
|------|---------|
| `modules/logger.lua` | Leveled logging with ring buffer and overlay. |
| `modules/storage.lua` | Atomic JSON key-value storage (temp → backup → primary pattern). |

### Log-Engine (`log/`)

| File | Purpose |
|------|---------|
| `log/init.lua` | Unified Log-Engine entry point. Logger creation, file output, stats. |
| `log/config.lua` | Default configuration values for Log-Engine. |
| `log/file_output.lua` | File I/O with rotation and backup. |
| `log/logger.lua` | Core logger engine with deduplication and rate limiting. |
| `log/stats.lua` | Cross-mod statistics tracking. |

---

## `tests/` — Shared Test Infrastructure

| File | Purpose |
|------|---------|
| `tests/init.lua` | Test runner: discovers and executes unit tests. |
| `tests/assert.lua` | Assertion library: assert_equal, assert_true, assert_false, assert_error. |
| `tests/mocks/` | CET, ImGui, GameUI mocks for headless testing. |
| `tests/unit/` | Unit test files (one per module). |
│   │   ├── tokens.lua            # Design tokens
│   │   ├── docs.lua              # In-game wiki renderer
│   │   ├── utils.lua             # Shared utilities (Tooltip, CET workarounds)
│   │   └── components/           # ~50+ ImGui widgets
│   │       ├── init.lua          # Barrel re-export
│   │       ├── compose.lua       # Row, Column, Stack, Flex, ErrorBoundary
│   │       ├── buttons.lua       # Button, ToggleButton, IconButton
│   │       ├── inputs.lua        # Checkbox, RadioButton, InputText, KeyBind
│   │       ├── sliders.lua       # SliderFloat, StepSlider, ColorPicker
│   │       ├── display.lua       # Text, StatusBadge, ProgressBar, Plot
│   │       ├── containers.lua    # CollapsingSection, TreeNode
│   │       ├── advanced.lua      # AdvancedSlider, ThemeDropdown, ComboBox
│   │       ├── layout.lua        # Separator, Indent, Columns, ScrollableRegion
│   │       ├── console.lua       # ConsoleOutput, RichInput, ConsoleToolbar
│   │       ├── tables.lua        # BeginTable wrapper
│   │       ├── primitives.lua    # ClipboardCopy, SafeSelectable, ContextMenu
│   │       └── glyphs.lua       # Centralized CET IconGlyphs rendering
│   │       └── icons.lua        # DEPRECATED: Emoji-only icons (legacy)
│   ├── features/
│   │   ├── favorites.lua         # Sidebar star/favorite logic
│   │   └── presets.lua           # Per-mod presets (may move to Config-Engine)
│   ├── modules/
│   │   ├── logger.lua            # Leveled logging, ring buffer, overlay
│   │   └── storage.lua           # Atomic JSON key-value storage
│   └── config/
│       └── themes.lua            # 16 built-in theme definitions
```

### 0-Mod-Engine Module Relationships

```
init.lua
  ├── log/init.lua           (Log-Engine entry point)
  ├── core.lua               (state store)
  ├── modules/logger.lua     (ring buffer logging)
  ├── modules/storage.lua    (persistence)
  ├── api/events.lua         (pub/sub)
  ├── ui/utils.lua           (shared utilities)
  ├── config/themes.lua      (theme definitions)
  ├── ui/color_engine.lua    (color science)
  ├── ui/tokens.lua          (design tokens)
  ├── ui/theme.lua           (theme engine)
  ├── ui/animation.lua       (easing, lerp, timer)
  ├── ui/components/         (widget library)
  ├── api/context.lua        (context proxy)
  ├── api/registry.lua       (registration)
  ├── api/windows.lua        (standalone windows)
  ├── cfg/core.lua           (Config-Engine state)
  ├── cfg/mod_manager.lua    (mod registration)
  ├── cfg/settings_schema.lua
  ├── cfg/settings_resolver.lua
  ├── cfg/settings_renderer.lua
  ├── cfg/setting_applier.lua
  ├── cfg/undo_redo.lua
  ├── cfg/state_sync.lua
  ├── cfg/render_mode.lua
  ├── cfg/search_parser.lua
  ├── cfg/test_runner.lua
  ├── cfg/test_results.lua
  └── cfg/ui/                (window, sidebar, content_area)
```

---

## `dependencies/` — Third-Party Dependencies

```
dependencies/
├── README.md                   # Explains each dependency
├── 0-Engine/                   # 0-Engine stock v0.18.6 (DigitalVixen)
│   ├── bin/.../mods/0-Engine/  # Actual CET mod location (simplified below)
│   │   ├── init.lua            # Main entry point, wires all modules, public API
│   │   ├── modules/
│   │   │   ├── EventEmitter.lua    # pcall-guarded pub/sub
│   │   │   ├── Lifecycle.lua       # Player entity lifecycle
│   │   │   ├── DerivedState.lua    # CET-call state cache
│   │   │   ├── BlackboardCache2.lua # PlayerStateMachine polling
│   │   │   ├── Storage.lua         # Namespaced JSON KV
│   │   │   ├── Logger.lua          # Ring buffer + overlay
│   │   │   ├── Proximity.lua       # Distance queries + zones
│   │   │   ├── SpatialHash.lua     # Grid-based spatial indexing
│   │   │   └── Reference.lua       # Callable value holder
│   │   └── external/               # psiberx libs
│   │       ├── Cron.lua            # Delayed/periodic execution
│   │       ├── GameSession.lua     # Session state management
│   │       ├── GameUI.lua          # Game UI event detection
│   │       ├── GameHUD.lua         # HUD message display
│   │       ├── GameLocale.lua      # Locale/language utilities
│   │       ├── GameSettings.lua    # Game settings access
│   │       ├── EventProxy.lua      # UI event handler manager
│   │       └── Ref.lua             # Weak reference utility
│   ├── r6/scripts/                 # RedScript components
│   │   ├── EngineStateSystem.reds  # PSM blackboard caching
│   │   └── NPCWatcherSystem.reds   # NPC spawn/despawn hooks
│   └── docs/
│       └── 0-Engine-Readme.md      # 0-Engine's own documentation
```

**Rules:** Read-only. Never modify files in `dependencies/`. Updated manually when new versions are released.

---

## `reference/` — Inspiration Mods

```
reference/
├── README.md                           # What each reference provides
├── Mod Configuration Menu 31640 .../   # MCM v0.9.11 — config menu reference
│   ├── ModConfigurationMenu/           # CET UI layer (init.lua, mcm_ui/)
│   ├── ModConfigurationMenuAPI/        # Public API (modules/, bridges/)
│   └── 00_MCMNativeSettingsLifecycle/  # Native settings lifecycle
├── Redscript Config Framework 30726 .../ # DVRCF v1.3.0 — native config reference
│   └── r6/scripts/RedscriptConfigFramework/  # RedScript source files
├── Reflex Engine 31017 .../            # Reflex Engine v1.34.4 — UI component inspiration
│   └── ReflexEngine/                   # CET mod (init.lua, core.lua, UI/, Modules/)
└── ...
```

**Rules:** Read-only. Used for pattern reference only. Directories contain extracted mod packages.

---

## `patched/` — Mods Patched to Use Our Engines

> **Note:** This directory does not exist yet. It will be created when mods are patched to use our engines.

```
patched/
├── README.md                   # Patching guide, checklist
├── 0-Engine/                   # Mods patched to use 0-Engine
│   ├── #TestingMod/            # Integration test bed (DevKit)
│   ├── ReflexEngine/           # (if patched)
│   └── ...
└── UI-Engine/                  # Mods patched to use UI-Engine
    └── ...
```

---

## `deployment/` — Deployment Mechanism

```
deployment/
├── game/                       # Symlink to game CET mods folder (user creates)
└── vortex/                     # Symlink to Vortex staging (user creates)
```

**Rules:** `game/` and `vortex/` are user-created symlinks. The deploy script copies files to these directories.

---

## `scripts/` — Development Automation

```
scripts/
├── version.sh                  # Snapshot engines to versions/
├── deploy.sh                   # Deploy engines + deps + patched to game
├── lint.sh                     # Code quality checks
└── test.sh                     # Run test suite
```

| Script | Purpose | Usage |
|--------|---------|-------|
| `version.sh` | Copy all engines to `versions/vX.Y.Z/` with manifest | `./scripts/version.sh v0.1.0` |
| `deploy.sh` | Copy engines + deps + patched to game folder | `./scripts/deploy.sh [--vortex]` |
| `lint.sh` | Check Lua 5.1 compliance, module patterns, style | `./scripts/lint.sh` |
| `test.sh` | Run test suite via `tests/init.lua` | `./scripts/test.sh` |

---

## `tests/` — Shared Test Infrastructure

```
tests/
├── init.lua                    # Test runner
├── assert.lua                  # Assertion library
├── mocks/
│   ├── cet_mock.lua            # CET runtime mock
│   ├── imgui_mock.lua          # ImGui API mock
│   └── gameui_mock.lua         # GameUI mock
└── unit/                       # Unit test files
    ├── core_test.lua
    ├── events_test.lua
    ├── registry_test.lua
    ├── context_test.lua
    ├── tokens_test.lua
    ├── compose_test.lua
    ├── settings_test.lua
    ├── searchable_combo_box_test.lua  # SearchableComboBox tests
    ├── multi_select_test.lua          # MultiSelect tests
    └── card_test.lua                  # Card tests
```

### Test File Naming Convention

```
engines/0-Mod-Engine/core.lua          →  tests/unit/core_test.lua
engines/0-Mod-Engine/api/events.lua    →  tests/unit/events_test.lua
engines/0-Mod-Engine/ui/theme.lua      →  tests/unit/theme_test.lua
engines/0-Mod-Engine/cfg/core.lua      →  tests/unit/configengine_core_test.lua
```

---

## `versions/` — Version Snapshots

> **Note:** This directory does not exist yet. It is created by `scripts/version.sh` at version milestones.

```
versions/
├── README.md                   # Versioning system explanation
└── vX.Y.Z/                     # Snapshot directories (gitignored)
    └── 0-Mod-Engine/           # Copy of unified engine at snapshot time
```

**Rules:** `versions/` contents are gitignored (except README). Created by `scripts/version.sh`.

---

## `docs/` — Shared Documentation

```
docs/
├── ARCHITECTURE.md             # Module map, data flow, rendering pipeline
├── API.md                      # Full public API reference
├── CODESTYLE.md                # Lua coding conventions and patterns
├── CONTRIBUTING.md             # How to contribute, PR checklist
├── FILEMAP.md                  # This file — file-by-file breakdown
├── PATCHING.md                 # Guide for patching mods to use 0-Engine
└── plans/                      # AI-generated temporary work plans (gitignored)
    ├── InitRepoPlan.md         # Master plan
    ├── Phase0-SetupInfrastructure.md
    ├── Phase1-CoreFoundation.md
    └── ...
```

---

## Cross-Module Relationships

```mermaid
graph TB
    subgraph Dev["Development"]
        ENG["engines/"]
        DEP["dependencies/"]
        REF["reference/"]
        PAT["patched/"]
    end

    subgraph Tooling["Tooling"]
        SCR["scripts/"]
        TST["tests/"]
        DOC["docs/"]
    end

    subgraph Output["Output"]
        VER["versions/"]
        DEPLOY["deployment/"]
    end

    ENG -->|"version.sh"| VER
    ENG -->|"deploy.sh"| DEPLOY
    DEP -->|"deploy.sh"| DEPLOY
    PAT -->|"deploy.sh"| DEPLOY

    TST -->|"test.sh"| ENG
    SCR -->|"lint.sh"| ENG

    REF -.->|"patterns"| ENG
    DOC -.->|"guidelines"| ENG