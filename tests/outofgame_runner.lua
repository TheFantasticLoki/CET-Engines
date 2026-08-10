--[[
    Out-of-Game Test Runner — Unified Framework PoC
    
    Runs shared tests from engines/0-Mod-Engine/tests/ using mocks.
    This file is NOT deployed — it's only for development/CI.
    
    Usage:
        lua tests/outofgame_runner.lua
        ./scripts/test.sh
]]

-- ============================================================================
-- Setup: Package Path
-- ============================================================================

local scriptDir = arg[0]:match("(.*/)") or "./"
package.path = scriptDir .. "?.lua;" .. scriptDir .. "?/init.lua;" .. package.path

-- ============================================================================
-- Load Mocks (CET, ImGui, GameUI)
-- ============================================================================

io.write("Loading mocks...\n")
local ok1, err1 = pcall(require, "tests.mocks.cet_mock")
local ok2, err2 = pcall(require, "tests.mocks.imgui_mock")
local ok3, err3 = pcall(require, "tests.mocks.gameui_mock")

if ok1 then io.write("  ✓ CET Mock\n") else io.write("  ✗ CET Mock: " .. tostring(err1) .. "\n") end
if ok2 then io.write("  ✓ ImGui Mock\n") else io.write("  ✗ ImGui Mock: " .. tostring(err2) .. "\n") end
if ok3 then io.write("  ✓ GameUI Mock\n") else io.write("  ✗ GameUI Mock: " .. tostring(err3) .. "\n") end

-- ============================================================================
-- Load Framework
-- ============================================================================

local framework = require("tests.framework")

-- ============================================================================
-- Build Context (mocked dependencies)
-- ============================================================================

-- Load engine modules (same as in-game, but with mocked ImGui)
local Core = require("engines.0-Mod-Engine.core")

local ctx = {
    Core = Core,
    assert = framework.assert,
    -- Add more dependencies here as tests need them:
    -- Events = require("engines.0-Mod-Engine.api.events"),
    -- Theme = require("engines.0-Mod-Engine.ui.theme"),
}

-- ============================================================================
-- Discover and Run Shared Tests
-- ============================================================================

io.write("\n\27[0;36m=== Running Shared Tests (Out-of-Game) ===\27[0m\n")

-- List of shared test modules to run
-- These are the SAME tests that run in-game via Config-Engine test panel
local sharedTests = {
    "tests.shared.core_state_test",
    -- Add more shared tests here as they're created:
    -- "tests.shared.events_test",
    -- "tests.shared.theme_test",
}

local totalPassed = 0
local totalFailed = 0
local allErrors = {}

for _, testPath in ipairs(sharedTests) do
    local ok, testModule = pcall(require, testPath)
    if ok and testModule and type(testModule.run) == "function" then
        local result = testModule.run(ctx)
        framework.report(testModule.name or testPath, result)
        totalPassed = totalPassed + result.passed
        totalFailed = totalFailed + result.failed
        -- Extract errors from details (new format) or errors (old format)
        local errList = result.errors or {}
        if result.details then
            for _, detail in ipairs(result.details) do
                if not detail.passed and detail.error then
                    table.insert(errList, (detail.name or "unnamed") .. ": " .. detail.error)
                end
            end
        end
        for _, err in ipairs(errList) do
            table.insert(allErrors, (testModule.name or testPath) .. " > " .. err)
        end
    else
        io.write("\n\27[1;33m--- " .. testPath .. " ---\27[0m\n")
        io.write("  \27[1;33mSKIP\27[0m (failed to load: " .. tostring(testModule) .. ")\n")
    end
end

-- ============================================================================
-- Summary
-- ============================================================================

io.write("\n\27[0;36m=== Summary ===\27[0m\n")
io.write("  Total:  " .. (totalPassed + totalFailed) .. "\n")
io.write("  Passed: \27[0;32m" .. totalPassed .. "\27[0m\n")
io.write("  Failed: \27[0;31m" .. totalFailed .. "\27[0m\n")

if totalFailed > 0 then
    io.write("\n\27[0;31mFailed tests:\27[0m\n")
    for _, err in ipairs(allErrors) do
        io.write("  \27[0;31mFAIL\27[0m " .. err .. "\n")
    end
    io.write("\n\27[0;31mTests failed with " .. totalFailed .. " failure(s).\27[0m\n")
    os.exit(1)
else
    io.write("\n\27[0;32mAll tests passed!\27[0m\n")
    os.exit(0)
end
