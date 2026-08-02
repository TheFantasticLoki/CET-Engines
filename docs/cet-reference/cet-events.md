# CET Events Reference

Source: wiki.redmodding.org/cyber-engine-tweaks/cet-functions/events

CET provides built-in events via `registerForEvent()`. Listeners must be registered in `init.lua`.
CET events are DISTINCT from game events — `onInit` means CET loaded mods, NOT that the game is initializing.

## registerForEvent

```lua
registerForEvent(event_name, callback)
```

### Event Types

| Event | Fires | Notes |
|-------|-------|-------|
| `onInit` | Once after CET loads all mods | Scripting API available. Register Observers here. |
| `onDraw` | Every frame | Only fires when overlay is open (unless using overlay trick). |
| `onOverlayOpen` | When CET overlay opens (F4) | |
| `onOverlayClose` | When CET overlay closes | |

### onInit

Fired once when CET has loaded all mods and the Scripting API is available.
Each mod can have only ONE `onInit` event.

```lua
registerForEvent('onInit', function()
    print('Game is loaded')
    -- Register observers here
    -- Register hotkeys here (at root level outside event handlers)
end)
```

### onDraw

Fired every frame. Use for ImGui rendering.

```lua
registerForEvent('onDraw', function()
    if ImGui.Begin('Window Title', ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.Text('Hello World!')
    end
    ImGui.End()
end)
```

### Overlay-gated rendering pattern

```lua
local isOverlayVisible = false

registerForEvent('onOverlayOpen', function()
    isOverlayVisible = true
end)

registerForEvent('onOverlayClose', function()
    isOverlayVisible = false
end)

registerForEvent('onDraw', function()
    if not isOverlayVisible then
        return
    end
    if ImGui.Begin('Window', ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.Text('Hello!')
    end
    ImGui.End()
end)
```

### Conditional rendering with observers

```lua
isSprinting = false

registerForEvent('onInit', function()
    Observe('SprintEvents', 'OnEnter', function(stateContext, scriptInterface)
        isSprinting = true
    end)
    Observe('SprintEvents', 'OnExit', function(stateContext, scriptInterface)
        isSprinting = false
    end)
end)

registerForEvent('onDraw', function()
    if not isSprinting then return end
    if ImGui.Begin('Notification', ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.Text('Nice sprint!')
    end
    ImGui.End()
end)
```
