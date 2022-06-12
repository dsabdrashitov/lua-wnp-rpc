local IngoingCalls = {}

local utils = require("utils")

IngoingCalls.__index = IngoingCalls

function IngoingCalls:_setClass(obj)
    setmetatable(obj, self)
end

function IngoingCalls:new(inputPipe, outputPipe, rootFunction)
    local obj = {}
    self:_setClass(obj)
    obj:_init(inputPipe, outputPipe, rootFunction)
    return obj
end

function IngoingCalls:_init(inputPipe, outputPipe, rootFunction)
    self.inputPipe = inputPipe
    self.outputPipe = outputPipe
    self.brokenPipes = false
    self.function2id = {[rootFunction] = 0}
    self.id2function = {[0] = rootFunction}
    self.registered = 1
end

function IngoingCalls:receiveCall()
    if self.brokenPipes then
        return false
    end
    local ok
    local funcId
    ok, funcId = self.inputPipe:read()
    if not ok then
        self.brokenPipes = true
        return false
    end
    local argsCount
    ok, argsCount = self.inputPipe:read()
    if not ok then
        self.brokenPipes = true
        return false
    end
    local args = {}
    for i = 1, argsCount do
        ok, args[i] = self.inputPipe:read()
        if not ok then
            self.brokenPipes = true
            return false
        end
    end
    local func = self.id2function[funcId]
    if not func then
        return self:_replyError(string.format("no function with id (%s)", tostring(funcId)))
    end
    local result = {pcall(func, table.unpack(args, 1, argsCount))}
    ok = result[1]
    if not ok then
        local err = result[2]
        return self:_replyError(err)
    end
    return self:_replyResult(result)
end

function IngoingCalls:_replyResult(result)
    local retsCount = utils.lastIndex(result) - 1
    local ok
    ok = self.outputPipe:write(retsCount)
    if not ok then
        self.brokenPipes = true
        return false
    end
    for i = 1, retsCount do
        ok = self.outputPipe:write(result[i + 1])
        if not ok then
            self.brokenPipes = true
            return false
        end
    end
    return true
end

function IngoingCalls:_replyError(err)
    local ok
    ok = self.outputPipe:write(-1)
    if not ok then
        self.brokenPipes = true
        return false
    end
    ok = self.outputPipe:write(err)
    if not ok then
        self.brokenPipes = true
        return false
    end
    return true
end

return IngoingCalls
