-- Config-Engine Undo/Redo System
-- Command pattern with ring buffer for settings changes.

---@class UndoRedo
local M = {}

-- State
---@type table[]
local undoStack = {}
---@type table[]
local redoStack = {}
---@type table[]
local batchStack = {}
---@type boolean
local inBatch = false
---@type table[]
local batchCommands = {}
---@type string
local batchDescription = ""
---@type number
local maxSteps = 50
---@type number
local maxRedoSteps = 50

-- Dependencies (late-bound)
---@type table|nil CfgCore module reference
local _cfgCore = nil
---@type table|nil CfgResolver module reference
local _cfgResolver = nil

--- Clear undo/redo entries for a specific mod.
---@param modId string The mod identifier
---@return nil
function M.clearForMod(modId)
    local function filterByMod(stack)
        local result = {}
        for _, cmd in ipairs(stack) do
            if cmd.type == "batch" then
                -- Filter batch sub-commands
                local filtered = {}
                for _, entry in ipairs(cmd.commands) do
                    local sub = entry.command or entry
                    if sub.modId ~= modId then
                        table.insert(filtered, entry)
                    end
                end
                if #filtered > 0 then
                    cmd.commands = filtered
                    table.insert(result, cmd)
                end
            elseif cmd.modId ~= modId then
                table.insert(result, cmd)
            end
        end
        return result
    end
    undoStack = filterByMod(undoStack)
    redoStack = filterByMod(redoStack)
end

--- Clear all undo/redo history.
---@return nil
function M.clear()
    undoStack = {}
    redoStack = {}
    batchCommands = {}
    inBatch = false
end

--- Apply a single command in the given direction ("undo" or "redo").
--- Requires CfgCore and CfgResolver to be set via M.init().
---@param cmd table The command to apply
---@param direction string "undo" or "redo"
---@return boolean success
function M.applyCommand(cmd, direction)
    if not _cfgCore or not _cfgResolver then
        return false
    end

    if cmd.type == "setting" then
        local mod = _cfgCore.getMod(cmd.modId)
        if mod and mod.settings then
            local value = (direction == "undo") and cmd.oldValue or cmd.newValue
            _cfgResolver.setValue(mod.settings, cmd.key, value)
            _cfgCore.markDirty()
            return true
        end
        return false
    elseif cmd.type == "preset" then
        local mod = _cfgCore.getMod(cmd.modId)
        if mod then
            mod.settings = (direction == "undo") and cmd.oldSettings or cmd.newSettings
            _cfgCore.markDirty()
            return true
        end
        return false
    elseif cmd.type == "batch" and cmd.commands then
        -- Undo iterates reverse, redo iterates forward
        local start, stop, step = 1, #cmd.commands, 1
        if direction == "undo" then
            start, stop, step = #cmd.commands, 1, -1
        end
        for i = start, stop, step do
            local sub = cmd.commands[i].command or cmd.commands[i]
            if sub.type == "setting" then
                local mod = _cfgCore.getMod(sub.modId)
                if mod and mod.settings then
                    local value = (direction == "undo") and sub.oldValue or sub.newValue
                    _cfgResolver.setValue(mod.settings, sub.key, value)
                end
            elseif sub.type == "preset" then
                local mod = _cfgCore.getMod(sub.modId)
                if mod then
                    mod.settings = (direction == "undo") and sub.oldSettings or sub.newSettings
                end
            end
        end
        _cfgCore.markDirty()
        return true
    end
    return false
end

--- Initialize the undo/redo system.
---@param options table|nil Optional: { maxSteps, maxRedoSteps, cfgCore, cfgResolver }
---@return nil
function M.init(options)
    options = options or {}
    maxSteps = options.maxSteps or 50
    maxRedoSteps = options.maxRedoSteps or 50
    _cfgCore = options.cfgCore or nil
    _cfgResolver = options.cfgResolver or nil
    undoStack = {}
    redoStack = {}
    batchStack = {}
    inBatch = false
    batchCommands = {}
    batchDescription = ""
end

--- Create a setting change command.
---@param modId string The mod ID
---@param key string The setting key
---@param oldValue any The previous value
---@param newValue any The new value
---@param description string|nil Optional description
---@return table The command
function M.makeSettingCommand(modId, key, oldValue, newValue, description)
    return {
        type = "setting",
        modId = modId,
        key = key,
        oldValue = oldValue,
        newValue = newValue,
        description = description or (modId .. "." .. key),
    }
end

--- Create a batch command from multiple commands.
---@param commands table Array of commands
---@param description string|nil Description of the batch
---@return table The batch command
function M.makeBatchCommand(commands, description)
    return {
        type = "batch",
        commands = commands,
        description = description or "Batch operation",
    }
end

--- Create a preset apply command.
---@param modId string The mod ID
---@param oldSettings table The previous settings
---@param newSettings table The new settings
---@param presetName string The preset name
---@return table The command
function M.makePresetCommand(modId, oldSettings, newSettings, presetName)
    return {
        type = "preset",
        modId = modId,
        oldSettings = oldSettings,
        newSettings = newSettings,
        description = "Apply preset: " .. presetName,
    }
end

--- Execute a command and push to undo stack.
---@param command table The command to execute
---@param applyFn fun(cmd: table): boolean Function to apply the command
---@return boolean success
function M.execute(command, applyFn)
    if inBatch then
        table.insert(batchCommands, { command = command, applyFn = applyFn })
        return true
    end

    local ok = applyFn(command)
    if not ok then
        return false
    end

    -- Push to undo stack
    table.insert(undoStack, command)

    -- Trim if over max
    while #undoStack > maxSteps do
        table.remove(undoStack, 1)
    end

    -- Clear redo stack on new action
    redoStack = {}

    return true
end

--- Undo the most recent command.
---@param applyFn fun(cmd: table): boolean Function to reverse the command
---@return table|nil The undone command, or nil if nothing to undo
function M.undo(applyFn)
    if inBatch then return nil end
    if #undoStack == 0 then return nil end

    local command = table.remove(undoStack)

    -- Reverse the command
    local reverseCmd = M._reverseCommand(command)
    local ok = applyFn(reverseCmd)
    if not ok then
        -- Re-push on failure
        table.insert(undoStack, command)
        return nil
    end

    table.insert(redoStack, command)

    -- Trim redo stack if over max
    while #redoStack > maxRedoSteps do
        table.remove(redoStack, 1)
    end

    return command
end

--- Redo the most recently undone command.
---@param applyFn fun(cmd: table): boolean Function to re-apply the command
---@return table|nil The redone command, or nil if nothing to redo
function M.redo(applyFn)
    if inBatch then return nil end
    if #redoStack == 0 then return nil end

    local command = table.remove(redoStack)
    local ok = applyFn(command)
    if not ok then
        table.insert(redoStack, command)
        return nil
    end

    table.insert(undoStack, command)
    return command
end

--- Begin a batch operation. Commands executed between begin/end are grouped.
---@param description string|nil Description of the batch
---@return nil
function M.beginBatch(description)
    if inBatch then
        -- Nest batches
        table.insert(batchStack, {
            commands = batchCommands,
            description = batchDescription,
        })
    end
    inBatch = true
    batchCommands = {}
    batchDescription = description or "Batch operation"
end

--- End a batch operation and execute as a single undo unit.
---@param applyFn fun(cmd: table): boolean Function to apply each command (used if no per-command applyFn)
---@return boolean success
function M.endBatch(applyFn)
    if not inBatch then return false end

    -- Check if we were nested
    if #batchStack > 0 then
        local outer = table.remove(batchStack)
        -- Merge inner commands into outer
        for _, entry in ipairs(batchCommands) do
            table.insert(outer.commands, entry)
        end
        batchCommands = outer.commands
        batchDescription = outer.description
        return true
    end

    inBatch = false

    if #batchCommands == 0 then
        return true
    end

    -- Execute all commands
    local commandOnly = {}
    for _, entry in ipairs(batchCommands) do
        local fn = entry.applyFn or applyFn
        local ok = fn(entry.command)
        if not ok then
            batchCommands = {}
            return false
        end
        table.insert(commandOnly, entry.command)
    end

    -- Create batch command and push to undo
    local batchCmd = M.makeBatchCommand(commandOnly, batchDescription)
    table.insert(undoStack, batchCmd)

    while #undoStack > maxSteps do
        table.remove(undoStack, 1)
    end

    redoStack = {}
    batchCommands = {}
    batchDescription = ""

    return true
end

--- Check if there are commands to undo.
---@return boolean
function M.canUndo()
    return not inBatch and #undoStack > 0
end

--- Check if there are commands to redo.
---@return boolean
function M.canRedo()
    return not inBatch and #redoStack > 0
end

--- Get the description of the next undo command (used by tests).
---@return string|nil
function M.getUndoDescription()
    if #undoStack == 0 then return nil end
    return undoStack[#undoStack].description
end

--- Get the description of the next redo command (used by tests).
---@return string|nil
function M.getRedoDescription()
    if #redoStack == 0 then return nil end
    return redoStack[#redoStack].description
end

--- Get undo stack size (used by tests).
---@return number
function M.getUndoCount()
    return #undoStack
end

--- Get redo stack size (used by tests).
---@return number
function M.getRedoCount()
    return #redoStack
end

--- Reverse a command for undo.
---@param command table The command to reverse
---@return table The reversed command
function M._reverseCommand(command)
    if command.type == "setting" then
        return M.makeSettingCommand(
            command.modId,
            command.key,
            command.newValue,
            command.oldValue,
            "Undo: " .. command.description
        )
    elseif command.type == "batch" then
        local reversed = {}
        -- Reverse order for batch undo
        for i = #command.commands, 1, -1 do
            table.insert(reversed, M._reverseCommand(command.commands[i]))
        end
        return M.makeBatchCommand(reversed, "Undo: " .. command.description)
    elseif command.type == "preset" then
        return M.makePresetCommand(
            command.modId,
            command.newSettings,
            command.oldSettings,
            "Undo: " .. command.description
        )
    end
    return command
end

return M
