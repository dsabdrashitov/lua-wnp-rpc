local OutputPipe = {}

local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local types = require("types")
local errors = require("errors")
local utils = require("utils")

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
    self.localFunctions = nil
end

function OutputPipe:setLocalFunctions(localFunctions)
    self.localFunctions = localFunctions
end

function OutputPipe:write(obj)
    self:_write(obj, {count = 0})
end

local type_switch

function OutputPipe:_write(obj, stored_objects)
    type_switch = type_switch or {
        ["string"] = OutputPipe._writeString,
        ["boolean"] = OutputPipe._writeBoolean,
        ["nil"] = OutputPipe._writeNil,
        ["number"] = OutputPipe._writeNumber,
        ["table"] = OutputPipe._writeTable,
        ["function"] = OutputPipe._writeFunction,
    }
    local write_method = type_switch[type(obj)]
    assert(write_method, string.format("error: unsupported type (%s)", type(obj)))
    write_method(self, obj, stored_objects)
end

function OutputPipe:_writeString(str)
    local len = string.len(str)
    local objMask = types.intMask(len)
    local objType = types.composeType(types.CLASS_STRING, objMask)
    local header = string.char(objType) .. types.serializeInt(len, objMask)

    self:_writeRaw(header)
    self:_writeRaw(str)
end

function OutputPipe:_writeBoolean(val)
    local objMask
    if val then
        objMask = types.MASK_BOOL_TRUE
    else
        objMask = types.MASK_BOOL_FALSE
    end
    local objType = types.composeType(types.CLASS_BOOLEAN, objMask)
    local header = string.char(objType)

    self:_writeRaw(header)
end

function OutputPipe:_writeNil()
    local objType = types.composeType(types.CLASS_VOID, types.MASK_VOID)
    local header = string.char(objType)

    self:_writeRaw(header)
end

function OutputPipe:_writeNumber(number)
    if math.type(number) == "integer" then
        self:_writeInt(number)
    else
        self:_writeDouble(number)
    end
end

function OutputPipe:_writeTable(table, stored_objects)
    if stored_objects[table] then
        self:_writeLink(table, stored_objects)
        return
    end
    stored_objects[table] = stored_objects.count
    stored_objects.count = stored_objects.count + 1

    local size = utils.tableSize(table)
    local objMask = types.intMask(size)
    local objType = types.composeType(types.CLASS_TABLE, objMask)
    local header = string.char(objType) .. types.serializeInt(size, objMask)

    self:_writeRaw(header)
    local done = 0
    for k, v in pairs(table) do
        self:_write(k, stored_objects)
        self:_write(v, stored_objects)
        done = done + 1
    end
    assert(done == size, "table size changed")
end

function OutputPipe:_writeLink(table, stored_objects)
    local link_id = stored_objects[table]
    local objMask = types.intMask(link_id)
    local objType = types.composeType(types.CLASS_LINK, objMask)
    local header = string.char(objType) .. types.serializeInt(link_id, objMask)

    self:_writeRaw(header)
end

function OutputPipe:_writeInt(number)
    local objMask = types.intMask(number)
    local objType = types.composeType(types.CLASS_INT, objMask)
    local header = string.char(objType) .. types.serializeInt(number, objMask)

    self:_writeRaw(header)
end

function OutputPipe:_writeDouble(number)
    local objType = types.composeType(types.CLASS_FLOAT, types.MASK_FLOAT64)
    local header = string.char(objType) .. types.serializeFloat(number, types.MASK_FLOAT64)

    self:_writeRaw(header)
end

function OutputPipe:_writeFunction(func)
    assert(self.localFunctions, "can't send function without ingoing calls endpoint")
    local funcId = self.localFunctions:getId(func)
    local objMask = types.intMask(funcId)
    local objType = types.composeType(types.CLASS_FUNCTION, objMask)
    local header = string.char(objType) .. types.serializeInt(funcId, objMask)

    self:_writeRaw(header)
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
            error(errors.ERROR_PIPE)
        end
        done = done + lwp.ByteBlock_getDWORD(self.dwPointer)
    end
end

return OutputPipe
