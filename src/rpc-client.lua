local RPCClient = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local RPCServer = require("rpc-server")
local OutgoingCalls = require("outgoing-calls")

RPCClient._WAIT_TIMEOUT_MS = 15000

RPCClient.__index = RPCClient

function RPCClient:_setClass(obj)
    setmetatable(obj, self)
end

function RPCClient:new(name)
    local obj = {}
    self:_setClass(obj)
    obj:_init(name)
    return obj
end

function RPCClient:_init(name)
    local pipeName = RPCServer:pipeAddress(name)
    local ret = lwp.WaitNamedPipe(pipeName, self._WAIT_TIMEOUT_MS)
    if not ret then
        self.pipe = nil
        return
    end

    self.pipe = lwp.CreateFile(
            pipeName,
            lwp.mask(lwp.GENERIC_READ, lwp.GENERIC_WRITE),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.OPEN_EXISTING,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )

    if (self.pipe == lwp.INVALID_HANDLE_VALUE) then
        self.pipe = nil
        return
    end

    local onConnectionError = function(err)
        self:close()
        error(err)
    end
    self.outgoingCalls = OutgoingCalls:new(self.pipe, self.pipe, onConnectionError)
end

function RPCClient:active()
    return self.pipe ~= nil
end

function RPCClient:close()
    self.outgoingCalls = nil
    if self.pipe ~= nil then
        lwp.CloseHandle(self.pipe)
        self.pipe = nil
    end
end

function RPCClient:rootCall(...)
    return self.outgoingCalls:rootCall(...)
end

return RPCClient
