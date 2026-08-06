-- Config-Engine Content Area
-- Displays the selected mod's settings or custom draw.
-- Phase 7: basic implementation.

---@class CfgContentArea
---Content area showing selected mod's settings, custom draw, and reset button.
local M = {}

-- Dependencies (late-bound)
---@type table?
local Core = nil
---@type table?
local Components = nil
---@type table?
local SettingsRenderer = nil

--- Initialize the content area module.
---@param deps table { core: CfgCore, components: ComponentsModule, settingsRenderer: SettingsRenderer }
---@return nil
function M.init(deps)
    Core = deps.core
    Components = deps.components
    SettingsRenderer = deps.settingsRenderer
end

--- Draw the content area.
---@param ctx table UI-Engine context
---@return nil
function M.draw(ctx)
    if not Core or not Components then return end

    local selectedMod = Core.getSelectedMod()
    if not selectedMod then
        -- No mod selected
        Components.Spacing(20)
        Components.Text("Select a mod from the sidebar")
        return
    end

    local mod = Core.getMod(selectedMod)
    if not mod then
        Components.Text("Mod not found: " .. selectedMod)
        return
    end

    local spec = mod.spec or {}

    -- Card header
    Components.CollapsingSection(
        spec.name or selectedMod,
        true,
        function()
            -- Mod info
            if spec.version then
                Components.Text("Version: " .. spec.version)
            end
            if spec.author then
                Components.Text("Author: " .. spec.author)
            end
            if spec.description then
                Components.TextWrapped(spec.description)
            end
        end
    )

    Components.Spacing(4)

    -- Settings rendering
    if mod.renderMode == "schema" or mod.renderMode == "hybrid" then
        if SettingsRenderer and SettingsRenderer.renderSettings then
            SettingsRenderer.renderSettings(selectedMod, spec, mod.settings)
        end
    end

    -- Custom draw
    if (mod.renderMode == "custom" or mod.renderMode == "hybrid") and spec.draw then
        -- Create a basic context for the mod
        local modCtx = {
            modId = selectedMod,
            spec = spec,
        }
        -- Proxy component calls
        if Components then
            setmetatable(modCtx, {
                __index = function(_, k)
                    if Components[k] then
                        return Components[k]
                    end
                    return nil
                end
            })
        end

        local ok, err = pcall(spec.draw, modCtx)
        if not ok then
            Components.TextColored(
                { r = 1, g = 0.3, b = 0.3 },
                "Draw error: " .. tostring(err)
            )
        end
    end

    -- Settings reset button
    Components.Spacing(8)
    if Components.Button then
        local clicked = Components.Button("Reset to Defaults")
        if clicked then
            local UndoRedoMod = nil
            pcall(function() UndoRedoMod = require("modules.undo_redo") end)
            if UndoRedoMod then
                local oldSettings = {}
                for k, v in pairs(mod.settings or {}) do
                    oldSettings[k] = v
                end
                local Resolver = require("modules.settings_resolver")
                local newSettings = Resolver.resolveSettings(spec, nil)
                local cmd = UndoRedoMod.makePresetCommand(selectedMod, oldSettings, newSettings, "Reset to Defaults")
                UndoRedoMod.execute(cmd, function(c)
                    Core.setMod(c.modId, { settings = c.newSettings })
                    Core.markDirty()
                    return true
                end)
            end
        end
    end
end

return M
