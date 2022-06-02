local types = {}

types.MASK_BITS = 2
types.MASK_MAX = (1 << types.MASK_BITS) - 1 -- equals 3
types.CLASS_BITS = 6
types.CLASS_MAX = (1 << types.CLASS_BITS) - 1 -- equals 63

types.MASK_INT8 = 0
types.MASK_INT16 = 1
types.MASK_INT32 = 2
types.MASK_INT64 = 3
types.MASK_BOOL_FALSE = 0
types.MASK_BOOL_TRUE = 1

types.CLASS_VOID = 0
types.CLASS_BOOLEAN = 1
types.CLASS_INT = 2
types.CLASS_FLOAT = 3
types.CLASS_STRING = 4
types.CLASS_TABLE = 5

function types.intMask(value)
    assert(math.type(value) == "integer", "value is not integer")
    if (-128 <= value) and (value <= 127) then
        return types.MASK_INT8
    end
    if (-32768 <= value) and (value <= 32767) then
        return types.MASK_INT16
    end
    if (-2147483648 <= value) and (value <= 2147483647) then
        return types.MASK_INT32
    end
    if (-9223372036854775808 <= value) and (value <= 9223372036854775807) then
        return types.MASK_INT64
    end
    error("value range is too wide")
end

function types.composeType(class, mask)
    assert(math.type(class) == "integer", "class is not integer")
    assert((0 <= class) and (class <= types.CLASS_MAX), "class out of range")
    assert(math.type(mask) == "integer", "mask is not integer")
    assert((0 <= mask) and (mask <= types.MASK_MAX), "unknown mask")
    return (class << types.MASK_BITS) | mask
end

function types.decomposeType(type)
    assert(math.type(type) == "integer", "type is not integer")
    assert(type >= 0, "negative type")
    local class = type >> types.MASK_BITS
    local mask = type & types.MASK_MAX
    return class, mask
end

-- little-endian
function types.serializeInt(value, mask)
    local buf = {}
    for _ = 1, (1 << mask) do
        buf[(#buf) + 1] = string.char(value & 255)
        value = value >> 8
    end
    return table.concat(buf)
end

-- little-endian
function types.deserializeInt(str)
    local result = 0
    for i = 1, string.len(str) do
        result = result | (string.byte(str, i) << ((i - 1) * 8))
    end
    return result
end

return types
