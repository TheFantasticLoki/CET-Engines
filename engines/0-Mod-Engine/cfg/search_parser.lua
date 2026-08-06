-- Search Parser — Config Engine
-- Parses advanced search syntax from the sidebar search bar.
--
-- Supported syntax:
--   "myMod"                    → substring match on name/id
--   tag="favorite"             → filter by tag
--   category="Framework"       → filter by category
--   tag=favorite               → unquoted also works
--   tag="favorite" category="Dev" → combined AND filters
--   "myMod" tag="favorite"     → literal + filter combined
--
-- Graceful degradation:
--   Malformed tokens are skipped, not fatal
--   Unrecognized text becomes a substring filter
--   Empty/missing values are rejected

---@class SearchParser
local M = {}

--- Parse a search query string into structured filters.
---@param query string The raw search query
---@return table { text = "substring", filters = { { key, value }, ... } }
function M.parse(query)
    if not query or type(query) ~= "string" or #query == 0 then
        return { text = "", filters = {} }
    end

    local filters = {}
    local literal = query

    -- Extract quoted key="value" pairs (e.g., tag="favorite")
    for key, value in query:gmatch('(%w+)="([^"]*)"') do
        if #value > 0 then
            table.insert(filters, { key = key:lower(), value = value:lower() })
            literal = literal:gsub(key .. '="[^"]*"', "")
        end
    end

    -- Extract unquoted key=value pairs (e.g., tag=favorite)
    -- Only match if not already captured by quoted pattern
    for key, value in query:gmatch('(%w+)=([%w_]+)') do
        local alreadyMatched = false
        for _, f in ipairs(filters) do
            if f.key == key:lower() then
                alreadyMatched = true
                break
            end
        end
        if not alreadyMatched then
            table.insert(filters, { key = key:lower(), value = value:lower() })
            literal = literal:gsub(key .. "=[%w_]+", "")
        end
    end

    -- Clean up literal: remove quotes, trim whitespace
    literal = literal:gsub('^%s+"?', ""):gsub('"?%s*$', "")
    literal = literal:gsub("^%s+", ""):gsub("%s+$", "")

    return { text = literal, filters = filters }
end

--- Check if a mod matches the parsed search criteria.
---@param mod table The mod state { spec, tags, ... }
---@param modId string The mod identifier
---@param category table|nil The mod's category assignment { category, subcategory }
---@param parsed table The parsed search result from M.parse()
---@return boolean True if the mod matches all criteria
function M.matches(mod, modId, category, parsed)
    if not parsed then return true end

    -- Check literal substring match (against name, id, description)
    if parsed.text and #parsed.text > 0 then
        local spec = mod.spec or {}
        local label = (spec.name or ""):lower()
        local id = (modId or ""):lower()
        local desc = (spec.description or ""):lower()
        local searchLower = parsed.text:lower()

        local nameMatch = label:find(searchLower, 1, true)
        local idMatch = id:find(searchLower, 1, true)
        local descMatch = desc:find(searchLower, 1, true)

        if not nameMatch and not idMatch and not descMatch then
            return false
        end
    end

    -- Check filter criteria (all must match — AND logic)
    for _, filter in ipairs(parsed.filters) do
        if filter.key == "tag" then
            -- Check if mod has this tag
            local modTags = mod.tags or {}
            local hasTag = false
            for _, t in ipairs(modTags) do
                if t:lower() == filter.value then
                    hasTag = true
                    break
                end
            end
            if not hasTag then return false end

        elseif filter.key == "category" then
            -- Check if mod is in this category
            if not category or not category.category then
                return false
            end
            if category.category:lower() ~= filter.value then
                return false
            end

        elseif filter.key == "author" then
            -- Check author match
            local spec = mod.spec or {}
            local author = (spec.author or ""):lower()
            if not author:find(filter.value, 1, true) then
                return false
            end

        -- Unknown filter keys are ignored (graceful degradation)
        end
    end

    return true
end

return M
