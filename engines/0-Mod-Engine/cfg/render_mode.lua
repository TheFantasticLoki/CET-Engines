-- Config-Engine Render Mode Detection
-- Determines how a mod's settings should be rendered.

---@class RenderMode
local M = {}

--- Detect the rendering mode for a mod registration spec.
---@param spec table The registration spec table
---@return string One of: "schema", "custom", "hybrid", "external"
function M.detectMode(spec)
    local hasSettings = spec.settings ~= nil and type(spec.settings) == "table"
    local hasDraw = spec.draw ~= nil and type(spec.draw) == "function"

    if hasSettings and hasDraw then
        return "hybrid"
    elseif hasSettings then
        return "schema"
    elseif hasDraw then
        return "custom"
    else
        return "external"
    end
end

--- Check if a mode uses schema-based rendering.
---@param mode string The render mode string
---@return boolean
function M.usesSchema(mode)
    return mode == "schema" or mode == "hybrid"
end

--- Check if a mode uses custom drawing.
---@param mode string The render mode string
---@return boolean
function M.usesCustom(mode)
    return mode == "custom" or mode == "hybrid"
end

return M
