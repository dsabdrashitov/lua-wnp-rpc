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

return utils
