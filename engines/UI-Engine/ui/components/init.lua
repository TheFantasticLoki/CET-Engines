--[[
    Components — UI-Engine Component Library

    Barrel re-export for all component sub-modules.
    All ~50+ widgets accessible via single require("engines.UI-Engine.ui.components").

    Usage:
        local Components = require("engines.UI-Engine.ui.components")
        Components.Button("Click me")
        Components.Text("Hello world")
]]

local M = {}

-- Import all sub-modules
M.primitives = require("engines.UI-Engine.ui.components.primitives")
M.buttons = require("engines.UI-Engine.ui.components.buttons")
M.display = require("engines.UI-Engine.ui.components.display")
M.layout = require("engines.UI-Engine.ui.components.layout")
M.inputs = require("engines.UI-Engine.ui.components.inputs")
M.sliders = require("engines.UI-Engine.ui.components.sliders")
M.containers = require("engines.UI-Engine.ui.components.containers")
M.advanced = require("engines.UI-Engine.ui.components.advanced")
M.compose = require("engines.UI-Engine.ui.components.compose")
M.console = require("engines.UI-Engine.ui.components.console")
M.tables = require("engines.UI-Engine.ui.components.tables")
M.icons = require("engines.UI-Engine.ui.components.icons")

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
