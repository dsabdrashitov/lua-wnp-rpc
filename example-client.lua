-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local wnprpc = require("build.lua-wnp-rpc-v_1_3.lua-wnp-rpc")

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
    local func_echo = func_dict["echo"]

    func_print(1, false, nil, 3.66, {["a"] = "b"})

    local call_result = {pcall(function() func_error("this error should return as RemoteError") end)}
    if call_result[1] then
        error("previous pcall should raise error, but it hasn't happened")
    else
        print_table("pcall(error)", call_result)
    end

    print_table("echo", {func_echo("a", nil, false, {1, 2, 3})})

    func_stop()

    client:close()
    print(client:active())
end

function print_table(name, table)
    print(name .. ":")
    for k, v in pairs(table) do
        print(tostring(k) .. " = " .. tostring(v))
        if type(v) == "table" then
            print_table(tostring(v), v)
        end
    end
    print(name .. " end")
end

main()
