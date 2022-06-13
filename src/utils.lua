local utils = {}

function utils.lastIndex(array)
    local max = 0
    for i, _ in pairs(array) do
        assert(type(i) == "number", "array index is not a number")
        if max < i then
            max = i
        end
    end
    return max
end

function utils.tableSize(table)
    local size = 0
    for _ in pairs(table) do
        size = size + 1
    end
    return size
end

return utils
