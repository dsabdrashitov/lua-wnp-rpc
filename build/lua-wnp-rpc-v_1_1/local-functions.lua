local LocalFunctions = {}

LocalFunctions.__index = LocalFunctions

function LocalFunctions:_setClass(obj)
    setmetatable(obj, self)
end

function LocalFunctions:new(rootFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(rootFunction)
    return obj
end

function LocalFunctions:_init(rootFunction)
    self.function2id = {}
    self.id2function = {}
    if rootFunction ~= nil then
        self.function2id[rootFunction] = 0
        self.id2function[0] = rootFunction
    end
    self.registered = 0
end

function LocalFunctions:getFunction(funcId)
    local func = self.id2function[funcId]
    return func
end

function LocalFunctions:getId(func)
    if not self.function2id[func] then
        self.registered = self.registered + 1
        self.function2id[func] = self.registered
        self.id2function[self.registered] = func
    end
    return self.function2id[func]
end

return LocalFunctions
