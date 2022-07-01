-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local wnprpc = require("out.production.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

PIPE_NAME = "wnprpc_test"

local running = true

function main()
    local server = wnprpc.RPCServer:new(PIPE_NAME, rootFunc)

    while running and server:active() do
        server:receiveCall()
    end

    server:close()
end

function rootFunc(password)
    assert(password == "password", "password check failed")
    return {
        ["print"] = print,
        ["assert"] = assert,
        ["stop"] = stop,
    }
end

function stop()
    running = false
end

main()
