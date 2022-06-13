local FunctionsMap = {}

local lwcs = require("lib.lua-win-critical-section-v_1_0.lua-win-critical-section")

FunctionsMap.__index = FunctionsMap

function FunctionsMap:_setClass(obj)
    setmetatable(obj, self)
end

function FunctionsMap:new(rootFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(rootFunction)
    return obj
end

function FunctionsMap:_init(rootFunction)
    self.function2id = {[rootFunction] = 0}
    self.id2function = {[0] = rootFunction}
    self.registered = 0
end

function FunctionsMap:getFunction(funcId)
    local func = self.id2function[funcId]
    return func
end

function FunctionsMap:getId(func)
    --TODO: add synchronization to all methods (LUA is single-threaded, but with dirty hacks it can be multi-threaded)
    if not self.function2id[func] then
        self.registered = self.registered + 1
        self.function2id[func] = self.registered
    end
    return self.function2id[func]
end

return FunctionsMap
