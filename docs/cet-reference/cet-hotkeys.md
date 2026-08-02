# CET Hotkeys Reference

Source: wiki.redmodding.org/cyber-engine-tweaks/cet-functions/hotkeys

Two types: **Hotkeys** (triggered on key release) and **Inputs** (triggered on press AND release).
Both appear in CET Bindings screen. Register at ROOT level, outside event handlers.

## registerHotkey

```lua
registerHotkey(slug, label, callback)
```

- `slug` (string) — unique identifier within your mod's scope
- `label` (string) — display text in CET Bindings menu
- `callback` (function) — executed when hotkey is released

```lua
registerHotkey('give_money', 'Give Money', function()
    Game.AddToInventory('Items.money', 1000)
end)
```

## registerInputEvent

```lua
registerInputEvent(slug, callback)
```

- `slug` (string) — unique identifier
- `callback` (function) — receives `action` parameter (pressed/released)

```lua
registerInputEvent('my_action', function(action)
    print('Action: ' .. tostring(action))
end)
```

## Notes

- Hotkeys/Inputs can trigger ANY time after CET loads, even before `onInit`
- They trigger ON TOP of existing game keybinds
- Sorted in CET Bindings by registration order
- Must check game state (player exists, etc.) before acting
