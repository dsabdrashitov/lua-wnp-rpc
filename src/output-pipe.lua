local OutputPipe = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")

OutputPipe.__index = OutputPipe

function OutputPipe:_setClass(obj)
    setmetatable(obj, self)
end

function OutputPipe:new(fileHandle)
    local obj = {}
    self:_setClass(obj)
    obj:_init(fileHandle)
    return obj
end

function OutputPipe:_init(fileHandle)
    self.fileHandle = fileHandle
    self.bufferSize = 1
    self.buffer = lwp.ByteBlock_alloc(self.bufferSize)
end

function OutputPipe:write(obj)

end

return OutputPipe
