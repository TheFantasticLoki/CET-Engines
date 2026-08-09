--[[
    Advanced — UI-Engine Component Library (Barrel Module)

    Re-exports all advanced widgets from sub-modules:
    - AdvancedSlider (slider.lua)
    - ThemeDropdown (theme_dropdown.lua)
    - ComboBox (combo_box.lua)
    - AdvancedTooltip (tooltip.lua)
]]

---@class AdvancedComponents
---@field AdvancedSlider AdvancedSlider|nil
---@field ThemeDropdown ThemeDropdown|nil
---@field ComboBox ComboBox|nil
---@field AdvancedTooltip AdvancedTooltip|nil
local M = {}

local slider = require("ui/components/advanced/slider")
local themeDropdown = require("ui/components/advanced/theme_dropdown")
local comboBox = require("ui/components/advanced/combo_box")
local tooltip = require("ui/components/advanced/tooltip")

-- Flatten functions
M.AdvancedSlider = slider.AdvancedSlider
M.ThemeDropdown = themeDropdown.ThemeDropdown
M.ComboBox = comboBox.ComboBox
M.AdvancedTooltip = tooltip

---@return nil
function M.init(theme, log)
    slider.init(theme, log)
    themeDropdown.init(theme)
end

return M
