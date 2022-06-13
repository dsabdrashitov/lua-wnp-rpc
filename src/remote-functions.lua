local RemoteFunctions = {}

local lwcs = require("lib.lua-win-critical-section-v_1_0.lua-win-critical-section")

RemoteFunctions.__index = RemoteFunctions

function RemoteFunctions:_setClass(obj)
    setmetatable(obj, self)
end

function RemoteFunctions:new(outgoingCalls)
    local obj = {}
    self:_setClass(obj)
    obj:_init(outgoingCalls)
    return obj
end

function RemoteFunctions:_init(outgoingCalls)
    self.outgoingCalls = outgoingCalls
    self.id2function = {}
end

function RemoteFunctions:getFunction(funcId)
    --TODO: synchronization
    local func = self.id2function[funcId]
    if not func then
        func = function(...)
            return self.outgoingCalls:_call(funcId, ...)
        end
        self.id2function[funcId] = func
    end
    return func
end

return RemoteFunctions
