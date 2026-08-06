-- Config-Engine Settings Renderer
-- Converts settings schemas to ImGui widgets automatically.
-- Uses UI-Engine components for all rendering.

---@class SettingsRenderer
---Auto-renders settings schemas as ImGui widgets via UI-Engine components.
local M = {}

-- Dependencies (late-bound)
---@type table?
local Core = nil
---@type table?
local Events = nil
---@type table?
local Components = nil
---@type table?
local UndoRedo = nil

--- Initialize the settings renderer.
---@param deps table { core: CfgCore, events: EventsModule, components: ComponentsModule, undoRedo: UndoRedoModule }
---@return nil
function M.init(deps)
    Core = deps.core
    Events = deps.events
    Components = deps.components
    UndoRedo = deps.undoRedo
end

--- Render settings for a mod.
---@param modId string The mod identifier
---@param spec table<string, any> The mod's registration spec
---@param settings table<string, any> The current resolved settings table
---@return boolean changed True if any setting changed
function M.renderSettings(modId, spec, settings)
    if not spec or not spec.settings then return false end
    if not settings then return false end

    local changed = false

    for key, setting in pairs(spec.settings) do
        local value = settings[key]
        local settingChanged = false
        local newValue = value

        -- Check conditional visibility
        local visible = true
        if setting.visible and type(setting.visible) == "function" then
            visible = setting.visible(settings)
        end

        if visible then
            -- Render based on type
            if setting.type == "toggle" then
                newValue, settingChanged = Components.Checkbox(
                    setting.label or key,
                    value,
                    { tooltip = setting.tooltip }
                )

            elseif setting.type == "slider" then
                newValue, settingChanged = Components.SliderFloat(
                    setting.label or key,
                    value or setting.default or setting.min,
                    {
                        min = setting.min,
                        max = setting.max,
                        step = setting.step or 0.1,
                        format = setting.format,
                        tooltip = setting.tooltip,
                    }
                )

            elseif setting.type == "int_slider" then
                newValue, settingChanged = Components.SliderInt(
                    setting.label or key,
                    value or setting.default or setting.min,
                    {
                        min = setting.min,
                        max = setting.max,
                        step = setting.step or 1,
                        tooltip = setting.tooltip,
                    }
                )

            elseif setting.type == "combo" then
                newValue, settingChanged = Components.ComboBox(
                    setting.label or key,
                    value,
                    {
                        options = setting.options,
                        tooltip = setting.tooltip,
                        searchable = setting.searchable,
                    }
                )

            elseif setting.type == "multi_combo" then
                newValue, settingChanged = Components.MultiSelect(
                    setting.label or key,
                    setting.options or {},
                    value or {},
                    {
                        tooltip = setting.tooltip,
                        searchable = setting.searchable,
                    }
                )

            elseif setting.type == "text" then
                newValue, settingChanged = Components.InputText(
                    setting.label or key,
                    value or "",
                    {
                        placeholder = setting.placeholder,
                        tooltip = setting.tooltip,
                        multiline = setting.multiline,
                    }
                )

            elseif setting.type == "number" then
                newValue, settingChanged = Components.InputFloat(
                    setting.label or key,
                    value or setting.default or 0,
                    {
                        min = setting.min,
                        max = setting.max,
                        step = setting.step or 0.1,
                        format = setting.format,
                        tooltip = setting.tooltip,
                    }
                )

            elseif setting.type == "color" then
                newValue, settingChanged = Components.ColorPicker(
                    setting.label or key,
                    value or { r = 1, g = 1, b = 1, a = 1 },
                    {
                        alpha = setting.alpha,
                        tooltip = setting.tooltip,
                    }
                )

            elseif setting.type == "keybind" then
                newValue, settingChanged = Components.KeyBind(
                    setting.label or key,
                    value or "",
                    {
                        tooltip = setting.tooltip,
                        allowMouse = setting.allowMouse,
                    }
                )

            elseif setting.type == "header" then
                Components.Separator(setting.label or key)

            elseif setting.type == "group" then
                Components.CollapsingSection(
                    setting.label or key,
                    not setting.collapsed,
                    function()
                        M.renderSettings(modId, { settings = setting.settings }, settings[key] or {})
                    end,
                    { tooltip = setting.tooltip }
                )

            elseif setting.type == "info" then
                Components.TextWrapped(setting.text or "")

            elseif setting.type == "button" then
                local clicked = Components.Button(
                    setting.label or key,
                    { tooltip = setting.tooltip }
                )
                if clicked and setting.action and type(setting.action) == "function" then
                    setting.action(settings)
                end

            elseif setting.type == "custom" then
                if setting.render and type(setting.render) == "function" then
                    local result = setting.render(settings, key)
                    if result ~= nil then
                        newValue = result
                        settingChanged = true
                    end
                end
            end

            -- Handle value change
            if settingChanged then
                -- Validate before applying
                local valid = Resolver.validateValue(setting, newValue)
                if valid then
                    settings[key] = newValue
                    changed = true
                    Core.markDirty()
                    Events.emit("configengine:settingChanged", modId, key, newValue, value)
                end
            end
        end
    end

    return changed
end

--- Render a single setting by key path.
---@param modId string The mod identifier
---@param spec table<string, any> The mod's registration spec
---@param settings table<string, any> The current settings
---@param keyPath string The dot-separated key path
---@return boolean changed True if changed
function M.renderSettingByKey(modId, spec, settings, keyPath)
    if not spec or not spec.settings then return false end

    local parts = {}
    for part in keyPath:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    -- Navigate to the setting definition
    local settingDef = spec.settings
    local settingValues = settings
    for i, part in ipairs(parts) do
        if i < #parts then
            if settingDef[part] and settingDef[part].type == "group" then
                settingDef = settingDef[part].settings or {}
                settingValues = settingValues[part] or {}
            else
                return false
            end
        else
            settingDef = settingDef[part]
            settingValues = settingValues[part]
        end
    end

    if not settingDef then return false end

    -- Render single setting
    local fakeSpec = { settings = { [parts[#parts]] = settingDef } }
    local fakeSettings = { [parts[#parts]] = settingValues }
    return M.renderSettings(modId, fakeSpec, fakeSettings)
end

return M
