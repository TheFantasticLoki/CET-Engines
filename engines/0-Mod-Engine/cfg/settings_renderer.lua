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
local Tokens = nil  -- For section card styling
local _sectionHeights = {}  -- Cache for section card heights (keyed by section ID)

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

--- Resolve Tokens module for styling.
local function resolveTokens()
    if Tokens then return end
    local ok, mod = pcall(require, "ui/tokens")
    if ok then Tokens = mod end
end

--- Section card styling helpers (same as content_area.lua).
local _panelBg = nil
local _muted = nil

local function resolveColors()
    if _panelBg then return end
    resolveTokens()
    _panelBg = Tokens and Tokens.color4n("panel") or { r = 0.06, g = 0.06, b = 0.07 }
    _muted = Tokens and Tokens.color4n("muted") or { r = 0.5, g = 0.5, b = 0.6 }
end

--- Measure content height by rendering it offscreen, then restore cursor.
---@param buildFn function Content builder
---@return number Measured height in pixels
local function MeasureContentHeight(buildFn)
    local savedX, savedY = ImGui.GetCursorScreenPos()

    -- Render content invisibly to measure
    ImGui.PushStyleVar(ImGuiStyleVar.Alpha, 0.0)
    ImGui.BeginGroup()
    buildFn()
    ImGui.EndGroup()
    ImGui.PopStyleVar(1)

    local _, bottom = ImGui.GetItemRectMax()
    local measuredHeight = bottom - savedY

    -- Restore cursor position
    ImGui.SetCursorScreenPos(savedX, savedY)

    return measuredHeight
end

--- Draw a styled section card with cached height measurement.
--- On first render (no cache): measures content invisibly, caches the height,
--- then renders content inside a BeginChild with the correct size.
--- On subsequent frames: reuses cached height — no measurement needed.
--- When schema changes (clearHeightCache called), re-measures on next frame.
---@param id string Unique ID for the section
---@param buildFn function Content builder
local function SectionCard(id, buildFn)
    resolveColors()

    local contentHeight = _sectionHeights[id]

    if not contentHeight then
        -- First frame (or after cache clear): measure content height.
        -- MeasureContentHeight renders buildFn() invisibly to get the pixel height.
        -- NOTE: This creates widgets twice on the first frame only (once for measurement,
        -- once for display). AdvancedSlider's DrawList rendering bypasses Alpha=0, so
        -- ghost sliders appear briefly. This is acceptable — subsequent frames use cache.
        contentHeight = MeasureContentHeight(buildFn)
        _sectionHeights[id] = contentHeight
    end

    -- Add padding (top: 10, bottom: 10)
    local totalHeight = contentHeight + 20

    -- Clamp to available space (minimum 50px)
    local availW, availH = ImGui.GetContentRegionAvail()
    totalHeight = math.max(50, math.min(totalHeight, availH))

    -- Render with measured/cached height
    ImGui.PushStyleColor(ImGuiCol.ChildBg, _panelBg.r, _panelBg.g, _panelBg.b, 0.6)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 12, 10)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4)
    ImGui.BeginChild(id, -1, totalHeight, true)

    -- Build content (single render)
    buildFn()

    ImGui.EndChild()
    ImGui.PopStyleVar(2)
    ImGui.PopStyleColor(1)
end

--- Draw a section title.
---@param text string Title text
local function SectionTitle(text)
    resolveColors()
    ImGui.TextColored(_muted.r, _muted.g, _muted.b, 0.7, text)
    ImGui.Spacing()
end

--- Clear cached heights and force re-measurement on next frame.
function M.clearHeightCache()
    _sectionHeights = {}
end

-- ============================================================================
-- Setting Type Renderers (dispatch table)
-- ============================================================================

--- Render a toggle setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderToggle(key, setting, value)
    local label = setting.label or key
    local newValue, clicked = ImGui.Checkbox(label, value)
    return newValue, (newValue ~= value)
end

--- Render a slider setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderSlider(key, setting, value)
    local label = setting.label or key
    local min = setting.min or 0
    local max = setting.max or 1
    local step = setting.step or 0.1
    local format = setting.format or "%.3f"
    local v = value or setting.default or min
    ImGui.Text(label)
    ImGui.SetNextItemWidth(280)
    local newValue, changed = Components.AdvancedSlider("##" .. key, v, {
        min = min, max = max, default = setting.default,
        step = step, format = format, label = label,
        tooltip = setting.tooltip, description = setting.description,
        showTicks = false, showButtons = true, showDefaultLine = true,
        showTooltip = true, width = 280, trackHeight = 16,
    })
    ImGui.Spacing()
    return newValue, changed
end

--- Render an integer slider setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderIntSlider(key, setting, value)
    local label = setting.label or key
    local min = setting.min or 0
    local max = setting.max or 100
    local step = setting.step or 1
    local v = math.floor(value or setting.default or min)
    ImGui.Text(label)
    ImGui.SetNextItemWidth(280)
    local rawVal, changed = Components.AdvancedSlider("##" .. key, v, {
        min = min, max = max, default = setting.default,
        step = step, format = "%d", label = label,
        tooltip = setting.tooltip, description = setting.description,
        showTicks = false, showButtons = true, showDefaultLine = true,
        showTooltip = true, width = 280, trackHeight = 16,
    })
    ImGui.Spacing()
    return math.floor(rawVal + 0.5), changed
end

--- Render a combo box setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderCombo(key, setting, value)
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
        return type(selected) == "table" and selected.value or selected, true
    end
    return value, false
end

--- Render a multi-combo setting (placeholder).
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderMultiCombo(key, setting, value)
    ImGui.TextDisabled(setting.label or key .. " (multi-select)")
    return value, false
end

--- Render a text input setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderText(key, setting, value)
    local label = setting.label or key
    local v = value or ""
    return ImGui.InputText(label, v, 256)
end

--- Render a number input setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderNumber(key, setting, value)
    local label = setting.label or key
    local v = value or setting.default or 0
    return ImGui.InputFloat(label, v, setting.step or 0.1, 1.0, setting.format or "%.3f")
end

--- Render a color picker setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderColor(key, setting, value)
    local label = setting.label or key
    local c = value or { r = 1, g = 1, b = 1, a = 1 }
    local arr = { c.r or 1, c.g or 1, c.b or 1, c.a or 1 }
    local colorChanged
    colorChanged, arr[1], arr[2], arr[3], arr[4] = ImGui.ColorEdit4(label, arr)
    if colorChanged then
        return { r = arr[1], g = arr[2], b = arr[3], a = arr[4] }, true
    end
    return value, false
end

--- Render a keybind setting (placeholder).
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderKeybind(key, setting, value)
    local label = setting.label or key
    local v = value or ""
    ImGui.Text(label .. ": " .. v)
    return value, false
end

--- Render a header setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderHeader(key, setting, value)
    ImGui.Separator()
    return value, false
end

--- Render a group setting (collapsible header with nested settings).
---@param modId string Mod identifier
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderGroup(modId, key, setting, value, settings)
    local label = setting.label or key
    local open = not setting.collapsed
    if ImGui.CollapsingHeader(label, open and ImGuiTreeNodeFlags.DefaultOpen or 0) then
        M.renderSettings(modId, { settings = setting.settings }, value or {})
    end
    return value, false
end

--- Render an info setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderInfo(key, setting, value)
    ImGui.TextWrapped(setting.text or "")
    return value, false
end

--- Render a button setting.
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@return any newValue, boolean changed
local function renderButton(key, setting, value, settings)
    local clicked = ImGui.Button(setting.label or key)
    if clicked and setting.action and type(setting.action) == "function" then
        setting.action(settings)
    end
    return value, false
end

--- Render a custom setting (user-provided render function).
---@param key string Setting key
---@param setting table Setting definition
---@param value any Current value
---@param settings table All settings
---@return any newValue, boolean changed
local function renderCustom(key, setting, value, settings)
    if setting.render and type(setting.render) == "function" then
        local result = setting.render(settings, key)
        if result ~= nil then
            return result, true
        end
    end
    return value, false
end

-- Dispatch table mapping setting types to renderer functions
local renderers = {
    toggle = renderToggle,
    slider = renderSlider,
    int_slider = renderIntSlider,
    combo = renderCombo,
    multi_combo = renderMultiCombo,
    text = renderText,
    number = renderNumber,
    color = renderColor,
    keybind = renderKeybind,
    header = renderHeader,
    info = renderInfo,
    button = renderButton,
    custom = renderCustom,
}

-- Types that don't have a simple value change (handled separately)
local structuralTypes = {
    section = true,
    divider = true,
    spacer = true,
    custom_section = true,
    group = true,
}

--- Render settings for a mod.
---@param modId string The mod identifier
---@param spec table The mod's registration spec
---@param settings table The current resolved settings table
---@return boolean True if any setting changed
function M.renderSettings(modId, spec, settings)
    if not spec or not spec.settings then return false end
    if not settings then return false end
    if not Components then return false end

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
            -- Handle structural types (section, divider, spacer, custom_section)
            if setting.type == "section" then
                local sectionLabel = setting.label or key
                local sectionId = "##section_" .. key

                SectionCard(sectionId, function()
                    SectionTitle(sectionLabel)
                    -- Render nested settings
                    if setting.settings then
                        local nestedSpec = { settings = setting.settings }
                        local nestedSettings = settings[key] or {}
                        for k, _ in pairs(setting.settings) do
                            if settings[k] ~= nil then
                                nestedSettings[k] = settings[k]
                            end
                        end
                        if M.renderSettings(modId, nestedSpec, nestedSettings) then
                            for k, v in pairs(nestedSettings) do
                                if settings[k] ~= v then
                                    settings[k] = v
                                    changed = true
                                end
                            end
                        end
                    end
                end)

            elseif setting.type == "divider" then
                ImGui.Separator()
                ImGui.Spacing()

            elseif setting.type == "spacer" then
                local height = setting.height or 8
                ImGui.Dummy(0, height)

            elseif setting.type == "custom_section" then
                local sectionLabel = setting.label or key
                local sectionId = "##custom_section_" .. key

                if setting.render and type(setting.render) == "function" then
                    SectionCard(sectionId, function()
                        SectionTitle(sectionLabel)
                        local result = setting.render(settings, key)
                        if result ~= nil then
                            newValue = result
                            settingChanged = true
                        end
                    end)
                end

            elseif setting.type == "group" then
                newValue, settingChanged = renderGroup(modId, key, setting, value, settings)

            else
                -- Use dispatch table for simple setting types
                local renderer = renderers[setting.type]
                if renderer then
                    newValue, settingChanged = renderer(key, setting, value, settings)
                end
            end

            -- Handle value change
            if settingChanged then
                local valid = true
                if Resolver and Resolver.validateValue then
                    valid = Resolver.validateValue(setting, newValue)
                end
                if valid then
                    local oldValue = settings[key]
                    settings[key] = newValue
                    changed = true
                    if UndoRedo and UndoRedo.makeSettingCommand then
                        local cmd = UndoRedo.makeSettingCommand(modId, key, oldValue, newValue)
                        UndoRedo.execute(cmd, function(c)
                            return true
                        end)
                    end
                    if Events and Events.emit then
                        Events.emit("configengine:settingChanged", modId, key, newValue, oldValue)
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

    local fakeSpec = { settings = { [parts[#parts]] = settingDef } }
    local fakeSettings = { [parts[#parts]] = settingValues }
    return M.renderSettings(modId, fakeSpec, fakeSettings)
end

return M
