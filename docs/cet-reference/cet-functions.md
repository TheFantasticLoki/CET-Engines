# CET Functions Reference

Source: wiki.redmodding.org/cyber-engine-tweaks/cet-functions

## print()

Output to CET Console and log file. Multiple args are space-separated.

```lua
print('Hey', 'there', 1, 2, true)
print(Game.GetPlayer():GetWorldPosition())
```

## debug.log()

Writes to the individual mod's log file.

```lua
debug.log(obj1, obj2, ...)
```

## GetMod() / Require

CET uses Lua `require()` with paths relative to the mod folder.
Forward slashes or dots both work as path separators.

```lua
-- Relative to mod folder root
local Module = require('modules/MyModule')
local Utils = require('utils')
```

## dir()

List directory contents.

```lua
local files = dir('./')
-- returns: { {name="file.lua", type="file"}, {name="subdir", type="directory"} }
```

## json

JSON encode/decode (added in CET 1.9.2).

```lua
local encoded = json.encode(myTable)
local decoded = json.decode(jsonString)
```

## GetPlayer() / Game.GetPlayer()

```lua
local player = Game.GetPlayer()
-- or global shorthand:
local player = GetPlayer()
```

## TweakDB

```lua
TweakDB:DebugStats()
```

## ModArchiveExists()

Check if a REDmod archive exists (CET 1.18.0+).

```lua
if ModArchiveExists('my_mod.archive') then
    print('Archive found')
end
```

## Game Object Access

```lua
-- Static functions (no handle needed)
Game.PrintHealth()
Game.AddToInventory('Items.money', 1000)

-- Handle functions (need object)
local player = Game.GetPlayer()
player:SetWarningMessage('Hello!')
print(player:GetWorldPosition())
```

## Redscript Detection

On the redscript side, declare a detection function:

```swift
// Redscript side
public static func IsDetected_NameOfYourMod() -> Void {}
```

Then in Lua:

```lua
if IsDetected_NameOfYourMod then
    -- redscript mod is loaded
end
```

## File Utilities

```lua
-- Recursive file listing
function getFilesRecursive(path, maxDepth, depth, storage)
    path = path or '.'
    maxDepth = maxDepth or -1
    depth = depth or 0
    storage = storage or {}
    if maxDepth ~= -1 and depth > maxDepth then return storage end
    if not string.find(path, '^%.') then path = '.' .. path end
    if string.find(path, '^%.//') then path = string.gsub(path, '^%.//', './') end
    local files = dir(path)
    if not files or #files == 0 then return storage end
    for _, file in ipairs(files) do
        if file.type == 'directory' then
            getFilesRecursive(path .. '/' .. file.name, maxDepth, depth + 1, storage)
        elseif string.find(file.name, '%.lua$') then
            table.insert(storage, path .. '/' .. file.name)
        end
    end
    return storage
end
```

## TweakDB DebugStats

```lua
TweakDB:DebugStats()
-- Displays: number of flats, records, queries, buffer size, created records
```
