local DuplexCalls = {}

local LocalFunctions = require("local-functions")
local RemoteFunctions = require("remote-functions")
local InputPipe = require("input-pipe")
local OutputPipe = require("output-pipe")
local utils = require("utils")
local errors = require("errors")

DuplexCalls.__index = DuplexCalls

function DuplexCalls:_setClass(obj)
    setmetatable(obj, self)
end

function DuplexCalls:new(inputHandle, outputHandle, rootFunction, processErrorFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputHandle, outputHandle, rootFunction, processErrorFunction)
    return obj
end

function DuplexCalls:_init(inputHandle, outputHandle, rootFunction, processErrorFunction)
    self.inputPipe = InputPipe:new(inputHandle)
    self.outputPipe = OutputPipe:new(outputHandle)

    self.localFunctions = LocalFunctions:new(rootFunction)
    self.outputPipe:setLocalFunctions(self.localFunctions)

    self.processErrorFunction = processErrorFunction
    local makeCall = function(funcId, ...)
        self:_makeCall(funcId, ...)
    end
    self.remoteFunctions = RemoteFunctions:new(makeCall)
    self.inputPipe:setRemoteFunctions(self.remoteFunctions)
end

function DuplexCalls:callRemoteRoot(...)
    return self:_makeCall(0, ...)
end

function DuplexCalls:processCall()
    self:__pcall(self._receiveRequest, self)
end

function DuplexCalls:_makeCall(funcId, ...)
    self:__pcall(self._sendRequest, self, funcId, ...)
    return self:__pcall(self._receiveReply, self)
end

function DuplexCalls:__pcall(func, ...)
    local rets = {pcall(func, ...)}
    local ok = rets[1]
    if ok then
        local retsSize = utils.lastIndex(rets)
        return table.unpack(rets, 2, retsSize)
    end
    local err = rets[2]
    if (err == errors.ERROR_PROTOCOL) or (err == errors.ERROR_PIPE) then
        if self.processErrorFunction then
            return self.processErrorFunction(err)
        end
    end
    error(err)
end

function DuplexCalls:_sendRequest(funcId, ...)
    local args = {...}
    local argsCount = utils.lastIndex(args)
    -- Positive - arguments count, negative - returns count, zero - error
    self.outputPipe:write(1 + argsCount)
    self.outputPipe:write(funcId)
    for i = 1, argsCount do
        self.outputPipe:write(args[i])
    end
end

function DuplexCalls:_receiveReply()
    while true do
        -- Positive - arguments count, negative - returns count, zero - error
        local header = self.inputPipe:read()
        assert(type(header) == "number", errors.ERROR_PROTOCOL)
        if header > 0 then
            self:_readRequest(header - 1)
            goto continue
        end
        if header == 0 then
            local err = self.inputPipe:read()
            error(err)
        end
        if header < 0 then
            local retsCount = -header - 1
            local rets = {}
            for i = 1, retsCount do
                rets[i] = self.inputPipe:read()
            end
            return table.unpack(rets, 1, retsCount)
        end
        ::continue::
    end
end

function DuplexCalls:_receiveRequest()
    -- Positive - arguments count, negative - returns count, zero - error
    local header = self.inputPipe:read()
    assert(type(header) == "number", errors.ERROR_PROTOCOL)
    assert(header > 0, errors.ERROR_PROTOCOL)
    local argsCount = header - 1
    self:_readRequest(argsCount)
end

function DuplexCalls:_readRequest(argsCount)
    local funcId = self.inputPipe:read()
    local args = {}
    for i = 1, argsCount do
        args[i] = self.inputPipe:read()
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

function DuplexCalls:_sendResults(pcallResult)
    local retsCount = utils.lastIndex(pcallResult) - 1
    self.outputPipe:write(-retsCount - 1)
    for i = 1, retsCount do
        self.outputPipe:write(pcallResult[1 + i])
    end
end

function DuplexCalls:_sendError(err)
    self.outputPipe:write(0)
    self.outputPipe:write(err)
end

return DuplexCalls
