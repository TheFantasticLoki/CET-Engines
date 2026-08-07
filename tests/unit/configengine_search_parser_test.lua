-- Test: ConfigEngine SearchParser
-- Stub smoke tests for cfg/search_parser.lua

local M = {}

function M.testModuleLoads()
    local SP = require("cfg/search_parser")
    assert(SP ~= nil, "SearchParser should load")
    assert(type(SP.parse) == "function", "should have parse()")
    assert(type(SP.matches) == "function", "should have matches()")
end

function M.testParseEmptyQuery()
    local SP = require("cfg/search_parser")
    local result = SP.parse("")
    assert(result.text == "", "empty text")
    assert(#result.filters == 0, "no filters")
end

function M.testParseLiteralText()
    local SP = require("cfg/search_parser")
    local result = SP.parse("myMod")
    assert(result.text == "myMod", "literal text preserved")
    assert(#result.filters == 0, "no filters")
end

function M.testParseQuotedFilter()
    local SP = require("cfg/search_parser")
    local result = SP.parse('tag="favorite"')
    assert(result.text == "", "text cleared")
    assert(#result.filters == 1, "one filter")
    assert(result.filters[1].key == "tag", "filter key is tag")
    assert(result.filters[1].value == "favorite", "filter value is favorite")
end

function M.testParseUnquotedFilter()
    local SP = require("cfg/search_parser")
    local result = SP.parse("tag=favorite")
    assert(#result.filters == 1, "one filter")
    assert(result.filters[1].key == "tag", "filter key")
    assert(result.filters[1].value == "favorite", "filter value")
end

function M.testParseCombinedQuery()
    local SP = require("cfg/search_parser")
    local result = SP.parse('myMod tag="favorite"')
    assert(result.text == "myMod", "literal text")
    assert(#result.filters == 1, "one filter")
end

function M.testParseNilInput()
    local SP = require("cfg/search_parser")
    local result = SP.parse(nil)
    assert(result.text == "", "nil -> empty")
end

return M
