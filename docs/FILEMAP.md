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
| `CET_DRAWLIST_GUIDE.md` | **CRITICAL** — CET DrawList API guide explaining the userdata bracket indexing limitation and correct static function pattern for custom rendering. |

---

## `engines/` — Mods We Develop

> **Note:** Phases 0-2 are complete. The following files exist in `engines/UI-Engine/`:
> - `init.lua` (406 lines) — Entry point, SafeRequire, public API ✅
> - `core.lua` (362 lines) — Centralized state store ✅
> - `api/events.lua` (150 lines) — Pub/sub event system ✅
> - `modules/logger.lua` (264 lines) — Leveled logging ✅
> - `modules/storage.lua` (195 lines) — Atomic JSON key-value ✅
> - `ui/utils.lua` (103 lines) — Shared utilities ✅
> - `config/default_config.lua` (88 lines) — Default configuration values ✅
> - `config/themes.lua` (359 lines) — 16 built-in themes ✅
> - `ui/color_engine.lua` (280 lines) — WCAG color science ✅
> - `ui/tokens.lua` (203 lines) — Design tokens ✅
> - `ui/theme.lua` (562 lines) — Theme push/pop engine ✅
>
> The detailed structure below shows the planned architecture for all phases.

```
engines/
├── UI-Engine/                    # UI framework (active rewrite)
│   ├── init.lua                  # Entry point, SafeRequire, public API
│   ├── core.lua                  # Centralized state store
│   ├── api/
│   │   ├── registry.lua          # Register/RegisterWindow/Unregister
│   │   ├── context.lua           # Themed ctx metatable proxy
│   │   ├── events.lua            # Pub/sub event system
│   │   └── init.lua              # API barrel re-export
│   ├── ui/
│   │   ├── window.lua            # Main window orchestrator
│   │   ├── sidebar.lua           # Sidebar with categorized mod list
│   │   ├── content_area.lua      # Content dispatch to mod draw()
│   │   ├── card.lua              # Card header component
│   │   ├── settings_panel.lua    # 5-tab settings UI
│   │   ├── theme.lua             # Theme push/pop engine
│   │   ├── color_engine.lua      # WCAG color science
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
│   │   └── storage.lua           # Atomic JSON key-value (may move to Config-Engine)
│   ├── config/
│   │   ├── default_config.lua    # Default configuration values
│   │   └── themes.lua            # 16 built-in theme definitions
│   ├── mcm_bridge/
│   │   └── init.lua              # MCM provider adapter (may move to Config-Engine)
│   └── examples/
│       └── example_consumer.lua  # Integration example for mod authors
│
└── Config-Engine/                # Config management (consumer app)
    ├── init.lua                  # Entry point, CET hooks, UIEngine registration
    ├── core.lua                  # Config-Engine state store (extends UI-Engine Core)
    ├── modules/
    │   ├── mod_manager.lua       # Mod discovery, registration, lifecycle
    │   ├── settings_schema.lua   # Schema definitions, validation, types
    │   ├── settings_renderer.lua # Schema → ImGui auto-generation
    │   ├── settings_resolver.lua # Schema merging, defaults, validation
    │   ├── render_mode.lua       # Detect schema/custom/hybrid/external modes
    │   ├── undo_redo.lua         # Undo/redo system (command pattern, ring buffer)
    │   └── state_sync.lua        # Sync to UI-Engine Storage, auto-save
    ├── ui/
    │   ├── window.lua            # Main window orchestrator (sidebar + content)
    │   ├── sidebar.lua           # Sidebar: mod list, search, categories
    │   └── content_area.lua      # Content dispatch to mod's draw/schema
    └── config/
        ├── default_config.lua    # Config-Engine defaults
        └── categories.lua        # Built-in category definitions
```

### UI-Engine Module Relationships

```
init.lua
  ├── core.lua              (state store)
  ├── modules/logger.lua    (logging)
  ├── modules/storage.lua   (persistence)
  ├── api/events.lua        (pub/sub)
  ├── config/themes.lua     (theme definitions)
  ├── ui/tokens.lua         (design tokens)
  ├── ui/color_engine.lua   (color science)
  ├── ui/theme.lua          (theme engine)
  ├── ui/components/        (widget library)
  ├── api/context.lua       (context proxy)
  ├── api/registry.lua      (registration)
  ├── ui/window.lua         (window orchestrator)
  └── features/             (favorites, presets)
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
engines/UI-Engine/core.lua  →  tests/unit/core_test.lua
engines/UI-Engine/api/events.lua  →  tests/unit/events_test.lua
```

---

## `versions/` — Version Snapshots

> **Note:** This directory does not exist yet. It is created by `scripts/version.sh` at version milestones.

```
versions/
├── README.md                   # Versioning system explanation
└── vX.Y.Z/                     # Snapshot directories (gitignored)
    ├── UI-Engine/              # Copy of UI-Engine at snapshot time
    ├── Config-Engine/          # Copy of Config-Engine (if exists)
    └── manifest.txt            # Version metadata
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