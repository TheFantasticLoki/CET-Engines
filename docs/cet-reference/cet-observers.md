# CET Observers Reference

Source: wiki.redmodding.org/cyber-engine-tweaks/cet-functions/observers

Observers detect when a game function/method is executed. Must be registered within `onInit`.

## Observe

Subscribe to events or state changes. Callback fires when the observed method executes.

```lua
Observe(className, methodName, callback)
```

### Callback Arguments

The callback receives the class instance (`self`) and original method arguments:

```lua
Observe('AimingStateEvents', 'OnEnter', function(self, stateContext, scriptInterface)
    -- self             the 'AimingStateEvents' class instance
    -- stateContext     original method argument
    -- scriptInterface  original method argument
end)
```

**IMPORTANT**: Observer functions MUST accept `self` as the first parameter (CET 1.14+).

### Observe State Changes (OnEnter/OnExit/OnUpdate)

```lua
registerForEvent('onInit', function()
    -- Fire ONCE when entering crouched state
    Observe('CrouchEvents', 'OnEnter', function(self, stateContext, scriptInterface)
        Game.AddToInventory('Items.money', 1000)
    end)

    -- Fire ONCE when exiting crouched state
    Observe('CrouchEvents', 'OnExit', function(self, stateContext, scriptInterface)
        -- reset state
    end)

    -- Fire CONTINUOUSLY while crouched
    Observe('CrouchEvents', 'OnUpdate', function(self, timeDelta, stateContext, scriptInterface)
        Game.AddToInventory('Items.money', 20)
    end)
end)
```

### Observe Component Events

```lua
registerForEvent('onInit', function()
    Observe('AnimationControllerComponent', 'PushEvent;GameObjectCName', function(gameObject, eventName)
        print('GameObject:', gameObject:GetClassName())
        print('Event:', eventName)
    end)
end)
```

### Observe Static Methods

Use full name with semicolon separator:

```lua
Observe('PlayerPuppet', 'IsSwimming;PlayerPuppet', function(player)
    print('PlayerPuppet.IsSwimming(player)')
end)
```

### ObserveBefore / ObserveAfter

Execute logic before/after a method. These are guaranteed to run.

```lua
ObserveBefore('PlayerPuppet', 'GetGunshotRange', function()
    print('Before GetGunshotRange')
end)

ObserveAfter('PlayerPuppet', 'GetGunshotRange', function()
    print('After GetGunshotRange')
end)
```

## Override

Replace a game method's behavior. The `wrappedMethod` parameter lets you call the original.

```lua
Override(className, methodName, callback)
```

```lua
registerForEvent('onInit', function()
    Override('CrouchDecisions', 'EnterCondition', function(self, stateContext, scriptInterface, wrappedMethod)
        -- Call original logic
        local result = wrappedMethod(stateContext, scriptInterface)

        -- Modify behavior
        if isADS then
            return false  -- disallow crouch while ADS
        end

        -- Return original result otherwise
        return result
    end)
end)
```

## NewProxy

Create proxy listeners for game script callbacks.

```lua
listener = NewProxy({
    OnHit = {
        args = {"handle:GameObject", "Uint32"},
        callback = function(shooter, damage)
            print("Hit by " .. NameToString(shooter:GetClassName()) .. "!")
            print("You lost " .. tostring(damage) .. " HP.")
        end
    }
})

-- Register with a game script
awesome:RegisterHit(listener:Target(), listener:Function("OnHit"))
awesome:RegisterShoot(listener:Target(), listener:Function("OnShoot"))
```

## @param Annotations for Code Completion

```lua
---@param request PerformFastTravelRequest
Observe("FastTravelSystem", "OnPerformFastTravelRequest", function(request)
    -- request has type info for code completion
end)
```
