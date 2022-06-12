local OutgoingCalls = {}

local utils = require("utils")

OutgoingCalls.ERROR_PIPE = {message="pipe error"}
OutgoingCalls.ERROR_FORMAT = {message="protocol breach"}

OutgoingCalls.__index = OutgoingCalls

function OutgoingCalls:_setClass(obj)
    setmetatable(obj, self)
end

function OutgoingCalls:new(inputPipe, outputPipe)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputPipe, outputPipe)
    return obj
end

function OutgoingCalls:_init(inputPipe, outputPipe)
    self.inputPipe = inputPipe
    self.outputPipe = outputPipe
    self.broken = false
end

function OutgoingCalls:rootCall()
    return self:_call(0)
end

function OutgoingCalls:_call(remoteId, ...)
    self:_sendCall(remoteId, ...)
    return self:_receiveReply()
end

function OutgoingCalls:_sendCall(remoteId, ...)
    self:_pipesAssert(true)
    local args = {...}
    local argsCount = utils.lastIndex(args)
    self:_pipesAssert(self.outputPipe:write(remoteId))
    self:_pipesAssert(self.outputPipe:write(argsCount))
    for i = 1, argsCount do
        self:_pipesAssert(self.outputPipe:write(args[i]))
    end
end

function OutgoingCalls:_receiveReply()
    local retsCount = self:_pipesAssert(self.inputPipe:read())
    if type(retsCount) ~= "number" then
        error(self.ERROR_FORMAT)
    end
    if retsCount < 0 then
        if retsCount ~= -1 then
            error(self.ERROR_FORMAT)
        end
        local err = self:_pipesAssert(self.inputPipe:read())
        error(err)
    end
    local rets = {}
    for i = 1, retsCount do
        rets[i] = self:_pipesAssert(self.inputPipe:read())
    end
    return table.unpack(rets, 1, retsCount)
end

function OutgoingCalls:_pipesAssert(ok, value)
    if not ok then
        self.broken = true
    end
    if self.broken then
        error(self.ERROR_PIPE)
    end
    return value
end

return OutgoingCalls
