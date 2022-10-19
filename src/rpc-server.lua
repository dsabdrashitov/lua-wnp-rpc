local RPCServer = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local DuplexCallsServer = require("duplex-calls-server")

RPCServer.PIPE_NAME_FORMAT = "\\\\.\\pipe\\%s"

RPCServer._OUT_BUFFER_SIZE = 512
RPCServer._IN_BUFFER_SIZE = 512
RPCServer._PIPE_TIMEOUT_MS = 1000

RPCServer.__index = RPCServer

function RPCServer:_setClass(obj)
    setmetatable(obj, self)
end

function RPCServer:new(name, rootFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(name, rootFunction)
    return obj
end

function RPCServer:pipeAddress(name)
    return string.format(self.PIPE_NAME_FORMAT, name)
end

function RPCServer:_init(name, rootFunction)
    local pipeName = self:pipeAddress(name)
    self.pipe = lwp.CreateNamedPipe(
            pipeName,
            lwp.PIPE_ACCESS_DUPLEX,
            lwp.mask(lwp.PIPE_TYPE_BYTE, lwp.PIPE_READMODE_BYTE, lwp.PIPE_WAIT),
            lwp.PIPE_UNLIMITED_INSTANCES,
            self._OUT_BUFFER_SIZE,
            self._IN_BUFFER_SIZE,
            self._PIPE_TIMEOUT_MS,
            nil
    )

    if (self.pipe == lwp.INVALID_HANDLE_VALUE) then
        self.pipe = nil
        return
    end

    local ret = lwp.ConnectNamedPipe(self.pipe, nil)
    if (not ret) and (lwp.GetLastError() ~= lwp.ERROR_PIPE_CONNECTED) then
        self:close()
        return
    end

    local processError = function(err)
        self:close()
        error(err)
    end
    self.calls = DuplexCallsServer:new(self.pipe, self.pipe, rootFunction, processError)
end

function RPCServer:active()
    return self.pipe ~= nil
end

function RPCServer:close()
    self.calls = nil
    if self.pipe ~= nil then
        -- return of CloseHandle can be false, but since this server is closing there is no sense in handling error
        lwp.CloseHandle(self.pipe)
        self.pipe = nil
    end
end

function RPCServer:processCall()
    if not self:active() then
        return false
    end
    if self.calls:empty() then
        return false
    end
    self.calls:processCall()
    return true
end

return RPCServer
