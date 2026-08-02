# CET Mod Structure Reference

Source: wiki.redmodding.org/cyber-engine-tweaks

## Directory Structure

```
mods/
  MyMod/
    init.lua          # Entry point (required)
    *.lua             # Additional modules
```

## init.lua Requirements

- **Entry point** — CET executes this file when loading the mod
- Must register events using `registerForEvent()`
- Must be in the mod's root directory

## Event Registration Pattern

```lua
-- Root-level: register hotkeys here
registerHotkey('my_key', 'My Key', function() ... end)
registerInputEvent('my_input', function(action) ... end)

-- onInit: register observers, init state
registerForEvent('onInit', function()
    Observe('ClassName', 'Method', function(self, ...) ... end)
end)

-- onDraw: render ImGui
registerForEvent('onDraw', function()
    if ImGui.Begin('Window') then
        -- ImGui calls
        ImGui.End()
    end
end)

-- Overlay events
registerForEvent('onOverlayOpen', function() ... end)
registerForEvent('onOverlayClose', function() ... end)
```

## require() / package.path

CET sets `package.path` to include the mod's root folder.

```lua
-- Forward slashes (recommended)
local Utils = require('utils')
local MyMod = require('modules/mymod')

-- Dots also work (Lua standard)
local Utils = require('utils')
local MyMod = require('modules.mymod')
```

## Cross-Mod Dependencies

Use `GetMod()` to access other mods' exports.

```lua
-- In mod A (init.lua), export via global:
MyMod = { version = "1.0", doSomething = function() end }

-- In mod B, access via GetMod:
local modA = GetMod("ModA")
if modA then
    modA.doSomething()
end
```

## CET Console Logging

```lua
print("Message")  -- outputs to CET console + log file
```

## Log Files

Located in CET installation directory:
- `Cyberpunk2077/bin/x64/plugins/cyber_engine_tweaks/`
- Each mod gets its own log file
