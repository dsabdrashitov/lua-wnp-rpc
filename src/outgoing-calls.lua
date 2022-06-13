local OutgoingCalls = {}

local RemoteFunctions = require("remote-functions")
local InputPipe = require("input-pipe")
local OutputPipe = require("output-pipe")
local utils = require("utils")
local errors = require("errors")

OutgoingCalls.__index = OutgoingCalls

function OutgoingCalls:_setClass(obj)
    setmetatable(obj, self)
end

function OutgoingCalls:new(inputHandle, outputHandle)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputHandle, outputHandle)
    return obj
end

function OutgoingCalls:_init(inputHandle, outputHandle)
    self.inputPipe = InputPipe:new(inputHandle)
    self.outputPipe = OutputPipe:new(outputHandle)
    self.remoteFunctions = RemoteFunctions:new(self)
    self.inputPipe:setRemoteFunctions(self.remoteFunctions)
end

function OutgoingCalls:setLocalFunctions(localFunctions)
    self.outputPipe:setLocalFunctions(localFunctions)
end

function OutgoingCalls:rootCall(...)
    return self:_call(0, ...)
end

function OutgoingCalls:_call(remoteId, ...)
    --TODO: catch errors and report
    self:_sendCall(remoteId, ...)
    return self:_receiveReply()
end

function OutgoingCalls:_sendCall(remoteId, ...)
    local args = {...}
    local argsCount = utils.lastIndex(args)
    self.outputPipe:write(remoteId)
    self.outputPipe:write(argsCount)
    for i = 1, argsCount do
        self.outputPipe:write(args[i])
    end
end

function OutgoingCalls:_receiveReply()
    local retsCount = self.inputPipe:read()
    assert(type(retsCount) == "number", errors.ERROR_PROTOCOL)
    if retsCount < 0 then
        assert(retsCount == -1, errors.ERROR_PROTOCOL)
        local err = self.inputPipe:read()
        error(err)
    end
    local rets = {}
    for i = 1, retsCount do
        rets[i] = self.inputPipe:read()
    end
    return table.unpack(rets, 1, retsCount)
end

return OutgoingCalls
