local DuplexCallsClient = {}

local DuplexCalls = require("duplex-calls")

DuplexCallsClient.__index = DuplexCallsClient
setmetatable(DuplexCallsClient, {__index = DuplexCalls})

function DuplexCallsClient:_setClass(obj)
    setmetatable(obj, self)
end

function DuplexCallsClient:new(inputHandle, outputHandle, processErrorFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputHandle, outputHandle, processErrorFunction)
    return obj
end

function DuplexCallsClient:_init(inputHandle, outputHandle, processErrorFunction)
    DuplexCalls._init(self, inputHandle, outputHandle, nil, processErrorFunction)
end

function DuplexCallsClient:callRemoteRoot(...)
    return self:_makeCall(0, ...)
end

return DuplexCallsClient
