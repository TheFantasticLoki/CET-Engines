# Contributing — CET Engine Workspace

## Overview

Guidelines for contributing to the UI-Engine rewrite and related workspace modules.

---

## Getting Started

1. Read `AGENTS.md` — the source of truth for all agent guidelines
2. Read `docs/ARCHITECTURE.md` — understand the module structure
3. Read `docs/CODESTYLE.md` — follow Lua coding conventions
4. Read `docs/API.md` — understand the public API surface

---

## Development Workflow

1. **Create a feature branch** from `main`
2. **Write code** following the code style guide
3. **Write tests** for new functionality in `tests/unit/`
4. **Run tests**: `./scripts/test.sh`
5. **Run lint**: `./scripts/lint.sh`
6. **Update documentation** if API or architecture changed
7. **Create a PR** with a clear description

---

## PR Checklist

Before submitting a pull request, verify:

### Code Quality
- [ ] All code follows `docs/CODESTYLE.md` conventions
- [ ] No `goto`, `__gc`, `table.pack`, or `table.unpack` (Lua 5.1 only)
- [ ] All variables and functions are `local` (except `ModEngine` global)
- [ ] Module pattern: `local M = {} ... return M`
- [ ] No dead code left in the file
- [ ] No tabs — 4 spaces only
- [ ] No trailing whitespace
- [ ] Max line length 120 characters

### Testing
- [ ] Unit tests added for new modules in `tests/unit/`
- [ ] All existing tests still pass: `./scripts/test.sh`
- [ ] Test covers both success and error cases
- [ ] Theme push/pop balance tested if applicable

### Documentation
- [ ] `docs/API.md` updated if public API changed
- [ ] `docs/ARCHITECTURE.md` updated if module structure changed
- [ ] `docs/FILEMAP.md` updated if new files added
- [ ] `docs/CODESTYLE.md` updated if new conventions added
- [ ] `AGENTS.md` updated if guidelines changed

### CET Compatibility
- [ ] No Lua 5.2+ features used
- [ ] Cross-mod dependencies use `GetMod()`, not `require()`
- [ ] `onInit` is idempotent (safe to call multiple times)
- [ ] Event subscriptions are cleaned up on `Unregister()`

### Error Handling
- [ ] ImGui calls wrapped in pcall where needed
- [ ] No silent failures — all errors logged via Logger
- [ ] ErrorBoundary wraps mod draw functions
- [ ] Graceful degradation when modules fail to load

### Theme System
- [ ] `PushTheme()` always balanced with `PopTheme()`
- [ ] No direct ImGui style calls bypassing Theme engine
- [ ] Color combinations meet WCAG 2.0 contrast ratios

---

## Code Review Process

1. **Automated checks** must pass (tests, lint)
2. **Manual review** for code quality, architecture, and patterns
3. **CET compatibility** verified by reviewer
4. **Documentation** reviewed for completeness
5. **Merge** after approval

### Review Criteria

| Criteria | Weight | Description |
|----------|--------|-------------|
| Correctness | High | Does it work as intended? |
| CET Compatibility | High | Lua 5.1, load-order awareness, idempotency |
| Error Handling | High | pcall wrapping, no silent failures |
| Code Style | Medium | Follows conventions, clean code |
| Testing | Medium | Adequate test coverage |
| Documentation | Medium | Docs updated to match changes |
| Performance | Low | No unnecessary polling, debounced saves |

---

## Testing Requirements

### New Modules

Every new module in `engines/0-Mod-Engine/` must have a corresponding test file:

```
engines/0-Mod-Engine/core.lua  →  tests/unit/core_test.lua
engines/0-Mod-Engine/api/events.lua  →  tests/unit/events_test.lua
```

### Test File Structure

```lua
-- tests/unit/myModule_test.lua
local assert = require("tests.assert")
local MyModule = require("engines.UI-Engine.myModule")

local M = {}

function M.testFeature()
    local result = MyModule.doSomething()
    assert.assert_equal(result, expected)
end

function M.testError()
    assert.assert_error(function()
        MyModule.doSomethingInvalid()
    end)
end

return M
```

### Running Tests

```bash
./scripts/test.sh
```

Tests run without the game using mocked CET, ImGui, and GameUI APIs.

---

## Documentation Requirements

### When to Update Docs

| Change | Files to Update |
|--------|-----------------|
| New public API method | `docs/API.md` |
| New module created | `docs/FILEMAP.md`, `docs/ARCHITECTURE.md` |
| Module dependency changed | `docs/ARCHITECTURE.md` |
| New coding convention | `docs/CODESTYLE.md`, `AGENTS.md` |
| New deployment step | `README.md` |
| New patching method | `docs/PATCHING.md` |

### Documentation Standards

- Use Markdown format
- Include code examples for API methods
- Include type signatures (Lua types or descriptions)
- Include error cases and edge cases
- Keep examples runnable (copy-paste testable)

---

## Commit Messages

Use clear, descriptive commit messages with the `Label(Scope): Message` format:

```
feat(UI-Engine): Add AdvancedSlider component with modifier keys

- Support Alt/Shift/Ctrl for fine/coarse/batch adjustment
- Add tick marks at configurable intervals
- Include inline input for precise value entry
- Add unit tests for modifier key behavior

Refs: Phase 3, Step 7
```

### Commit Format

```
<Label>(<Scope>): <short description>

<detailed description>

<optional references>
```

### Labels

| Label | Description |
|-------|-------------|
| `feat`, `feature` | New feature |
| `fix`, `bugfix`, `fixed` | Bug fix |
| `hotfix` | Critical hotfix |
| `docs`, `doc`, `documentation` | Documentation only |
| `test`, `tests`, `testing` | Adding or updating tests |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `chore` | Build process, tooling, or infrastructure |
| `style`, `css` | Code style change (formatting, whitespace) |
| `ui` | UI changes |
| `perf`, `performance` | Performance improvements |
| `optimize` | Optimization |
| `build` | Build system changes |
| `ci` | Continuous integration |
| `cd` | Continuous deployment |
| `deploy`, `release` | Deployment or release |
| `deps`, `dep`, `dependencies` | Dependency changes |
| `revert` | Revert a previous commit |
| `wip` | Work in progress |
| `security` | Security changes |
| `i18n` | Internationalization |
| `a11y` | Accessibility |
| `api` | API changes |
| `data` | Data changes |
| `config` | Configuration changes |
| `init` | Initialization |
| `added`, `add` | Adding new files or features |
| `update`, `updated` | Updating existing features |
| `removed`, `remove`, `delete`, `del` | Removing files or features |

### Scopes

| Scope | Description |
|-------|-------------|
| `UI-Engine` | UI-Engine module changes |
| `Config-Engine` | Config-Engine module changes |
| `core` | Core state store |
| `logger` | Logger module |
| `storage` | Storage module |
| `events` | Events module |
| `utils` | Utilities module |
| `init` | Entry point |
| `theme` | Theme system |
| `components` | Component library |
| `window` | Window system |
| `context` | Context proxy |
| `registry` | Registration system |
| `tests` | Test infrastructure |
| `scripts` | Build/deploy scripts |
| `docs` | Documentation |
| `mocks` | Mock infrastructure |

---

## Issue Reporting

When reporting issues:

1. **Describe the problem** clearly
2. **Steps to reproduce** the issue
3. **Expected behavior** vs actual behavior
4. **CET version** and Lua version
5. **Error messages** from CET console
6. **Screenshots** if applicable

---

## Architecture Decisions

For significant architectural changes:

1. **Create an issue** describing the proposed change
2. **Discuss alternatives** and trade-offs
3. **Get approval** before implementing
4. **Update documentation** to reflect the decision
5. **Update `AGENTS.md`** if guidelines change

---

## Versioning

Follow semantic versioning: `vMAJOR.MINOR.PATCH`

- **MAJOR**: Breaking API changes
- **MINOR**: New features, backward-compatible
- **PATCH**: Bug fixes, backward-compatible

During development, use phase suffixes: `v0.1.0-core`, `v0.2.0-theme`, etc.

Create snapshots at milestones: `./scripts/version.sh vX.Y.Z`