local RemoteFunctions = {}

RemoteFunctions.__index = RemoteFunctions

function RemoteFunctions:_setClass(obj)
    setmetatable(obj, self)
end

function RemoteFunctions:new(functionBuilder)
    local obj = {}
    self:_setClass(obj)
    obj:_init(functionBuilder)
    return obj
end

function RemoteFunctions:_init(functionBuilder)
    self.functionBuilder = functionBuilder
    self.id2function = {}
end

function RemoteFunctions:getFunction(funcId)
    --TODO: synchronization
    local func = self.id2function[funcId]
    if not func then
        func = self.functionBuilder(funcId)
        self.id2function[funcId] = func
    end
    return func
end

return RemoteFunctions
