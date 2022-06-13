local IngoingCalls = {}

local FunctionsMap = require("functions-map")
local utils = require("utils")
local errors = require("errors")

IngoingCalls.__index = IngoingCalls

function IngoingCalls:_setClass(obj)
    setmetatable(obj, self)
end

function IngoingCalls:new(inputPipe, outputPipe, rootFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputPipe, outputPipe, rootFunction)
    return obj
end

function IngoingCalls:_init(inputPipe, outputPipe, rootFunction)
    self.inputPipe = inputPipe
    self.outputPipe = outputPipe
    self.fmap = FunctionsMap:new(rootFunction)
end

function IngoingCalls:receiveCall()
    local funcId = self.inputPipe:read()
    local argsCount = self.inputPipe:read()
    assert(type(argsCount) == "number", errors.ERROR_PROTOCOL)
    local args = {}
    for i = 1, argsCount do
        args[i] = self.inputPipe:read()
    end

    local func = self.fmap:getFunction(funcId)
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
