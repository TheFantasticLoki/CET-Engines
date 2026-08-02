# CET Engine Workspace

Multi-engine CET (Cyber Engine Tweaks) mod development environment for Cyberpunk 2077. Supports the development, testing, versioning, and deployment of **UI-Engine** (active rewrite) and **Config-Engine** (future parallel plan).

---

## Directory Structure

```
CET-Engines/
├── AGENTS.md                               # AI agent guidelines (source of truth)
├── README.md                               # This file
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
│   └── 0-Engine/                           # 0-Engine stock v0.18.6 (DigitalVixen)
│
├── reference/                              # Inspiration mods (read-only)
│   ├── README.md                           # What each reference provides
│   ├── Reflex Engine/                      # UI component inspiration (v1.34.4)
│   ├── Mod Configuration Menu/             # Config menu reference (v0.9.11)
│   ├── Redscript Config Framework/         # Native config reference (v1.3.0)
│   └── ...
│
├── patched/                                # Mods patched to use our engines
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

## Quick Start

### Prerequisites

- Bash shell (Linux/macOS/WSL)
- Lua 5.1 interpreter (for tests)
- Git (for version tracking)

### Version Snapshots

Create a version snapshot of all engines:

```bash
./scripts/version.sh v0.1.0
./scripts/version.sh v0.1.0-core
```

Snapshots are copied to `versions/vX.Y.Z/` with a manifest file containing version, timestamp, git hash, file count, and line count.

### Deployment

Deploy engines + dependencies + patched mods to the game folder:

```bash
./scripts/deploy.sh              # Deploy to deployment/game/
./scripts/deploy.sh --vortex     # Deploy to game + Vortex staging
```

**Setup required**: Create symlinks for deployment targets:

```bash
# Game CET mods folder
ln -s /path/to/cyber_engine_tweaks/mods deployment/game

# Vortex staging (optional)
ln -s /path/to/vortex/staging deployment/vortex
```

### Testing

Run the test suite:

```bash
./scripts/test.sh
```

Tests use mocked CET, ImGui, and GameUI APIs — no game installation required.

### Code Quality

Run lint checks (Lua 5.1 compliance, module patterns, local usage):

```bash
./scripts/lint.sh
```

---

## Development Workflow

1. **Edit** code in `engines/UI-Engine/` (or `engines/Config-Engine/`)
2. **Test** locally: `./scripts/test.sh`
3. **Lint** for quality: `./scripts/lint.sh`
4. **Deploy** to game: `./scripts/deploy.sh`
5. **Verify** in-game by opening CET overlay
6. **Snapshot** at milestones: `./scripts/version.sh v0.X.0-<name>`

---

## For AI Agents

See [AGENTS.md](AGENTS.md) for comprehensive guidelines covering code organization, API design, error handling, theme system, performance, testing, documentation, versioning, and CET compatibility rules.

---

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — Module map, data flow, rendering pipeline
- [API Reference](docs/API.md) — Full public API surface
- [Code Style](docs/CODESTYLE.md) — Lua coding conventions
- [Contributing](docs/CONTRIBUTING.md) — How to contribute
- [File Map](docs/FILEMAP.md) — File-by-file breakdown
- [Patching Guide](docs/PATCHING.md) — How to patch mods to use our engines
- [Implementation Plans](docs/plans/) — Phase-by-phase rewrite plans