# Test Infrastructure Analysis

> **Purpose:** Comprehensive analysis of the current test systems and options for rewriting tests from scratch.

---

## Current Test Systems Overview

The codebase has **two separate test systems** that evolved independently:

| System | Location | Purpose | Runs |
|--------|----------|---------|------|
| **Out-of-Game Tests** | `tests/` | Unit tests with mocks | Lua 5.1 interpreter (no game) |
| **In-Game Tests** | `cfg/test_runner.lua` + DevKit | Integration tests | Inside CET overlay |

---

## 1. Out-of-Game Test System

### Structure

```
tests/
├── init.lua              # Test runner (discovers + runs tests)
├── assert.lua            # Assertion library
├── mocks/                # CET/ImGui/GameUI mocks
│   ├── cet_mock.lua      # CET API mocks (GetMod, registerForEvent, etc.)
│   ├── imgui_mock.lua    # ImGui API mocks (widgets, drawing, etc.)
│   └── gameui_mock.lua   # GameUI mocks
└── unit/                 # Test files (one per module)
    ├── core_test.lua
    ├── events_test.lua
    ├── registry_test.lua
    ├── context_test.lua
    ├── ... (42 test files total)
    └── configengine_*.lua (11 config engine tests)
```

### Test Runner (`tests/init.lua`)

- **Auto-discovery**: Finds all `*_test.lua` files in `tests/unit/`
- **Convention**: Test functions must start with `test` (e.g., `testDefaultValues`)
- **Execution**: Each test function is pcall-wrapped
- **Output**: ANSI-colored pass/fail with error details
- **Mock loading**: Loads mocks before running tests

### Assertion Library (`tests/assert.lua`)

Provides:
- `assert_equal(actual, expected, message)`
- `assert_true(value, message)`
- `assert_false(value, message)`
- `assert_nil(value, message)`
- `assert_not_nil(value, message)`
- `assert_error(fn, message)`

### Mock System (`tests/mocks/`)

**What's mocked:**

| Mock | Covers | Notes |
|------|--------|-------|
| `cet_mock.lua` | GetMod, registerForEvent, json, Game, Cron, TweakDB, GameOptions, spdlog, Observe/Override | Recently rewritten with full CET API coverage |
| `imgui_mock.lua` | All ImGui widgets, enums, draw list functions | Recently rewritten with 900+ functions |
| `gameui_mock.lua` | GameUI.IsInputEnabled, screen resolution, HUD | Basic coverage |

**Mock quality**: High — mocks now accurately reflect the CET API based on type definitions in `dependencies/lua-libs/`.

### Current Test Status

- **42 test files** covering UI-Engine and Config-Engine modules
- **345 tests passing, 70 failing** (as of 2026-08-09)
- **Failures are NOT mock-related** — they're outdated tests testing removed functions

### Problems with Current System

1. **Pre-unification code**: Tests were written for the old split `UI-Engine/Config-Engine` structure
2. **Dead code references**: Many tests call functions that were removed in cleanup
3. **Inconsistent patterns**: Some tests use setup/teardown, others don't
4. **No integration testing**: Can't test ImGui rendering, theme application, or window management
5. **Mock limitations**: Can't test actual CET behavior (overlay, hotkeys, etc.)

---

## 2. In-Game Test System

### Structure

```
engines/0-Mod-Engine/
├── cfg/
│   ├── test_runner.lua    # Test execution engine
│   └── test_results.lua   # Result storage with history
└── cfg/ui/
    └── content_area.lua   # Renders test results in UI

patched/UI-Engine-DevKit/
├── init.lua               # Config-Engine registration
├── env.lua                # Shared state
├── helpers.lua            # Pass/Fail helpers
├── tests.lua              # Automated API test suite
└── tab_*.lua              # UI tabs for different test categories
```

### Test Runner (`cfg/test_runner.lua`)

**Key features:**
- **Test granularity**: `startup` (auto-run), `full` (on-demand), `debug` (diagnostic)
- **pcall-wrapped**: Errors never propagate across mods
- **Timeout detection**: Warns if tests take too long
- **Result storage**: In-memory with 5-entry history per mod

**API:**
```lua
TestRunner.runModTests(modId, mode)     -- Run tests for one mod
TestRunner.runStartupTests()            -- Run all startup tests
TestRunner.runAllTests(mode)            -- Run all mods in a mode
```

### Test Results (`cfg/test_results.lua`)

**Storage:**
- In-memory results per mod
- 5-entry history ring buffer per mod
- Aggregate stats (total, passing, failing, errors)

**API:**
```lua
TestResults.set(modId, mode, result)   -- Store results
TestResults.get(modId)                 -- Get latest results
TestResults.getAggregateStats()        -- Get summary stats
TestResults.getStatusIcon(modId)       -- Get status icon/color
```

### DevKit Test Suite (`patched/UI-Engine-DevKit/`)

**Comprehensive API coverage:**
- Public API tests (GetVersion, GetTheme, SetTheme, etc.)
- Registry API tests (register, unregister, getMod)
- Context API tests (create, getState, setState)
- Windows API tests (register, getWindowIds)
- Events API tests (On, Emit, unsubscribe)
- Core State tests (IsRegistered, Register)
- Component Proxy tests (verifies all 65 components)

**UI Tabs:**
- API Tests (pass/fail results)
- Components (live demos)
- Themes (browser + switcher)
- Icons (explorer)
- Registry (demo)
- Context (demo)
- Windows (demo)
- Events (demo)
- Log Engine (integration)
- Diagnostics (dump)

### How In-Game Tests Work

1. **Registration**: Mods register tests via `RegisterMod()` with a `tests` table:
   ```lua
   ModEngine.RegisterMod("my-mod", {
       tests = {
           startup = function(ctx) ... end,  -- Auto-run
           full = function(ctx) ... end,      -- On-demand
           debug = function(ctx) ... end,     -- Diagnostic
       },
   })
   ```

2. **Execution**: TestRunner calls the test function with a `testCtx`:
   ```lua
   local testCtx = {
       core = Core,
       modId = modId,
       settings = mod.settings or {},
   }
   local ok, result = pcall(testFn, testCtx)
   ```

3. **Result format**: Test functions return a result table:
   ```lua
   return {
       passed = 10,
       failed = 1,
       warnings = 0,
       details = { ... },
   }
   ```

4. **Display**: Results render in Config-Engine's content area with pass/fail counts

---

## 3. Key Differences Between Systems

| Aspect | Out-of-Game | In-Game |
|--------|-------------|---------|
| **Environment** | Lua 5.1 interpreter | CET overlay (LuaJIT) |
| **ImGui** | Mocked (no rendering) | Real ImGui (actual rendering) |
| **CET API** | Mocked | Real CET API |
| **Game state** | Not available | Full game access |
| **Purpose** | Unit tests, fast iteration | Integration tests, visual verification |
| **Speed** | Fast (seconds) | Slow (requires game) |
| **CI/CD** | Yes (script.sh) | No (manual) |

---

## 4. Options for Rewriting Tests

### Option A: Unified Test Framework (Recommended)

**Concept**: Create a single test framework that works both in-game and out-of-game.

**Architecture:**
```
tests/
├── framework/              # Shared test framework
│   ├── init.lua           # Core test runner
│   ├── assert.lua         # Assertions (same for both)
│   ├── runner.lua         # Test discovery + execution
│   └── reporter.lua       # Result reporting
├── mocks/                 # Out-of-game mocks
│   ├── cet_mock.lua
│   ├── imgui_mock.lua
│   └── gameui_mock.lua
├── unit/                  # Unit tests (out-of-game)
│   ├── core_test.lua
│   └── ...
└── integration/           # Integration tests (in-game)
    ├── api_test.lua
    ├── component_test.lua
    └── theme_test.lua
```

**How it works:**

1. **Shared test functions**: Write tests once, run anywhere:
   ```lua
   -- tests/unit/core_test.lua
   local M = {}
   
   function M.testDefaultValues(ctx)
       local Core = ctx.Core
       assert.equal(Core.getCurrentTheme(), "Dark")
   end
   
   return M
   ```

2. **Out-of-game runner**: Uses mocks, runs in Lua 5.1:
   ```lua
   -- tests/runner_outofgame.lua
   local mocks = require("tests.mocks")
   mocks.loadAll()
   
   local testModule = require("tests.unit.core_test")
   testModule.testDefaultValues({ Core = require("core") })
   ```

3. **In-game runner**: Uses real CET, runs in overlay:
   ```lua
   -- tests/runner_ingame.lua
   local testModule = require("tests.unit.core_test")
   testModule.testDefaultValues({ Core = ModEngine.Core })
   ```

**Pros:**
- Write tests once, run in both environments
- Consistent test patterns
- Easy to migrate existing tests
- Can run fast unit tests in CI/CD

**Cons:**
- Requires careful API abstraction
- Some tests may need environment-specific branches

---

### Option B: Enhanced In-Game Testing

**Concept**: Focus on the in-game test system, make it the primary testing method.

**Enhancements:**
1. **Auto-discovery**: Scan registered mods for test functions
2. **Test categories**: Organize by module/feature
3. **Visual reporting**: Enhanced UI with detailed results
4. **Export results**: Save test results to file for CI/CD
5. **Snapshot testing**: Compare ImGui output between runs

**Architecture:**
```
engines/0-Mod-Engine/
├── cfg/
│   ├── test_runner.lua    # Enhanced with auto-discovery
│   ├── test_results.lua   # Enhanced with export
│   └── test_reporter.lua  # NEW: Visual reporting
```

**Pros:**
- Tests real CET behavior
- Can test ImGui rendering
- Visual verification
- Better integration testing

**Cons:**
- Requires game to run
- Slow iteration
- No CI/CD automation
- Harder to debug failures

---

### Option C: Hybrid Approach

**Concept**: Keep both systems but make them share more code.

**Shared components:**
- Assertion library (same for both)
- Test discovery (convention-based)
- Result format (same structure)
- Mock interfaces (abstract away CET-specifics)

**Separate components:**
- Test runners (environment-specific)
- Mock implementations (CET vs real)
- Reporting (console vs ImGui)

**Pros:**
- Leverages existing work
- Clear separation of concerns
- Can evolve independently

**Cons:**
- More code to maintain
- Potential drift between systems
- Duplication in test patterns

---

### Option D: LuaUnit-Based Framework

**Concept**: Use LuaUnit (mature Lua testing framework) as the base.

**Architecture:**
```
tests/
├── luaunit.lua           # LuaUnit framework (single file)
├── run_outofgame.lua     # Out-of-game runner
├── run_ingame.lua        # In-game runner
├── mocks/                # Mocks for out-of-game
└── test_*.lua            # Test files (LuaUnit style)
```

**LuaUnit features:**
- Rich assertion library
- Test discovery
- Output formatting (text, TAP, JUnit XML)
- Test groups and tags
- Setup/teardown

**Pros:**
- Battle-tested framework
- Rich features out of the box
- Good documentation
- TAP/JUnit output for CI/CD

**Cons:**
- External dependency (single file, but still)
- Different API than current tests
- May not fit CET's Lua 5.1 constraints

---

## 5. Recommended Approach: Option A (Unified Framework)

### Why Option A?

1. **Single source of truth**: Tests are written once, not duplicated
2. **Fast iteration**: Unit tests run in seconds without the game
3. **CI/CD ready**: Out-of-game tests can run in automated pipelines
4. **Integration coverage**: In-game tests verify real CET behavior
5. **Maintainability**: Less code to maintain than separate systems

### Implementation Plan

**Phase 1: Framework Core**
- Create `tests/framework/` with shared components
- Refactor assertion library to work in both environments
- Create abstract `ctx` provider (mock vs real)

**Phase 2: Out-of-Game Migration**
- Rewrite unit tests using new framework
- Update test runner to use framework
- Verify all tests pass with mocks

**Phase 3: In-Game Integration**
- Create in-game runner that uses framework
- Update DevKit to use framework
- Verify tests pass in CET overlay

**Phase 4: Cleanup**
- Remove old test files
- Update documentation
- Add CI/CD integration

---

## 6. Test Categories for Rewriting

Based on the current codebase, here are the recommended test categories:

### Unit Tests (Out-of-Game)

| Category | Modules | Priority |
|----------|---------|----------|
| **Core State** | `core.lua`, `cfg/core.lua` | High |
| **Events** | `api/events.lua` | High |
| **Registry** | `api/registry.lua` | High |
| **Context** | `api/context.lua` | High |
| **Theme** | `ui/theme.lua`, `config/themes.lua` | High |
| **Components** | `ui/components/*.lua` | Medium |
| **Settings** | `cfg/settings_*.lua` | Medium |
| **Storage** | `modules/storage.lua` | Medium |
| **Logger** | `modules/logger.lua`, `log/` | Medium |
| **Animation** | `ui/animation.lua` | Low |
| **Color Engine** | `ui/color_engine.lua` | Low |
| **Tokens** | `ui/tokens.lua` | Low |

### Integration Tests (In-Game)

| Category | Scope | Priority |
|----------|-------|----------|
| **API Surface** | All public ModEngine.* methods | High |
| **Component Rendering** | All 65 components via ctx | High |
| **Theme Application** | Push/pop balance, color application | High |
| **Window Management** | Register, draw, unregister | Medium |
| **Config-Engine** | Settings schema, render, resolve | Medium |
| **Log-Engine** | File output, rotation | Medium |
| **Cross-Mod** | GetMod, events between mods | Low |

---

## 7. Key Patterns to Preserve

From the current test infrastructure, these patterns should be preserved:

### 1. Test Convention
```lua
local M = {}

function M.testFeatureName()
    -- test body
end

return M
```

### 2. Setup/Teardown
```lua
local function setup()
    Core.reset()
    Core.init()
end

function M.testSomething()
    setup()
    -- test body
end
```

### 3. pcall Wrapping
```lua
function M.testRiskyOperation()
    local ok, result = pcall(function()
        -- risky code
    end)
    assert_true(ok, "Should not throw")
end
```

### 4. Event Cleanup
```lua
function M.testEvents()
    -- Subscribe
    local unsub = Events.on("test", handler, "source")
    
    -- Test
    Events.emit("test")
    
    -- Cleanup
    unsub()
end
```

---

## 8. Next Steps

1. **Review this analysis** with the team
2. **Choose approach** (recommended: Option A)
3. **Create framework prototype** in `tests/framework/`
4. **Rewrite one module's tests** as proof of concept
5. **Iterate** based on learnings
6. **Migrate remaining tests** incrementally

---

*Created: 2026-08-09*
*Status: Analysis complete, awaiting decision on approach*
