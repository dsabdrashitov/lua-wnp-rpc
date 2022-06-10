local InputPipe = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local types = require("types")

InputPipe.__index = InputPipe

function InputPipe:_setClass(obj)
    setmetatable(obj, self)
end

function InputPipe:new(fileHandle)
    local obj = {}
    self:_setClass(obj)
    obj:_init(fileHandle)
    return obj
end

function InputPipe:_init(fileHandle)
    self.fileHandle = fileHandle
    self.bufferSize = 8
    self.buffer = lwp.ByteBlock_alloc(self.bufferSize)
    self.dwPointer = lwp.ByteBlock_alloc(lwp.SIZEOF_DWORD)
end

local class_switch

function InputPipe:read()
    local ok, r = self:_readRaw(1)
    if not ok then
        return false
    end
    local objType = string.byte(r)
    local objClass, objMask = types.decomposeType(objType)

    class_switch = class_switch or {
        [types.CLASS_VOID] = InputPipe._readNil,
        [types.CLASS_BOOLEAN] = InputPipe._readBoolean,
        [types.CLASS_INT] = InputPipe._readInt,
        [types.CLASS_FLOAT] = InputPipe._readFloat,
        [types.CLASS_STRING] = InputPipe._readString,
        [types.CLASS_TABLE] = InputPipe._readTable,
    }
    local read_method = class_switch[objClass]
    assert(read_method, string.format("error: unsupported class (%d)", objClass))
    return read_method(self, objMask)
end

function InputPipe:_readString(mask)
    local ok
    local len
    ok, len = self:_readInt(mask)
    if not ok then
        return false
    end
    local str
    ok, str = self:_readRaw(len)
    if not ok then
        return false
    end
    return true, str
end

function InputPipe:_readBoolean(mask)
    if mask == types.MASK_BOOL_TRUE then
        return true, true
    end
    if mask == types.MASK_BOOL_FALSE then
        return true, false
    end
    return false
end

function InputPipe:_readNil(mask)
    if mask == types.MASK_VOID then
        return true, nil
    end
    return false
end

function InputPipe:_readTable(mask)
    local ok
    local size
    ok, size = self:_readInt(mask)
    if not ok then
        return false
    end
    local result = {}
    for _ = 1, size do
        local key
        ok, key = self:read()
        if not ok then
            return false
        end
        local val
        ok, val = self:read()
        if not ok then
            return false
        end
        result[key] = val
    end
    return true, result
end

function InputPipe:_readInt(mask)
    local bytes = types.maskBytes(mask)
    local ok
    local str
    ok, str = self:_readRaw(bytes)
    if not ok then
        return false
    end
    local result = types.deserializeInt(str, mask)
    return true, result
end

function InputPipe:_readFloat(mask)
    local bytes = types.maskBytes(mask)
    local ok
    local str
    ok, str = self:_readRaw(bytes)
    if not ok then
        return false
    end
    local result = types.deserializeFloat(str, mask)
    if result == nil then
        return false
    end
    return true, result
end

function InputPipe:_readRaw(len)
    if (self.bufferSize < len) then
        while (self.bufferSize < len) do
            self.bufferSize = self.bufferSize * 2
        end
        self.buffer = lwp.ByteBlock_alloc(self.bufferSize)
    end
    local done = 0
    while done < len do
        lwp.ByteBlock_setOffset(self.buffer, done)
        local ok = lwp.ReadFile(self.fileHandle, self.buffer, len - done, self.dwPointer, nil)
        if not ok then
            return false
        end
        done = done + lwp.ByteBlock_getDWORD(self.dwPointer)
    end
    lwp.ByteBlock_setOffset(self.buffer, 0)
    local result = lwp.ByteBlock_getString(self.buffer, len)
    return true, result
end

return InputPipe
