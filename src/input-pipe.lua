local InputPipe = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local types = require("types")
local errors = require("errors")

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
    self.remoteFunctions = nil
end

function InputPipe:setRemoteFunctions(remoteFunctions)
    self.remoteFunctions = remoteFunctions
end

function InputPipe:read()
    return self:_read({count = 0})
end

local class_switch

function InputPipe:_read(stored_objects)
    local r = self:_readRaw(1)
    local objType = string.byte(r)
    local objClass, objMask = types.decomposeType(objType)

    class_switch = class_switch or {
        [types.CLASS_VOID] = InputPipe._readNil,
        [types.CLASS_BOOLEAN] = InputPipe._readBoolean,
        [types.CLASS_INT] = InputPipe._readInt,
        [types.CLASS_FLOAT] = InputPipe._readFloat,
        [types.CLASS_STRING] = InputPipe._readString,
        [types.CLASS_TABLE] = InputPipe._readTable,
        [types.CLASS_LINK] = InputPipe._readLink,
        [types.CLASS_FUNCTION] = InputPipe._readFunction,
    }
    local read_method = class_switch[objClass]
    if not read_method then
        error(errors.ERROR_PROTOCOL)
    end
    return read_method(self, objMask, stored_objects)
end

function InputPipe:_readString(mask)
    local len = self:_readInt(mask)
    local str = self:_readRaw(len)
    return str
end

function InputPipe:_readBoolean(mask)
    if mask == types.MASK_BOOL_TRUE then
        return true
    end
    if mask == types.MASK_BOOL_FALSE then
        return false
    end
    error(errors.ERROR_PROTOCOL)
end

function InputPipe:_readNil(mask)
    if mask == types.MASK_VOID then
        return nil
    end
    error(errors.ERROR_PROTOCOL)
end

function InputPipe:_readTable(mask, stored_objects)
    local size = self:_readInt(mask)
    local result = {}
    stored_objects[stored_objects.count] = result
    stored_objects.count = stored_objects.count + 1
    for _ = 1, size do
        local key = self:_read(stored_objects)
        local val = self:_read(stored_objects)
        result[key] = val
    end
    return result
end

function InputPipe:_readLink(mask, stored_objects)
    local link_id = self:_readInt(mask)
    return stored_objects[link_id]
end

function InputPipe:_readInt(mask)
    local bytes = types.maskBytes(mask)
    local str = self:_readRaw(bytes)
    local result = types.deserializeInt(str, mask)
    return result
end

function InputPipe:_readFloat(mask)
    local bytes = types.maskBytes(mask)
    local str = self:_readRaw(bytes)
    local result = types.deserializeFloat(str, mask)
    return result
end

function InputPipe:_readFunction(mask)
    assert(self.remoteFunctions, errors.ERROR_PROTOCOL)
    local funcId = self:_readInt(mask)
    local result = self.remoteFunctions:getFunction(funcId)
    return result
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
            error(errors.ERROR_PIPE)
        end
        done = done + lwp.ByteBlock_getDWORD(self.dwPointer)
    end
    lwp.ByteBlock_setOffset(self.buffer, 0)
    local result = lwp.ByteBlock_getString(self.buffer, len)
    return result
end

return InputPipe
