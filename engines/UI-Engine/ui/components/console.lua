--[[
    Console — UI-Engine Component Library

    Console components for log viewing and input.
    Includes ConsoleOutput, RichInput, ConsoleToolbar.

    Dependencies: ui/utils.lua, ui/tokens.lua, modules/logger.lua
]]

local M = {}

local Utils = require("ui/utils")
local Tokens = require("ui/tokens")

-- --- Console Output ---

--- Searchable log viewer
-- @param entries Array of log entry tables {timestamp, level, modName, message}
-- @param height Height in pixels
-- @param options Optional: {filter, autoScroll}
function M.ConsoleOutput(entries, height, options)
    entries = entries or {}
    height = height or 200
    options = options or {}
    local filter = options.filter
    local autoScroll = options.autoScroll ~= false

    -- Begin scrollable region
    Utils.SafeImGuiCall(ImGui.BeginChild, "##console_output", -1, height, false, ImGui.WindowFlags.HorizontalScrollbar)

    -- Render entries
    for _, entry in ipairs(entries) do
        local visible = true

        -- Apply filter if set
        if filter and filter ~= "" then
            local searchStr = (entry.message or "") .. (entry.modName or "")
            visible = string.find(searchStr:lower(), filter:lower()) ~= nil
        end

        if visible then
            -- Color based on level
            local color = { r = 1, g = 1, b = 1 }
            if entry.level == "error" then
                color = Tokens.color4n("secondary")
            elseif entry.level == "warn" then
                color = Tokens.color4n("favorite")
            elseif entry.level == "info" then
                color = Tokens.color4n("primary")
            else
                color = Tokens.color4n("muted")
            end

            -- Format: [timestamp] [level] modName: message
            local display = string.format("[%s] [%s] %s: %s",
                entry.timestamp or "",
                (entry.level or "debug"):upper(),
                entry.modName or "",
                entry.message or "")

            Utils.SafeImGuiCall(ImGui.TextColored, color.r, color.g, color.b, 1, display)
        end
    end

    -- Auto-scroll to bottom
    if autoScroll then
        Utils.SafeImGuiCall(ImGui.SetScrollHereY, 1.0)
    end

    Utils.SafeImGuiCall(ImGui.EndChild)
end

-- --- Rich Input ---

--- Input with history + shortcuts
-- @param prompt Prompt label
-- @param onSubmit Callback function(text)
-- @param options Optional: {history, placeholder}
-- @return string text, boolean submitted
function M.RichInput(prompt, onSubmit, options)
    prompt = prompt or "> "
    options = options or {}
    local history = options.history or {}
    local placeholder = options.placeholder or ""

    local text = ""
    local submitted = false

    -- Render input
    local changed, newText = Utils.SafeImGuiCall(ImGui.InputTextWithHint,
        "##rich_input", placeholder, text,
        ImGui.InputTextFlags.EnterReturnsTrue, nil, nil)

    if changed and newText and newText ~= "" then
        submitted = true
        text = newText

        -- Add to history
        table.insert(history, newText)

        -- Callback
        if onSubmit and type(onSubmit) == "function" then
            onSubmit(newText)
        end
    end

    -- Keyboard shortcuts
    if ImGui.IsKeyPressed and ImGui.IsKeyPressed(ImGui.Key.UpArrow) then
        -- Navigate history up
        if #history > 0 then
            text = history[#history]
        end
    end

    return text, submitted
end

-- --- Console Toolbar ---

--- Toolbar buttons
-- @param actions Array of action tables {label, icon, onClick, tooltip}
function M.ConsoleToolbar(actions)
    actions = actions or {}

    for _, action in ipairs(actions) do
        local label = action.icon or action.label or ""
        local tooltip = action.tooltip
        local onClick = action.onClick

        local clicked = Utils.SafeImGuiCall(ImGui.Button, label)

        if clicked and onClick and type(onClick) == "function" then
            onClick()
        end

        if tooltip and tooltip ~= "" then
            Utils.Tooltip(tooltip)
        end

        ImGui.SameLine()
    end
end

return M
