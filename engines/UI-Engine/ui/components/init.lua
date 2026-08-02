--[[
    Components — UI-Engine Component Library

    Barrel re-export for all component sub-modules.
    All ~50+ widgets accessible via single require("ui/components").

    Uses SafeRequire for all sub-modules so that a single failure
    doesn't crash the entire component library.

    Usage:
        local Components = require("ui/components")
        Components.Button("Click me")
        Components.Text("Hello world")
]]

local M = {}

-- --- SafeRequire for component sub-modules ---
local function SafeRequire(path)
    local ok, mod = pcall(require, path)
    if ok then return mod end
    -- Log to CET console (Log-Engine may not be available yet)
    print("[UIEngine:Components] FAILED to load '" .. path .. "': " .. tostring(mod))
    return nil
end

-- Import all sub-modules (SafeRequire — one failure doesn't kill all)
M.primitives = SafeRequire("ui/components/primitives")
M.buttons = SafeRequire("ui/components/buttons")
M.display = SafeRequire("ui/components/display")
M.layout = SafeRequire("ui/components/layout")
M.inputs = SafeRequire("ui/components/inputs")
M.sliders = SafeRequire("ui/components/sliders")
M.containers = SafeRequire("ui/components/containers")
M.advanced = SafeRequire("ui/components/advanced")
M.compose = SafeRequire("ui/components/compose")
M.console = SafeRequire("ui/components/console")
M.tables = SafeRequire("ui/components/tables")
M.icons = SafeRequire("ui/components/icons")

-- Flatten into single API (only functions, don't overwrite sub-module tables)
local subModules = {
    "primitives", "buttons", "display", "layout", "inputs", "sliders",
    "containers", "advanced", "compose", "console", "tables", "icons"
}

for _, modName in ipairs(subModules) do
    local mod = M[modName]
    if type(mod) == "table" then
        for k, v in pairs(mod) do
            if type(v) == "function" and M[k] == nil then
                M[k] = v
            end
        end
    end
end

-- Initialize modules that need dependencies
--- Initialize all component modules with dependencies
-- @param logger Logger module reference
-- @param core Core module reference
-- @param theme Theme module reference
function M.init(logger, core, theme)
    if M.containers and M.containers.init then
        M.containers.init(core)
    end
    if M.advanced and M.advanced.init then
        M.advanced.init(theme)
    end
    if M.compose and M.compose.init then
        M.compose.init(logger)
    end
end

return M
