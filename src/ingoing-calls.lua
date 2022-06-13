local IngoingCalls = {}

local LocalFunctions = require("local-functions")
local InputPipe = require("input-pipe")
local OutputPipe = require("output-pipe")
local utils = require("utils")
local errors = require("errors")

IngoingCalls.__index = IngoingCalls

function IngoingCalls:_setClass(obj)
    setmetatable(obj, self)
end

function IngoingCalls:new(inputHandle, outputHandle, rootFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputHandle, outputHandle, rootFunction)
    return obj
end

function IngoingCalls:_init(inputHandle, outputHandle, rootFunction)
    self.inputPipe = InputPipe:new(inputHandle)
    self.outputPipe = OutputPipe:new(outputHandle)
    self.localFunctions = LocalFunctions:new(rootFunction)
    self.outputPipe:setLocalFunctions(self.localFunctions)
end

function IngoingCalls:setRemoteFunctions(remoteFunctions)
    self.inputPipe:setRemoteFunctions(remoteFunctions)
end

function IngoingCalls:receiveCall()
    local funcId = self.inputPipe:read()
    local argsCount = self.inputPipe:read()
    assert(type(argsCount) == "number", errors.ERROR_PROTOCOL)
    local args = {}
    for i = 1, argsCount do
        args[i] = self.inputPipe:read()
    end

    local func = self.localFunctions:getFunction(funcId)
    if not func then
        self:_replyError(string.format("no function with id (%s)", tostring(funcId)))
        return
    end
    local pcallResult = {pcall(func, table.unpack(args, 1, argsCount))}
    local ok = pcallResult[1]
    if not ok then
        local err = pcallResult[2]
        self:_replyError(err)
        return
    end
    self:_replyResult(pcallResult)
end

function IngoingCalls:_replyResult(pcallResult)
    local retsCount = utils.lastIndex(pcallResult) - 1
    self.outputPipe:write(retsCount)
    for i = 1, retsCount do
        self.outputPipe:write(pcallResult[i + 1])
    end
end

function IngoingCalls:_replyError(err)
    self.outputPipe:write(-1)
    self.outputPipe:write(err)
end

return IngoingCalls
