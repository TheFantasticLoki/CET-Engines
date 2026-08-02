# CET Scripting API Reference

Source: wiki.redmodding.org/cyber-engine-tweaks/scripting-api

## Game Object

The `Game` object provides access to the game's scripting API.

### Static Functions (no handle needed)

```lua
Game.PrintHealth()
Game.AddToInventory('Items.money', 1000)
Game.GetPlayer()  -- returns player handle
```

### Handle Functions (need object reference)

```lua
local player = Game.GetPlayer()
player:SetWarningMessage('Hello!')
print(player:GetWorldPosition())
player:GetClassName()
```

### Global Access (CET 1.14+)

Direct access without going through Game object:

```lua
print(GetPlayer())  -- equivalent to Game.GetPlayer()
```

## Class System (CET 1.14+)

### Creating Objects

```lua
local obj = ClassName.new()
local obj = ClassName.new({ property1 = value1, property2 = value2 })
```

### Class Aliases

Redscript class aliases are supported. Example:

```lua
local player = Game.GetPlayer()
local pos = player:GetWorldPosition()  -- returns Vector4
```

## Overloaded Functions

CET resolves overloaded functions based on parameter types.

## Variant Type Support

Partial support for Variant types (CET 1.14+).

## Backward Compatibility

New scripting features in CET 1.14 are optional — existing mods don't need rewriting.
