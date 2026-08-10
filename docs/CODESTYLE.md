# Code Style — UI-Engine

## Overview

Lua coding conventions for UI-Engine and all workspace modules. These rules enforce consistency, CET compatibility, and maintainability.

---

## Module Pattern

Every Lua file follows the module pattern:

```lua
local M = {}

-- Private functions and variables
local function helper()
    return 42
end

-- Public API
function M.publicFunction()
    return helper()
end

return M
```

**Rules:**
- Every file returns a table: `local M = {} ... return M`
- No exceptions — even single-function files
- One module per file, one clear responsibility
- The returned table is the public API surface

---

## Variable Naming

```lua
-- local variables: camelCase
local selectedMod = nil
local currentTheme = "Red"

-- constants: UPPER_SNAKE_CASE
local MAX_FRAME_LOGS = 512
local DEFAULT_THEME = "Dark"

-- module references: PascalCase
local Core = require("core")
local Logger = require("modules.logger")

-- function parameters: camelCase
local function drawButton(label, width, height)
    -- body
end
```

**Rules:**
- `local` for all variables and functions unless intentionally global
- Only `ModEngine` (and backward-compat aliases `UIEngine`, `ConfigEngine`, `LogEngine`) are intentional globals — never pollute `_G` otherwise
- Use descriptive names, avoid abbreviations except for common ones (`id`, `fn`, `ctx`)
- Private functions use `local function name()` (not exposed on module table)

---

## Indentation and Formatting

- **4 spaces** for indentation — no tabs
- **Max line length**: 120 characters (soft limit)
- **No trailing whitespace**
- **Single blank line** between functions
- **Two blank lines** between major sections

```lua
local M = {}

local function processItem(item)
    if item == nil then
        return nil
    end

    local result = {
        name = item.name,
        value = item.value * 2
    }

    return result
end

function M.getItems()
    local items = {}
    for i = 1, 10 do
        items[i] = processItem(i)
    end
    return items
end

return M
```

---

## Comments

```lua
-- Single line comment

--[[
    Multi-line comment block.
    Use for longer explanations.
]]

-- TODO: Something to fix later
-- FIXME: Known bug
-- NOTE: Important implementation detail
-- HACK: CET workaround (explain why)
```

**Rules:**
- `-- Single line` for inline comments
- `--[[ Multi-line ]]` for block comments
- Document *why*, not *what* (the code shows what)
- Mark CET workarounds with `-- HACK:` prefix

---

## Error Handling

### pcall Wrapping

All ImGui calls that may fail across CET versions must be wrapped in pcall:

```lua
-- Correct: pcall-wrapped
local ok, result = pcall(function()
    return ImGui.Button(label, width, height)
end)
if not ok then
    Logger.error("Button failed: " .. tostring(result))
    return false
end
return result
```

### ErrorBoundary

Every mod's `draw()` is wrapped in `Compose.ErrorBoundary()`:

```lua
function M.draw(ctx)
    -- ErrorBoundary is applied by ContentArea, not by the mod itself
    ctx.Column(function()
        ctx.Text("My content")
        ctx.Button("Click me")
    end)
end
```

### No Silent Failures

```lua
-- Wrong: silent failure
if not result then
    return  -- no error message, no log
end

-- Correct: log the failure
if not result then
    Logger.warn("Operation failed for mod: " .. modId)
    return false
end
```

---

## Require Paths

Always use module names relative to the mod root:

```lua
-- Correct
local Core = require("core")
local Logger = require("modules.logger")
local Events = require("api.events")
local Theme = require("ui.theme")

-- Wrong: path-style require
local Core = require("src/core")
local Logger = require("src/modules/logger")
```

**Rules:**
- `require("module")` relative to mod root
- No `require("path/to/module")` syntax
- Modules are loaded once and cached by Lua's `require` system

---

## Cross-Mod Dependencies

For 0-Mod-Engine, use direct `require()` since all modules are in the same mod:

```lua
-- Correct: require within the same mod
local Core = require("core")
local Events = require("api.events")
local Theme = require("ui.theme")
```

For cross-mod dependencies (different CET mods), use `GetMod()`:

```lua
-- Correct: lazy resolution via GetMod() for external mods
local function getOtherMod()
    local mod = GetMod("SomeOtherMod")
    if mod then
        return mod
    end
    return nil
end
```

**Why:** Mods may load in any order. `GetMod()` returns nil if the mod hasn't loaded yet, allowing graceful degradation.

---

## CET Compatibility

### Lua 5.1 Only

```lua
-- WRONG: Lua 5.2+ features
goto done          -- Lua 5.2+ goto
::done::           -- Lua 5.2+ labels
table.pack(t)      -- Lua 5.2+
table.unpack(t)    -- Lua 5.2+
-- __gc metamethod  -- Lua 5.2+

-- CORRECT: Lua 5.1 alternatives
-- Use if/elseif/else instead of goto
-- Use manual table construction instead of table.pack
-- Use select() for varargs instead of table.unpack
-- Use finalizers or manual cleanup instead of __gc
```

### Idempotent Initialization

```lua
local initialized = false

function M.init()
    if initialized then
        return  -- safe to call multiple times
    end
    initialized = true

    -- initialization logic
end
```

### Event Subscription Cleanup

```lua
local subscriptions = {}

function M.init()
    -- Clean up previous subscriptions
    for _, unsub in ipairs(subscriptions) do
        unsub()
    end
    subscriptions = {}

    -- Re-subscribe
    table.insert(subscriptions, Events.On("event", handler))
end
```

---

## Theme Push/Pop Balance

Every `PushTheme()` must have a matching `PopTheme()`:

```lua
-- Correct: balanced push/pop
Theme.PushTheme()
local ok, result = pcall(function()
    -- draw themed content
    ImGui.Button("Hello")
end)
Theme.PopTheme()
if not ok then
    Logger.error("Theme draw failed: " .. tostring(result))
end

-- Wrong: unbalanced (corrupts ImGui state)
Theme.PushTheme()
-- ... draw ...
-- Missing PopTheme() — NEVER do this
```

**Test requirement:** Every test that calls `PushTheme()` must verify `PopTheme()` is called.

---

## Performance

### No Per-Frame Polling

```lua
-- Wrong: polling every frame
function M.draw()
    local health = getPlayerHealth()  -- expensive CET call
    ctx.Text("Health: " .. health)
end

-- Correct: use events
Events.On("player:healthChanged", function(health)
    Core.setPlayerHealth(health)
end)

function M.draw()
    ctx.Text("Health: " .. Core.getPlayerHealth())
end
```

### Debounced Saves

```lua
-- Wrong: save on every keystroke
function M.onValueChanged(value)
    Storage.save("setting", value)  -- writes to disk every frame
end

-- Correct: debounce saves
local saveTimer = nil

function M.onValueChanged(value)
    Core.setSetting("setting", value)
    if saveTimer then
        Engine.ClearTimer(saveTimer)
    end
    saveTimer = Engine.SetTimeout(0.5, function()
        Engine.SetData("my-mod", "setting", Core.getSetting("setting"))
        saveTimer = nil
    end)
end
```

### Logger Rate Limiting

```lua
-- Wrong: log every frame
function M.update()
    Logger.debug("Updating position: " .. x .. "," .. y)  -- spam
end

-- Correct: rate-limited logging
local lastLogTime = 0

function M.update()
    local now = os.clock()
    if now - lastLogTime >= 1.0 then  -- max 1 per second
        Logger.debug("Updating position: " .. x .. "," .. y)
        lastLogTime = now
    end
end
```

---

## Shared Utilities

All shared helper functions go in `ui/utils.lua`. Never duplicate utilities across files.

```lua
-- ui/utils.lua
local M = {}

function M.Tooltip(text)
    if text and text ~= "" then
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text(text)
            ImGui.EndTooltip()
        end
    end
end

function M.SafeSelectable(label, selected)
    -- CET hover-state workaround
    -- ...
end

return M
```

**Usage:**
```lua
local Utils = require("ui.utils")

function M.draw()
    ImGui.Button("Hover me")
    Utils.Tooltip("This is a tooltip")
end
```

---

## Testing

### Test File Structure

```lua
-- tests/unit/myModule_test.lua
local assert = require("tests.assert")
local MyModule = require("engines.UI-Engine.myModule")

local M = {}

function M.testBasicFunctionality()
    local result = MyModule.doSomething()
    assert.assert_equal(result, expected, "Basic functionality should work")
end

function M.testErrorCase()
    assert.assert_error(function()
        MyModule.doSomethingInvalid()
    end)
end

return M
```

### Mock Usage

```lua
-- Use mocks for external dependencies
require("tests.mocks.cet_mock")
require("tests.mocks.imgui_mock")
require("tests.mocks.gameui_mock")
```

### Assertions

```lua
assert.assert_equal(actual, expected, "message")
assert.assert_true(value, "message")
assert.assert_false(value, "message")
assert.assert_not_nil(value, "message")
assert.assert_error(fn, "message")