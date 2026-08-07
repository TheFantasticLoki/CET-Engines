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

---@class ComponentLibrary
---@field primitives PrimitiveComponents|nil
---@field buttons ButtonComponents|nil
---@field display DisplayComponents|nil
---@field layout LayoutComponents|nil
---@field inputs InputComponents|nil
---@field sliders SliderComponents|nil
---@field containers ContainerComponents|nil
---@field advanced AdvancedComponents|nil
---@field compose Compose|nil
---@field console ConsoleComponents|nil
---@field tables TableComponents|nil
---@field glyphs Glyphs|nil
---@field iconBrowser IconBrowser|nil
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
---@type PrimitiveComponents|nil
M.primitives = SafeRequire("ui/components/primitives")
---@type ButtonComponents|nil
M.buttons = SafeRequire("ui/components/buttons")
---@type DisplayComponents|nil
M.display = SafeRequire("ui/components/display")
---@type LayoutComponents|nil
M.layout = SafeRequire("ui/components/layout")
---@type InputComponents|nil
M.inputs = SafeRequire("ui/components/inputs")
---@type SliderComponents|nil
M.sliders = SafeRequire("ui/components/sliders")
---@type ContainerComponents|nil
M.containers = SafeRequire("ui/components/containers")
---@type AdvancedComponents|nil
M.advanced = SafeRequire("ui/components/advanced")
---@type Compose|nil
M.compose = SafeRequire("ui/components/compose")
---@type ConsoleComponents|nil
M.console = SafeRequire("ui/components/console")
---@type TableComponents|nil
M.tables = SafeRequire("ui/components/tables")
---@type Glyphs|nil
M.glyphs = SafeRequire("ui/components/glyphs")
---@type IconBrowser|nil
M.iconBrowser = SafeRequire("ui/components/icon_browser")

-- Flatten into single API (only functions, don't overwrite sub-module tables)
local subModules = {
    "primitives", "buttons", "display", "layout", "inputs", "sliders",
    "containers", "advanced", "compose", "console", "tables", "glyphs", "iconBrowser"
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

-- Diagnostic state for component loading
local _diagAdvLoaded = (type(M.advanced) == "table")
local _diagAdvSlider = (type(M.AdvancedSlider) == "function")
-- Note: run diagnostics lazily via M.getDiagnostics() instead of on every load

-- Initialize modules that need dependencies
--- Initialize all component modules with dependencies
---@param logger Logger module reference
---@param core Core module reference
---@param theme Theme module reference
---@return nil
function M.init(logger, core, theme)
    if logger and logger.debug then
        logger.debug("[Components] Initializing component library")
    end

    if M.containers and M.containers.init then
        M.containers.init(core)
    end
    if M.advanced and M.advanced.init then
        M.advanced.init(theme, logger)
    end
    if M.compose and M.compose.init then
        M.compose.init(logger)
    end
end

return M
