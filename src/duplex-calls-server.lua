local DuplexCallsServer = {}

local DuplexCalls = require("duplex-calls")

DuplexCallsServer.__index = DuplexCallsServer
setmetatable(DuplexCallsServer, {__index = DuplexCalls})

function DuplexCallsServer:_setClass(obj)
    setmetatable(obj, self)
end

function DuplexCallsServer:new(inputHandle, outputHandle, rootFunction, processErrorFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputHandle, outputHandle, rootFunction, processErrorFunction)
    return obj
end

function DuplexCallsServer:_init(inputHandle, outputHandle, rootFunction, processErrorFunction)
    DuplexCalls._init(self, inputHandle, outputHandle, rootFunction, processErrorFunction)
    self.inside_process = false
    self.deferred_call = nil
    self.deferred_result = nil
end

function DuplexCallsServer:processCall()
    self.inside_process = true
    self:__pcall(self._receiveRequest, self)
    self.inside_process = false
end

function DuplexCallsServer:empty()
    return self:__pcall(self._empty, self)
end

function DuplexCallsServer:_makeCall(funcId, ...)
    if self.inside_process then
        self:__pcall(self._sendRequest, self, funcId, ...)
        return self:__pcall(self._receiveReply, self)
    else
        self.deferred_call = {
            funcId = funcId,
            args = {...},
        }
        self:processCall()
        local result = self.deferred_result
        self.deferred_result = nil
        if result[1] then
            return table.unpack(result, 2)
        else
            error(result[2])
        end
    end
end

function DuplexCallsServer:_readRequest(argsCount)
    local funcId = self.inputPipe:read()
    local args = {}
    for i = 1, argsCount do
        args[i] = self.inputPipe:read()
    end

    if self.deferred_call ~= nil then
        local call = self.deferred_call
        self.deferred_call = nil
        self.deferred_result = pcall(self._makeCall, self, call.funcId, table.unpack(call.args))
    end

    local func = self.localFunctions:getFunction(funcId)
    if not func then
        self:_sendError(string.format("no function with id (%s)", tostring(funcId)))
        return
    end

    local pcallResult = {pcall(func, table.unpack(args, 1, argsCount))}

    local ok = pcallResult[1]
    if not ok then
        local err = pcallResult[2]
        self:_sendError(err)
        return
    end
    self:_sendResults(pcallResult)
end

return DuplexCallsServer
