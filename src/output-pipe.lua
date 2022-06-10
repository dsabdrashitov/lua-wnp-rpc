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
    return self:_write(obj, {count = 0})
end

function OutputPipe:_write(obj, stored_objects)
    type_switch = type_switch or {
        ["string"] = OutputPipe._writeString,
        ["boolean"] = OutputPipe._writeBoolean,
        ["nil"] = OutputPipe._writeNil,
        ["number"] = OutputPipe._writeNumber,
        ["table"] = OutputPipe._writeTable,
    }
    local write_method = type_switch[type(obj)]
    assert(write_method, string.format("error: unsupported type (%s)", type(obj)))
    return write_method(self, obj, stored_objects)
end

function OutputPipe:_writeString(str)
    local len = string.len(str)
    local intMask = types.intMask(len)
    local objType = types.composeType(types.CLASS_STRING, intMask)
    local header = string.char(objType) .. types.serializeInt(len, intMask)

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

function OutputPipe:_writeNil()
    local header = string.char(types.composeType(types.CLASS_VOID, 0))

    local result = true
    result = result and self:_writeRaw(header)
    return result
end

function OutputPipe:_writeNumber(number)
    if math.type(number) == "integer" then
        return self:_writeInt(number)
    else
        return self:_writeDouble(number)
    end
end

function OutputPipe:_writeTable(table, stored_objects)
    if stored_objects[table] then
        return self:_writeLink(table, stored_objects)
    end
    stored_objects[table] = stored_objects.count
    stored_objects.count = stored_objects.count + 1

    local size = OutputPipe._tableSize(table)
    local intMask = types.intMask(size)
    local objType = types.composeType(types.CLASS_TABLE, intMask)
    local header = string.char(objType) .. types.serializeInt(size, intMask)

    local result = true
    result = result and self:_writeRaw(header)
    local done = 0
    for k, v in pairs(table) do
        result = result and self:_write(k, stored_objects)
        result = result and self:_write(v, stored_objects)
        done = done + 1
    end
    assert(done == size, "table has variable size")
    return result
end

function OutputPipe:_writeLink(table, stored_objects)
    local link_id = stored_objects[table]
    local objMask = types.intMask(link_id)
    local objType = types.composeType(types.CLASS_LINK, objMask)
    local header = string.char(objType) .. types.serializeInt(link_id, objMask)

    local result = true
    result = result and self:_writeRaw(header)
    return result
end

function OutputPipe:_writeInt(number)
    local intMask = types.intMask(number)
    local objType = types.composeType(types.CLASS_INT, intMask)
    local header = string.char(objType) .. types.serializeInt(number, intMask)

    local result = true
    result = result and self:_writeRaw(header)
    return result
end

function OutputPipe:_writeDouble(number)
    local objType = types.composeType(types.CLASS_FLOAT, types.MASK_FLOAT64)
    local header = string.char(objType) .. types.serializeFloat(number, types.MASK_FLOAT64)

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
    lwp.ByteBlock_setOffset(self.buffer, 0)
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

function OutputPipe._tableSize(table)
    local size = 0
    for _ in pairs(table) do
        size = size + 1
    end
    return size
end

return OutputPipe
