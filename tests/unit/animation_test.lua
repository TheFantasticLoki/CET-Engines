-- Test: UI Animation Module
-- Stub smoke tests for ui/animation.lua

local M = {}

function M.testModuleLoads()
    local Anim = require("ui/animation")
    assert(Anim ~= nil, "Animation should load")
    assert(type(Anim.Linear) == "function", "should have Linear()")
    assert(type(Anim.Lerp) == "function", "should have Lerp()")
    assert(type(Anim.Clamp) == "function", "should have Clamp()")
    assert(type(Anim.Map) == "function", "should have Map()")
    assert(type(Anim.Timer) == "function", "should have Timer()")
end

function M.testEasingFunctionsRange()
    local Anim = require("ui/animation")
    local fns = {
        Anim.Linear, Anim.EaseOutCubic, Anim.EaseInCubic, Anim.EaseInOutCubic,
        Anim.EaseOutQuad, Anim.EaseInQuad, Anim.EaseInOutQuad,
        Anim.EaseOutExpo, Anim.EaseInOutSine, Anim.EaseOutElastic,
    }
    for _, fn in ipairs(fns) do
        local v0 = fn(0)
        local v1 = fn(1)
        assert(v0 >= -0.01 and v0 <= 0.01, "f(0) should be ~0, got " .. tostring(v0))
        assert(v1 >= 0.99 and v1 <= 1.01, "f(1) should be ~1, got " .. tostring(v1))
    end
end

function M.testClamp()
    local Anim = require("ui/animation")
    assert(Anim.Clamp(5, 0, 10) == 5, "within range")
    assert(Anim.Clamp(-1, 0, 10) == 0, "below min")
    assert(Anim.Clamp(15, 0, 10) == 10, "above max")
    assert(Anim.Clamp(nil, 0, 10) == 0, "nil -> min")
end

function M.testLerp()
    local Anim = require("ui/animation")
    assert(Anim.Lerp(0, 10, 0.5) == 5, "midpoint")
    assert(Anim.Lerp(0, 10, 0) == 0, "start")
    assert(Anim.Lerp(0, 10, 1) == 10, "end")
end

function M.testTimerLifecycle()
    local Anim = require("ui/animation")
    local t = Anim.Timer(0.1)
    assert(t:running() == false, "not running before start")
    assert(t:finished() == false, "not finished before start")
    t:start()
    assert(t:running() == true, "running after start")
    t:stop()
    assert(t:running() == false, "not running after stop")
end

return M
