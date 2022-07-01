-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local wnprpc = require("out.production.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

PIPE_NAME = "wnprpc_test"

function main()
    local client = wnprpc.RPCClient:new(PIPE_NAME)

    print(pcall(function() client:rootCall("something", true) end))
    local g = client:rootCall("password")

    print_output(pcall(g["print"], "hello", true, nil, 42, 366.239))
    print_output(pcall(g["assert"], true, "error0", nil, 42, 366.239))
    print_output(pcall(g["assert"], false, nil, "error1"))
    print_output(pcall(g["assert"], false, "error2", nil))
    print_output(pcall(g["stop"]))

    client:close()
end

function print_output(...)
    print("return:")
    for k, v in pairs({...}) do
        print(tostring(k) .. " = " .. tostring(v))
    end
end

main()
