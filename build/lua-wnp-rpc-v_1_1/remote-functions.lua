local RemoteFunctions = {}

local utils = require("utils")

RemoteFunctions.__index = RemoteFunctions

function RemoteFunctions:_setClass(obj)
    setmetatable(obj, self)
end

function RemoteFunctions:new(makeCall)
    local obj = {}
    self:_setClass(obj)
    obj:_init(makeCall)
    return obj
end

function RemoteFunctions:_init(makeCall)
    self.makeCall = makeCall
    self.id2function = {}
end

function RemoteFunctions:getFunction(funcId)
    local func = self.id2function[funcId]
    if not func then
        func = function(...)
            return self.makeCall(funcId, ...)
        end
        self.id2function[funcId] = func
    end
    return func
end

return RemoteFunctions
