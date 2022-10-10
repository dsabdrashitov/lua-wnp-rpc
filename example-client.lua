-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local wnprpc = require("build.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

NAME = "wnprpc_test"

function main()
    local client = wnprpc.RPCClient:new(NAME)
    print(client:active())

    local there_was_no_error = pcall(function() client:rootCall("wrong password") end)
    if there_was_no_error then
        error("previous pcall should raise error, but it hasn't happened")
    else
        print("ok, wrong password raised error")
    end

    local func_dict = client:rootCall("password")
    print_table("func_dict", func_dict)

    local func_print = func_dict["print"]
    local func_error = func_dict["error"]
    local func_stop = func_dict["stop"]

    func_print(1, false, nil, 3.66, {["a"] = "b"})

    local call_result = {pcall(function() func_error("this error should return as RemoteError") end)}
    if call_result[1] then
        error("previous pcall should raise error, but it hasn't happened")
    else
        print_table("pcall(error)", call_result)
    end

    func_stop()

    client:close()
    print(client:active())
end

function print_table(name, table)
    print(name .. ":")
    for k, v in pairs(table) do
        print(tostring(k) .. " = " .. tostring(v))
    end
end

main()
