# Patching Guide — CET Engine Workspace

## Overview

Step-by-step guide for patching existing CET mods to use UI-Engine or 0-Engine.

---

## What is Patching?

Patching a mod means modifying it to use UI-Engine or 0-Engine instead of (or alongside) its own implementation. This allows mods to benefit from:

- **0-Engine**: Event-driven architecture, state caching, lifecycle management
- **UI-Engine**: Themed UI components, consistent look and feel, context API

---

## Before Patching

### Checklist

- [ ] Understand what the mod currently does
- [ ] Identify which UI-Engine/0-Engine features are relevant
- [ ] Create a backup of the original mod
- [ ] Test the mod in its unpatched state
- [ ] Read `docs/API.md` for the relevant API surface

### Triage by Impact

Prioritize mods that benefit most from patching:

| Priority | Mod Type | Reason |
|----------|----------|--------|
| High | Mods with per-frame polling | 0-Engine events eliminate polling |
| High | Mods with custom UI | UI-Engine provides themed components |
| Medium | Mods with settings persistence | 0-Engine Storage provides atomic writes |
| Medium | Mods with state management | 0-Engine DerivedState simplifies caching |
| Low | Mods with simple text output | Minimal benefit from patching |

---

## Patching to Use 0-Engine

### Step 1: Add Dependency Reference

In the mod's `init.lua`, add a lazy reference to 0-Engine:

```lua
-- In your mod's init.lua
local function get0Engine()
    local engine = GetMod("0-Engine")
    if engine then
        return engine
    end
    return nil
end
```

### Step 2: Register Event Subscriptions

Replace per-frame polling with event subscriptions:

```lua
-- Before: per-frame polling
function M.onDraw()
    local health = getPlayerHealth()  -- expensive call every frame
    -- ... use health ...
end

-- After: event-driven
function M.onInit()
    local engine = get0Engine()
    if engine then
        engine.Subscribe("SprintStateChanged", function(isSprinting)
            M.cachedSprint = isSprinting
        end)
    end
end

function M.onDraw()
    -- Use cached value instead of polling
    local sprint = M.cachedSprint or false
    -- ... use sprint ...
end
```

### Step 3: Use Lifecycle Hooks

Replace manual state management with 0-Engine lifecycle:

```lua
-- Before: manual state management
local isInitialized = false

function M.onInit()
    if isInitialized then return end
    isInitialized = true
    -- ... initialize ...
end

-- After: use 0-Engine Lifecycle
function M.onInit()
    local engine = get0Engine()
    if engine then
        engine.WhenReady(function(player)
            -- ... initialize ...
        end)
    end
end
```

### Step 4: Use Storage for Persistence

Replace manual JSON file management with 0-Engine Storage:

```lua
-- Before: manual file I/O
function M.saveSettings()
    local file = io.open(path, "w")
    file:write(json.encode(settings))
    file:close()
end

-- After: use 0-Engine Storage
function M.saveSettings()
    local engine = get0Engine()
    if engine then
        engine.SetData("my-mod", "settings", settings)
    end
end
```

### Step 5: Test the Patched Mod

```bash
# Deploy to game folder
./scripts/deploy.sh

# Launch game and test:
# 1. Open CET overlay
# 2. Verify mod loads without errors
# 3. Test all features
# 4. Check CET console for errors
```

---

## Patching to Use UI-Engine

### Step 1: Add Dependency Reference

```lua
-- In your mod's init.lua
local function getModEngine()
    local engine = GetMod("0-Mod-Engine")
    if engine then
        return engine
    end
    return nil
end
```

### Step 2: Register with ModEngine

Replace custom window/UI code with ModEngine registration:

```lua
-- Before: custom window management
function M.init()
    -- Create custom ImGui window
    -- Handle overlay detection
    -- Manage window state
end

-- After: register with ModEngine
function M.onInit()
    local engine = getModEngine()
    if engine then
        engine.Register("my-mod", {
            title = "My Mod",
            version = "1.0.0",
            draw = function(ctx)
                -- Draw using UI-Engine components
            end
        })
    end
end
```

### Step 3: Replace ImGui Calls with ctx

Replace raw ImGui calls with UI-Engine context methods:

```lua
-- Before: raw ImGui
ImGui.Text("My Setting")
local changed, value = ImGui.SliderFloat("##setting", currentValue, 0, 100)
if changed then
    currentValue = value
end

-- After: UI-Engine context
ctx.Text("My Setting")
local newValue = ctx.SliderFloat("My Setting", currentValue, 0, 100)
if newValue ~= currentValue then
    currentValue = newValue
end
```

### Step 4: Use Themed Components

Replace custom styling with UI-Engine themed components:

```lua
-- Before: custom styled button
ImGui.PushStyleColor(ImGuiCol.Button, myColor)
if ImGui.Button("Enable") then
    toggle()
end
ImGui.PopStyleColor()

-- After: themed toggle button
local newValue = ctx.ToggleButton("Enable", currentValue)
if newValue ~= currentValue then
    currentValue = newValue
    toggle()
end
```

### Step 5: Use Composition Primitives

Replace manual layout with UI-Engine composition:

```lua
-- Before: manual layout
ImGui.BeginChild("content", 0, 200, true)
ImGui.Columns(2, nil, true)
ImGui.Text("Label")
ImGui.NextColumn()
ImGui.Text("Value")
ImGui.Columns(1)
ImGui.EndChild()

-- After: composition primitives
ctx.Column(function()
    ctx.Columns(2, nil, true)
    ctx.Text("Label")
    ctx.Text("Value")
    ctx.Columns(1)
end)
```

### Step 6: Test the Patched Mod

```bash
# Deploy to game folder
./scripts/deploy.sh

# Launch game and test:
# 1. Open CET overlay
# 2. Verify mod appears in UI-Engine sidebar
# 3. Verify themed components render correctly
# 4. Test all features
# 5. Check CET console for errors
```

---

## Patching Checklist

### Pre-Patch
- [ ] Backup original mod
- [ ] Test unpatched mod
- [ ] Identify relevant UI-Engine/0-Engine features
- [ ] Read relevant API documentation

### During Patch
- [ ] Add `GetMod()` lazy reference
- [ ] Replace polling with events (0-Engine)
- [ ] Register with UI-Engine if using UI
- [ ] Replace raw ImGui with ctx methods
- [ ] Use shared utilities (Tooltip, etc.)
- [ ] Wrap in ErrorBoundary

### Post-Patch
- [ ] Deploy to game folder
- [ ] Test in CET overlay
- [ ] Check CET console for errors
- [ ] Test all mod features
- [ ] Test mod loading/unloading
- [ ] Test overlay toggle (idempotent init)
- [ ] Update mod documentation

---

## Common Issues

### Mod Not Appearing in Sidebar

**Cause:** Registration failed or mod loaded before UI-Engine.

**Fix:** Ensure registration happens in `onInit`, which fires after all mods load:

```lua
function M.onInit()
    local ui = getUIEngine()
    if not ui then
        Logger.warn("UI-Engine not available")
        return
    end
    ui.Register("my-mod", spec)
end
```

### Theme Not Applied

**Cause:** Using raw ImGui calls instead of ctx.

**Fix:** Replace all ImGui calls with `ctx` methods:

```lua
-- Wrong
ImGui.Text("Hello")

-- Correct
ctx.Text("Hello")
```

### Event Handler Not Firing

**Cause:** Event subscription not cleaned up on reload.

**Fix:** Store subscription handles and clean up:

```lua
local subscriptions = {}

function M.onInit()
    -- Clean up previous subscriptions
    for _, unsub in ipairs(subscriptions) do
        unsub()
    end
    subscriptions = {}

    -- Re-subscribe
    local engine = get0Engine()
    if engine then
        table.insert(subscriptions,
            engine.Subscribe("eventName", handler))
    end
end
```

### State Not Persisting

**Cause:** Direct file I/O instead of 0-Engine Storage.

**Fix:** Use 0-Engine Storage for persistence:

```lua
-- Wrong
local file = io.open(path, "w")
file:write(data)
file:close()

-- Correct
engine.SetData("my-mod", "key", data)
```

---

## Rolling Back a Patch

If a patched mod doesn't work:

1. Restore the backup copy
2. Deploy the original: `./scripts/deploy.sh`
3. Test in game
4. Investigate the issue in the patched version