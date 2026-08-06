-- Config-Engine Settings Renderer
-- Converts settings schemas to ImGui widgets automatically.
-- Uses UI-Engine components for all rendering.

---@class SettingsRenderer
local M = {}

-- Dependencies (late-bound)
local Core = nil
local Events = nil
local Components = nil
local UndoRedo = nil
local Resolver = nil

--- Initialize the settings renderer.
---@param deps table { core: CfgCore, events: table, components: table, undoRedo: UndoRedo, resolver: SettingsResolver }
---@return nil
function M.init(deps)
    Core = deps.core
    Events = deps.events
    Components = deps.components
    UndoRedo = deps.undoRedo
    Resolver = deps.resolver
end

--- Render settings for a mod.
---@param modId string The mod identifier
---@param spec table The mod's registration spec
---@param settings table The current resolved settings table
---@return boolean True if any setting changed
function M.renderSettings(modId, spec, settings)
    if not spec or not spec.settings then return false end
    if not settings then return false end
    if not Components then return false end

    -- DIAGNOSTIC: Log renderSettings call
    if not _renderDiagCount then _renderDiagCount = 0 end
    _renderDiagCount = _renderDiagCount + 1
    local _rNum = _renderDiagCount
    local _settingCount = 0
    if spec.settings then for _ in pairs(spec.settings) do _settingCount = _settingCount + 1 end end
    if _rNum <= 3 then
        print(string.format("[SettingsRenderer] CALL #%d: modId=%s, settings=%d, Components.AdvancedSlider=%s",
            _rNum, tostring(modId), _settingCount,
            tostring(type(Components.AdvancedSlider) == "function")))
    end

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
            -- DIAGNOSTIC: Log each setting type
            if _rNum <= 3 then
                print(string.format("[SettingsRenderer] CALL #%d setting '%s' type='%s' visible=%s",
                    _rNum, tostring(key), tostring(setting.type), tostring(visible)))
            end

            -- Render based on type (direct ImGui — no Components dependency)
            if setting.type == "toggle" then
                local label = setting.label or key
                local clicked
                newValue, clicked = ImGui.Checkbox(label, value)
                settingChanged = clicked

            elseif setting.type == "slider" then
                local label = setting.label or key
                local min = setting.min or 0
                local max = setting.max or 1
                local step = setting.step or 0.1
                local format = setting.format or "%.3f"
                local v = value or setting.default or min
                -- Use AdvancedSlider with minimal config (no ticks, no buttons)
                newValue, settingChanged = Components.AdvancedSlider(label, v, {
                    min = min,
                    max = max,
                    default = setting.default,
                    step = step,
                    format = format,
                    showTicks = false,
                    showButtons = false,
                    showDefaultLine = true,
                    showTooltip = true,
                    width = 256,
                    trackHeight = 12,
                })

            elseif setting.type == "int_slider" then
                local label = setting.label or key
                local min = setting.min or 0
                local max = setting.max or 100
                local step = setting.step or 1
                local v = math.floor(value or setting.default or min)
                -- Use AdvancedSlider with integer step
                local rawVal
                rawVal, settingChanged = Components.AdvancedSlider(label, v, {
                    min = min,
                    max = max,
                    default = setting.default,
                    step = step,
                    format = "%d",
                    showTicks = false,
                    showButtons = false,
                    showDefaultLine = true,
                    showTooltip = true,
                    width = 256,
                    trackHeight = 12,
                })
                newValue = math.floor(rawVal + 0.5)

            elseif setting.type == "combo" then
                local label = setting.label or key
                local options = setting.options or {}
                local currentIdx = 1
                for i, opt in ipairs(options) do
                    local optVal = type(opt) == "table" and opt.value or opt
                    if optVal == value then currentIdx = i; break end
                end
                local newIdx, newItem = ImGui.Combo(label, currentIdx - 1, options, #options)
                if newItem and newIdx ~= currentIdx - 1 then
                    local selected = options[newIdx + 1]
                    newValue = type(selected) == "table" and selected.value or selected
                    settingChanged = true
                end

            elseif setting.type == "multi_combo" then
                -- Simplified: just show a text placeholder for multi_combo
                ImGui.TextDisabled(setting.label or key .. " (multi-select)")
                settingChanged = false

            elseif setting.type == "text" then
                local label = setting.label or key
                local v = value or ""
                newValue, settingChanged = ImGui.InputText(label, v, 256)

            elseif setting.type == "number" then
                local label = setting.label or key
                local v = value or setting.default or 0
                newValue, settingChanged = ImGui.InputFloat(label, v, setting.step or 0.1, 1.0, setting.format or "%.3f")

            elseif setting.type == "color" then
                local label = setting.label or key
                local c = value or { r = 1, g = 1, b = 1, a = 1 }
                local arr = { c.r or 1, c.g or 1, c.b or 1, c.a or 1 }
                local changed
                changed, arr[1], arr[2], arr[3], arr[4] = ImGui.ColorEdit4(label, arr)
                if changed then
                    newValue = { r = arr[1], g = arr[2], b = arr[3], a = arr[4] }
                    settingChanged = true
                end

            elseif setting.type == "keybind" then
                local label = setting.label or key
                local v = value or ""
                ImGui.Text(label .. ": " .. v)
                settingChanged = false

            elseif setting.type == "header" then
                ImGui.Separator()

            elseif setting.type == "group" then
                local label = setting.label or key
                local open = not setting.collapsed
                if ImGui.CollapsingHeader(label, open and ImGuiTreeNodeFlags.DefaultOpen or 0) then
                    M.renderSettings(modId, { settings = setting.settings }, settings[key] or {})
                end

            elseif setting.type == "info" then
                ImGui.TextWrapped(setting.text or "")

            elseif setting.type == "button" then
                local clicked = ImGui.Button(setting.label or key)
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
                local valid = true
                if Resolver and Resolver.validateValue then
                    valid = Resolver.validateValue(setting, newValue)
                end
                if valid then
                    settings[key] = newValue
                    changed = true
                    if Core and Core.markDirty then Core.markDirty() end
                    if Events and Events.emit then
                        Events.emit("configengine:settingChanged", modId, key, newValue, value)
                    end
                end
            end
        end
    end

    return changed
end

--- Render a single setting by key path.
---@param modId string The mod identifier
---@param spec table The mod's registration spec
---@param settings table The current settings
---@param keyPath string The dot-separated key path
---@return boolean True if changed
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
