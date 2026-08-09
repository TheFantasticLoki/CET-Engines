--[[
    Animation — UI-Engine

    Lightweight animation utilities for smooth transitions.
    Provides easing functions, linear interpolation, color blending,
    and a reusable timer for frame-independent animations.

    Uses os.clock() for time (available in Lua 5.1 / CET).

    Dependencies: None (standalone utility module)

    Usage:
        local Animation = require("ui/animation")
        local timer = Animation.Timer(0.2)
        timer:start()
        -- each frame:
        timer:update()
        local t = timer:fraction()  -- 0..1
        local val = Animation.Lerp(from, to, Animation.EaseOutCubic(t))
]]

local M = {}

-- ============================================================================
-- Global Animation Configuration
-- ============================================================================

---@class AnimationConfig
---@field enabled boolean Master switch: disable all animations
---@field speedScale number Speed multiplier (0.25-2.0, default 1.0)
---@field fadeEnabled boolean Can disable just fade transitions
local _config = {
    enabled = true,
    speedScale = 1.0,
    fadeEnabled = true,
}

--- Set global animation configuration (called from engine settings).
---@param opts table { enabled?, speedScale?, fadeEnabled? }
function M.setConfig(opts)
    if not opts then return end
    if opts.enabled ~= nil then _config.enabled = opts.enabled end
    if opts.speedScale ~= nil then
        _config.speedScale = math.max(0.25, math.min(2.0, opts.speedScale))
    end
    if opts.fadeEnabled ~= nil then _config.fadeEnabled = opts.fadeEnabled end
end

--- Get current global animation configuration.
---@return AnimationConfig config
function M.getConfig()
    return _config
end

--- Check if animations are enabled globally.
---@return boolean enabled
function M.isEnabled()
    return _config.enabled
end

--- Get effective duration accounting for global speed scale.
---@param duration Base duration in seconds
---@return number Effective duration (duration / speedScale)
function M.effectiveDuration(duration)
    if not _config.enabled then return 0 end
    return duration / math.max(0.01, _config.speedScale)
end

-- ============================================================================
-- Easing Functions (t: 0..1 → 0..1)
-- ============================================================================

--- Linear interpolation (no easing)
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.Linear(t)
    return t
end

--- Ease-out cubic: fast start, slow end
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseOutCubic(t)
    return 1 - (1 - t) ^ 3
end

--- Ease-in cubic: slow start, fast end
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseInCubic(t)
    return t ^ 3
end

--- Ease-in-out cubic: smooth start and end
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return 1 - (-2 * t + 2) ^ 3 / 2
    end
end

--- Ease-out quad: gentle deceleration
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseOutQuad(t)
    return 1 - (1 - t) ^ 2
end

--- Ease-in quad: gentle acceleration
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseInQuad(t)
    return t * t
end

--- Ease-in-out quad: smooth acceleration and deceleration
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - (-2 * t + 2) ^ 2 / 2
    end
end

--- Ease-out exponential: very fast start, very slow end
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseOutExpo(t)
    if t == 1 then return 1 end
    return 1 - 2 ^ (-10 * t)
end

--- Ease-in-out sine: gentle wave-like transition
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseInOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end

--- Elastic ease-out: bouncy overshoot
---@param t Progress (0..1)
---@return number Eased value (0..1)
function M.EaseOutElastic(t)
    if t == 0 or t == 1 then return t end
    local p = 0.3
    local s = p / 4
    return 2 ^ (-10 * t) * math.sin((t - s) * (2 * math.pi) / p) + 1
end

-- ============================================================================
-- Interpolation Utilities
-- ============================================================================

--- Linearly interpolate between two numbers
---@param a Start value
---@param b End value
---@param t Factor (0..1, clamped)
---@return number Interpolated value
function M.Lerp(a, b, t)
    t = math.max(0, math.min(1, t))
    return a + (b - a) * t
end

--- Linearly interpolate between two color tables
---@param c1 Start color {r, g, b} or {r, g, b, a}
---@param c2 End color {r, g, b} or {r, g, b, a}
---@param t Factor (0..1, clamped)
---@return table Interpolated color
function M.LerpColor(c1, c2, t)
    t = math.max(0, math.min(1, t))
    local result = {
        r = c1.r + (c2.r - c1.r) * t,
        g = c1.g + (c2.g - c1.g) * t,
        b = c1.b + (c2.b - c1.b) * t,
    }
    if c1.a and c2.a then
        result.a = c1.a + (c2.a - c1.a) * t
    end
    return result
end

--- Clamp a value between min and max
---@param val Value to clamp (nil treated as min)
---@param min Minimum
---@param max Maximum
---@return number Clamped value
function M.Clamp(val, min, max)
    if val == nil then
        return min or 0
    end
    if min == nil then min = 0 end
    if max == nil then max = 0 end
    return math.max(min, math.min(max, val))
end

--- Map a value from one range to another
---@param val Input value
---@param inMin Input range minimum
---@param inMax Input range maximum
---@param outMin Output range minimum
---@param outMax Output range maximum
---@return number Mapped value
function M.Map(val, inMin, inMax, outMin, outMax)
    local t = (val - inMin) / (inMax - inMin)
    t = math.max(0, math.min(1, t))
    return outMin + (outMax - outMin) * t
end

-- ============================================================================
-- Timer — Reusable animation timer
-- ============================================================================

--- Create a new timer for time-based animations.
--- Respects global animation config (enabled, speedScale).
---@param duration Duration in seconds (before speed scaling)
---@param easingFn Optional easing function (default: EaseOutCubic)
---@return table Timer instance
function M.Timer(duration, easingFn)
    local timer = {
        _baseDuration = math.max(0.001, duration or 0.2),
        _easing = easingFn or M.EaseOutCubic,
        _startTime = 0,
        _elapsed = 0,
        _running = false,
        _finished = false,
    }

    --- Get effective duration accounting for global speed scale
    ---@return number Effective duration in seconds
    function timer:_effectiveDuration()
        return M.effectiveDuration(self._baseDuration)
    end

    --- Start or restart the timer
    function timer:start()
        -- If animations disabled, jump to end immediately
        if not _config.enabled then
            self._elapsed = 0
            self._running = false
            self._finished = true
            return
        end
        self._startTime = os.clock()
        self._elapsed = 0
        self._running = true
        self._finished = false
    end

    --- Stop the timer
    function timer:stop()
        self._running = false
    end

    --- Update the timer (call once per frame).
    --- Respects global speed scale.
    function timer:update()
        if not self._running then return end
        -- If animations disabled mid-run, jump to end
        if not _config.enabled then
            self._elapsed = self:_effectiveDuration()
            self._running = false
            self._finished = true
            return
        end
        self._elapsed = os.clock() - self._startTime
        local effDur = self:_effectiveDuration()
        if self._elapsed >= effDur then
            self._elapsed = effDur
            self._running = false
            self._finished = true
        end
    end

    --- Get raw elapsed time (0..effectiveDuration)
    ---@return number Elapsed seconds
    function timer:elapsed()
        return self._elapsed
    end

    --- Get normalized progress with easing (0..1)
    ---@return number Eased fraction
    function timer:fraction()
        local effDur = self:_effectiveDuration()
        local raw = math.max(0, math.min(1, self._elapsed / effDur))
        return self._easing(raw)
    end

    --- Get raw (un-eased) progress (0..1)
    ---@return number Raw fraction
    function timer:fractionRaw()
        local effDur = self:_effectiveDuration()
        return math.max(0, math.min(1, self._elapsed / effDur))
    end

    --- Check if timer has finished
    ---@return boolean True if duration elapsed
    function timer:finished()
        return self._finished
    end

    --- Check if timer is currently running
    ---@return boolean True if running
    function timer:running()
        return self._running
    end

    --- Get remaining time in seconds
    ---@return number Seconds remaining
    function timer:remaining()
        return math.max(0, self:_effectiveDuration() - self._elapsed)
    end

    --- Reset timer to zero (keeps running state)
    function timer:reset()
        self._startTime = os.clock()
        self._elapsed = 0
        self._finished = false
    end

    --- Set a new base duration (before speed scaling)
    ---@param d New base duration in seconds
    function timer:setDuration(d)
        self._baseDuration = math.max(0.001, d or 0.2)
    end

    --- Get the base duration (before speed scaling)
    ---@return number Base duration in seconds
    function timer:getBaseDuration()
        return self._baseDuration
    end

    return timer
end

return M
