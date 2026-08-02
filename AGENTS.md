# AI Agent Guidelines — CET Engine Workspace

> **This is the source of truth.** All agents working in this workspace must read this file first.

---

## Workspace Overview

This workspace contains a multi-engine CET (Cyber Engine Tweaks) mod development environment for Cyberpunk 2077. It supports the development, testing, versioning, and deployment of **UI-Engine** (active rewrite) and **Config-Engine** (future parallel plan).

The workspace is designed so agentic AI agents can start coding UI-Engine with a clean, well-documented repo.

---

## Directory Structure

```
CET-Engines/                         # Root workspace
├── AGENTS.md                               # AI agent guidelines (this file)
├── README.md                               # Workspace overview, quick start
│
├── docs/                                   # Shared documentation
│   ├── ARCHITECTURE.md                     # Module map, data flow, rendering pipeline
│   ├── API.md                              # Full public API reference
│   ├── CODESTYLE.md                        # Lua coding conventions and patterns
│   ├── CONTRIBUTING.md                     # How to contribute, PR checklist
│   ├── FILEMAP.md                          # File-by-file breakdown
│   ├── PATCHING.md                         # Guide for patching mods to use 0-Engine
│   └── plans/                              # AI-generated temporary work plans (gitignored)
│
├── engines/                                # Mods we develop (each is independent)
│   ├── UI-Engine/                          # UI framework — the rewrite target
│   └── Config-Engine/                      # Config management — future plan
│
├── dependencies/                           # Third-party deps (read-only, not modified)
│   ├── README.md                           # Explains each dependency
│   ├── 0-Engine/                           # 0-Engine stock v0.18.6 (DigitalVixen)
│   └── ...
│
├── reference/                              # Inspiration mods (read-only)
│   ├── README.md                           # What each reference provides
│   ├── Reflex Engine/                      # UI component inspiration (v1.34.4)
│   ├── Mod Configuration Menu/             # Config menu reference (v0.9.11)
│   ├── Redscript Config Framework/         # Native config reference (v1.3.0)
│   └── ...
│
├── patched/                                # Mods patched to use our engines
│   ├── README.md                           # Patching guide, checklist
│   ├── 0-Engine/                           # Mods patched to use 0-Engine
│   └── UI-Engine/                          # Mods patched to use UI-Engine
│
├── deployment/                             # Deployment mechanism
│   ├── game/                               # Symlink to game CET mods folder (user creates)
│   └── vortex/                             # Symlink to Vortex staging (user creates)
│
├── scripts/                                # Development automation
│   ├── version.sh                          # Snapshot engines to versions/
│   ├── deploy.sh                           # Deploy engines + deps + patched to game
│   ├── lint.sh                             # Code quality checks
│   └── test.sh                             # Run test suite
│
├── tests/                                  # Shared test infrastructure
│   ├── init.lua                            # Test runner
│   ├── assert.lua                          # Assertion library
│   ├── mocks/                              # CET, ImGui, GameUI mocks
│   └── unit/                               # Unit test files
│
└── versions/                               # Version snapshots (gitignored except README)
    └── README.md
```

---

## Good Practices to Cement

These practices must be followed throughout all development. They are enforced by the agent executing the plan.

### Code Organization

1. **`local` everywhere** — only public API symbols are global. Never pollute `_G` except for `_G.UIEngine`.
2. **Module pattern** — every file: `local M = {} ... return M`. No exceptions.
3. **One module per file** — each file has a single clear responsibility.
4. **No dead code** — if it's not used, remove it. Don't leave "just in case" code.
5. **Shared utilities** — `Tooltip()`, CET workarounds, and helper functions go in `ui/utils.lua`. Never duplicate utility functions across files.
6. **Consistent require paths** — always `require("module")` relative to the mod root, never `require("path/to/module")`.

### API Design

7. **Registration returns `true, nil` or `false, errorString`** — consistent success/failure pattern.
8. **Schema validation is strict** — missing required fields cause registration failure with clear error messages.
9. **Backward compatibility** — when changing the public API, deprecate before removing. Use `_G.UIEngine.Deprecated()` warnings.
10. **Context is the sole UI interface** — mods call `ctx.ToggleButton()`, never `ImGui.ToggleButton()`. The `ctx` proxy is the only way to access components.

### Error Handling

11. **pcall wrapping** — all ImGui calls that may fail across CET versions are wrapped in pcall. Reference: `Stock Mods/Reflex Engine/.../UI/ui.lua` pattern.
12. **ErrorBoundary** — every mod's `draw()` is wrapped in `Compose.ErrorBoundary()` to prevent one mod from crashing the entire frame.
13. **Graceful degradation** — if a module fails to load, the mod continues with reduced functionality. SafeRequire pattern in init.lua.
14. **No silent failures** — always log errors via Logger, never swallow them.

### Theme System

15. **Push/Pop balance** — `Theme.PushTheme()` must always be followed by `Theme.PopTheme()`. Imbalance corrupts ImGui state. Use the mock to verify balance in tests.
16. **Theme reads directly from Core** — no cached copies of theme state. `Core.currentTheme` is the single source of truth.
17. **WCAG compliance** — all color combinations must meet WCAG 2.0 contrast ratios. Use ColorEngine for validation.

### Performance

18. **No unnecessary polling** — use 0-Engine's events for game state, not per-frame polling.
19. **Debounced saves** — settings auto-save 0.5s after last change, not on every keystroke.
20. **Theme caching** — composite cache keys avoid redundant color resolution.
21. **Logger rate limiting** — max 1 debug message per frame to console.

### Testing

22. **Unit tests for every module** — each module has a corresponding `tests/unit/<module>_test.lua`.
23. **Mock all external dependencies** — CET, ImGui, GameUI are mocked. Tests run without the game.
24. **Integration test via #TestingMod** — the DevKit mod exercises the full `ctx` API surface.
25. **Theme push/pop balance test** — verify in test suite that Push is always followed by Pop.

### Documentation

26. **Update docs with code** — if you change the API, update `docs/API.md`. If you change architecture, update `docs/ARCHITECTURE.md`.
27. **Plans are temporary** — `docs/plans/` files are deleted after the work is complete.
28. **AGENTS.md is the source of truth** — agents read this file first. Keep it current.

### Versioning

29. **Semantic versioning** — `vMAJOR.MINOR.PATCH` with phase suffixes during development.
30. **Snapshot at milestones** — run `scripts/version.sh` at each phase boundary.
31. **Manifest includes context** — version, timestamp, git hash, file count, line count.

### CET Compatibility

32. **Lua 5.1 only** — no `goto`, no `__gc` metamethods, no `table.pack`/`table.unpack`.
33. **Load-order awareness** — mods may load before or after UI-Engine. Use `GetMod()` lazy resolution, not direct `require()`.
34. **Idempotent initialization** — `onInit` may fire multiple times (CET overlay toggle). Registration must be safe to repeat.
35. **No `_G` in CET** — CET's sandboxed Lua environment does not expose `_G`. Use direct global assignment (e.g., `UIEngine = {}`) instead of `_G.UIEngine = {}`. This applies to all global assignments including `onInit`, `onDraw`, `onShutdown`.

---

## CET Compatibility Rules (Detailed)

### Lua 5.1 Constraints
- **No `goto` statements** — Lua 5.1 does not support `goto`. Use `if/elseif/else` or function returns instead.
- **No `__gc` metamethod** — Lua 5.1 does not support `__gc` in metatables. Use `luasocket` cleanup or manual cleanup patterns.
- **No `table.pack` / `table.unpack`** — These are Lua 5.2+ functions. Use manual table construction or `select()` for varargs.
- **No `goto` labels** — Labels (`::label::`) are Lua 5.2+ syntax.

### Load-Order Awareness
- Mods may load before or after UI-Engine in CET.
- **Never use direct `require()`** for cross-mod dependencies. Use `GetMod()` for lazy resolution.
- Example: `local ui = GetMod("0-Engine-UI")` — returns nil if not loaded yet, mod must handle gracefully.
- Registration with UI-Engine should happen in `onInit`, which fires after all mods are loaded.

### Idempotent Initialization
- `onInit` may fire multiple times (CET overlay toggle reloads mods).
- Registration must be safe to repeat — calling `Register()` twice with the same ID should update, not duplicate.
- Event subscriptions must be cleaned up and re-subscribed, not accumulated.
- State initialization must check if already initialized and skip if so.

---

## Versioning Rules

### Semantic Versioning
- Format: `vMAJOR.MINOR.PATCH` (e.g., `v0.1.0`)
- During development, use phase suffixes: `v0.1.0-core`, `v0.2.0-theme`, etc.
- **MAJOR** — breaking API changes
- **MINOR** — new features, backward-compatible
- **PATCH** — bug fixes, backward-compatible

### Snapshot Process
- Run `./scripts/version.sh vX.Y.Z` at each phase boundary
- Creates a copy of all engines in `versions/vX.Y.Z/`
- Generates a manifest with version, timestamp, git hash, file count, line count
- Version snapshots are for non-git-based change history (git history is separate)

### Manifest Contents
```
Version: v0.1.0-core
Timestamp: 2025-01-15T10:30:00-05:00
Git Hash: abc1234
UI-Engine Files: 15
UI-Engine Lines: 2847
Config-Engine Files: 0
Config-Engine Lines: 0
```

---

## Deployment Rules

### Direct-Copy Deployment
- Deploy via `./scripts/deploy.sh` — copies engines + dependencies + patched mods to `deployment/game/`.
- User creates symlinks: `deployment/game/` → actual game CET mods folder.
- Optionally deploy to `deployment/vortex/` with `--vortex` flag for stable features.

### Deployment Targets
| Source | Destination |
|--------|-------------|
| `engines/UI-Engine/` | `deployment/game/0-Engine-UI/` |
| `engines/Config-Engine/` | `deployment/game/0-Engine-Config/` |
| `dependencies/0-Engine/` | `deployment/game/0-Engine/` |
| `patched/` content | `deployment/game/` (preserving structure) |

### Rules
- **Copy only** — never modify source files in the repo during deployment.
- **Validate paths** — deployment script checks that source and destination exist.
- **No auto-deploy** — deployment is always manual via script.

---

## Module Ownership

| Module | UI-Engine Owns | Config-Engine Owns |
|--------|---------------|-------------------|
| Components | All ~50+ widgets | Uses via ctx |
| Theme | Push/pop, color engine, 16 themes, tokens | Uses via UI-Engine API |
| Composition | Row, Column, Stack, Flex, Box, ErrorBoundary | — |
| Window | Overlay detection, sidebar, content area, cards | — |
| Context | Metatable proxy delegation | — |
| Events | Pub/sub system | Uses events |
| Logger | Ring buffer, overlay, file output | — |
| Settings | — | Persistence, migration, import/export |
| Storage | — | Atomic JSON key-value |
| Presets | — | Per-mod presets, collections |
| MCM Bridge | — | Provider adapter |
| Registration | Register/Unregister API | Schema validation for config |

---

## Testing Guidelines

- **Test runner**: `./scripts/test.sh` executes `tests/init.lua`
- **Mock everything external**: CET API, ImGui API, GameUI — tests must run without the game
- **Test file naming**: `tests/unit/<module>_test.lua`
- **Assertion library**: `tests/assert.lua` provides `assert_equal`, `assert_true`, `assert_false`, `assert_error`, `assert_not_nil`
- **Theme balance test**: Every test that uses PushTheme must verify PopTheme is called

---

## Code Style Quick Reference

- Use 4-space indentation
- `local` for all variables and functions unless intentionally global
- Module pattern: `local M = {} ... return M`
- Comments: `-- Single line` for inline, `--[[ Multi-line ]]` for blocks
- No trailing whitespace
- No tabs — spaces only
- Max line length: 120 characters (soft limit)