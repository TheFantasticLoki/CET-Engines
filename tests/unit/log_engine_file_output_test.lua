--[[
    Log-Engine FileOutput Tests

    Tests for engines/Log-Engine/file_output.lua

    Note: File I/O is mocked in these tests. The tests verify
    the logic (path resolution, rotation, formatting) without
    touching the real filesystem.
]]

local assert = require("tests.assert")

-- Mock io.open to capture writes without touching the filesystem
local mockFiles = {}
local mockSizes = {}

local originalIoOpen = io.open

local function mockIoOpen(path, mode)
    if mode == "a" or mode == "w" then
        -- Track writes
        if not mockFiles[path] then
            mockFiles[path] = { content = "", size = 0 }
        end
        if mode == "w" then
            mockFiles[path] = { content = "", size = 0 }
        end
        -- Return a mock file handle
        return {
            write = function(self, data)
                mockFiles[path].content = mockFiles[path].content .. data
                mockFiles[path].size = mockFiles[path].size + #data
                mockSizes[path] = mockFiles[path].size
            end,
            close = function(self) end,
            seek = function(self, whence, offset)
                if whence == "end" then
                    return mockFiles[path].size
                elseif whence == "set" then
                    return offset or 0
                elseif whence == "cur" then
                    return mockFiles[path].size + (offset or 0)
                end
                return 0
            end,
        }
    elseif mode == "r" then
        if mockFiles[path] and mockFiles[path].content ~= "" then
            local pos = 1
            return {
                read = function(self, spec)
                    if spec == "*a" then
                        local content = mockFiles[path].content
                        mockFiles[path].content = ""
                        return content
                    end
                    return nil
                end,
                close = function(self) end,
                seek = function(self, whence, offset)
                    if whence == "end" then
                        return mockFiles[path].size
                    end
                    return 0
                end,
            }
        end
        return nil
    end
    return nil
end

local function installMock()
    io.open = mockIoOpen
    mockFiles = {}
    mockSizes = {}
end

local function uninstallMock()
    io.open = originalIoOpen
    mockFiles = {}
    mockSizes = {}
end

-- --- Tests ---

local FileOutput  -- Will be required after mock is installed

local M = {}

function M.testInit()
    installMock()
    FileOutput = require("engines.Log-Engine.file_output")
    -- Reset initialization state by re-requiring
    -- (In real code, init is idempotent)
    FileOutput.init()
    FileOutput.init()  -- Should not error
    assert.assert_true(true, "Init should be idempotent")
    uninstallMock()
end

function M.testWriteCreatesFile()
    installMock()
    -- Re-require to get fresh module with mock
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()
    FileOutput.setSessionId("test1234")

    FileOutput.write("test-mod", {
        timestamp = "12:00:00.000",
        levelName = "INFO",
        frame = 1,
        modName = "test-mod",
        message = "Hello world",
    })

    -- Verify a file was written
    local written = false
    for path, data in pairs(mockFiles) do
        if data.size > 0 then
            written = true
            assert.assert_true(data.content:find("Hello world") ~= nil, "File should contain the message")
            assert.assert_true(data.content:find("INFO") ~= nil, "File should contain the level")
        end
    end
    assert.assert_true(written, "At least one file should have been written")
    uninstallMock()
end

function M.testSetFilePath()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()
    FileOutput.setSessionId("test1234")

    FileOutput.setFilePath("custom-mod", "custom/path.log")

    FileOutput.write("custom-mod", {
        timestamp = "00:00:00.000",
        levelName = "INFO",
        frame = 1,
        modName = "custom-mod",
        message = "Custom path test",
    })

    -- The custom path should be used
    local found = false
    for path, data in pairs(mockFiles) do
        if path:find("custom/path.log") and data.size > 0 then
            found = true
        end
    end
    assert.assert_true(found, "Should write to custom path")
    uninstallMock()
end

function M.testFormatLine()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()
    FileOutput.setSessionId("test1234")

    FileOutput.write("fmt-test", {
        timestamp = "12:30:45.123",
        levelName = "ERROR",
        frame = 42,
        modName = "fmt-test",
        message = "Something broke",
    })

    for path, data in pairs(mockFiles) do
        if data.size > 0 then
            -- Verify format: [timestamp] [LEVEL] [frame] modName: message
            assert.assert_true(data.content:find("%[12:30:45%.123%]"), "Should have time-only timestamp")
            assert.assert_true(data.content:find("%[ERROR%]"), "Should have level")
            assert.assert_true(data.content:find("%[42%]"), "Should have frame number")
            assert.assert_true(data.content:find("fmt-test:"), "Should have modName")
            assert.assert_true(data.content:find("Something broke"), "Should have message")
        end
    end
    uninstallMock()
end

function M.testGetFilePath()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()

    local path = FileOutput.getFilePath("some-mod")
    assert.assert_not_nil(path, "Should return a file path")
    -- Note: in Lua patterns, hyphen is a special char, so check with plain string ops
    assert.assert_true(path:find("some") ~= nil, "Path should contain mod name")
    assert.assert_true(path:find("%.log") ~= nil, "Path should end with .log")
    uninstallMock()
end

function M.testFlushAll()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()

    -- Should not error
    FileOutput.flushAll()
    assert.assert_true(true, "flushAll should not error")
    uninstallMock()
end

function M.testCloseAll()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()
    FileOutput.setSessionId("test1234")

    FileOutput.write("close-test", {
        timestamp = "00:00:00.000",
        levelName = "INFO",
        frame = 1,
        modName = "close-test",
        message = "test",
    })

    -- Should not error
    FileOutput.closeAll()
    assert.assert_true(true, "closeAll should not error")
    uninstallMock()
end

function M.testIsEnabled()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()

    assert.assert_true(FileOutput.isEnabled(), "File output should be enabled by default")
    uninstallMock()
end

-- --- Test Session Header ---

function M.testSessionHeader()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()
    FileOutput.setSessionId("abc12345")

    FileOutput.write("header-test", {
        timestamp = "12:00:00.000",
        levelName = "INFO",
        frame = 1,
        modName = "header-test",
        message = "First message",
    })

    for path, data in pairs(mockFiles) do
        if data.size > 0 then
            -- Verify header is present
            assert.assert_true(data.content:find("=== Log Session ==="), "Should have header start")
            assert.assert_true(data.content:find("Session: abc12345"), "Should have session ID")
            assert.assert_true(data.content:find("Mod: header-test"), "Should have mod name")
            assert.assert_true(data.content:find("Started:"), "Should have start time")
            assert.assert_true(data.content:find("Level:"), "Should have level")
            assert.assert_true(data.content:find("Ring Buffer:"), "Should have ring buffer size")
            assert.assert_true(data.content:find("==================="), "Should have header end")
        end
    end
    uninstallMock()
end

function M.testSessionId()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()

    FileOutput.setSessionId("test1234")
    assert.assert_equal(FileOutput.getSessionId(), "test1234", "Should return session ID")

    FileOutput.setSessionId("new5678")
    assert.assert_equal(FileOutput.getSessionId(), "new5678", "Should update session ID")
    uninstallMock()
end

-- --- Test Dedup Summary ---

function M.testWriteDedupSummary()
    installMock()
    package.loaded["engines.Log-Engine.file_output"] = nil
    FileOutput = require("engines.Log-Engine.file_output")
    FileOutput.init()
    FileOutput.setSessionId("test1234")

    FileOutput.writeDedupSummary("dedup-test", 5, "12:00:00.000", "Something broke")

    for path, data in pairs(mockFiles) do
        if data.size > 0 then
            assert.assert_true(data.content:find("DEDUP"), "Should have DEDUP tag")
            assert.assert_true(data.content:find("x5 duplicates"), "Should have duplicate count")
            assert.assert_true(data.content:find("Something broke"), "Should have original message")
        end
    end
    uninstallMock()
end