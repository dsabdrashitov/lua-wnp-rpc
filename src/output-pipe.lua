local OutputPipe = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local types = require("types")

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
    self.bufferSize = 8
    self.buffer = lwp.ByteBlock_alloc(self.bufferSize)
    self.dwPointer = lwp.ByteBlock_alloc(lwp.SIZEOF_DWORD)
end

local type_switch

function OutputPipe:write(obj)
    type_switch = type_switch or {
        ["string"] = OutputPipe._writeString,
        ["boolean"] = OutputPipe._writeBoolean,
        ["nil"] = OutputPipe._writeNil,
        ["number"] = OutputPipe._writeNumber,
        ["function"] = OutputPipe._writeFunction,
        ["table"] = OutputPipe._writeTable,
    }
    local write_method = type_switch[type(obj)]
    assert(write_method, string.format("error: unsupported type (%s)", type(obj)))
    return write_method(self, obj)
end

function OutputPipe:_writeString(str)
    local len = string.len(str)
    local intMask = types.intMask(len)
    local strType = types.composeType(types.CLASS_STRING, intMask)
    local header = string.char(strType) .. types.serializeInt(len, intMask)

    local result = true
    result = result and self:_writeRaw(header)
    result = result and self:_writeRaw(str)
    return result
end

function OutputPipe:_writeBoolean(val)
    local boolMask
    if val then
        boolMask = types.MASK_BOOL_TRUE
    else
        boolMask = types.MASK_BOOL_FALSE
    end
    local header = string.char(types.composeType(types.CLASS_BOOLEAN, boolMask))

    local result = true
    result = result and self:_writeRaw(header)
    return result
end

function OutputPipe:_writeRaw(str)
    local len = string.len(str)
    if (self.bufferSize < len) then
        while (self.bufferSize < len) do
            self.bufferSize = self.bufferSize * 2
        end
        self.buffer = lwp.ByteBlock_alloc(self.bufferSize)
    end
    lwp.ByteBlock_setString(self.buffer, str)
    local done = 0
    while done < len do
        lwp.ByteBlock_setOffset(self.buffer, done)
        local result = lwp.WriteFile(self.fileHandle, self.buffer, len - done, self.dwPointer, nil)
        if not result then
            return false
        end
        done = done + lwp.ByteBlock_getDWORD(self.dwPointer)
    end
    return true
end

return OutputPipe
