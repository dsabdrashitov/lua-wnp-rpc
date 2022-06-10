local types = {}

types.MASK_BITS = 2
types.MASK_MAX = (1 << types.MASK_BITS) - 1 -- equals 3
types.CLASS_BITS = 6
types.CLASS_MAX = (1 << types.CLASS_BITS) - 1 -- equals 63

types.MASK_INT8 = 0
types.MASK_INT16 = 1
types.MASK_INT32 = 2
types.MASK_INT64 = 3
types.MASK_FLOAT32 = types.MASK_INT32
types.MASK_FLOAT64 = types.MASK_INT64
types.MASK_BOOL_FALSE = 0
types.MASK_BOOL_TRUE = 1
types.MASK_VOID = 0

types.CLASS_VOID = 0
types.CLASS_BOOLEAN = 1
types.CLASS_INT = 2
types.CLASS_FLOAT = 3
types.CLASS_STRING = 4
types.CLASS_TABLE = 5
types.CLASS_LINK = 6 -- class for already sent objects

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

function types.maskBytes(mask)
    return 1 << mask
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
    local bytes = types.maskBytes(mask)
    return string.pack("<i" .. bytes .. "", value)
end

function types.serializeFloat(value, mask)
    mask = mask or types.MASK_FLOAT64

    if mask == types.MASK_FLOAT64 then
        return string.pack("<d", value)
    elseif mask == types.MASK_FLOAT32 then
        return string.pack("<f", value)
    else
        error("invalid mask")
    end
end

-- little-endian
-- i don't use string.unpack here to check that my understanding of little-endian is consistent with string.pack
function types.deserializeInt(str, mask)
    local bytes = types.maskBytes(mask)
    local result = 0
    for i = 1, bytes do
        result = result | (string.byte(str, i) << ((i - 1) * 8))
    end
    return result
end

function types.deserializeFloat(str, mask)
    if mask == types.MASK_FLOAT64 then
        return string.unpack("<d", str)
    elseif mask == types.MASK_FLOAT32 then
        return string.unpack("<f", str)
    else
        return nil
    end
end

return types
