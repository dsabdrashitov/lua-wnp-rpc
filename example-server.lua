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
    local running = true

    local func_stop = function()
        print("Called stop.")
        running = false
    end
    local func_error = function(err)
        print("Called error:", err)
        error(err)
    end
    local func_print = function(...)
        print("Called print.")
        return print(...)
    end

    local root_func = function(pwd)
        if pwd ~= "password" then
            error("wrong password")
        end
        return {
            ["stop"] = func_stop,
            ["print"] = func_print,
            ["error"] = func_error,
        }
    end
    local server = wnprpc.RPCServer:new(NAME, root_func)

    while running do
        if not server:processCall() then
            -- it's good idea to place some kind of sleep here instead of print
            print("Empty pipe. Skip loop iteration.")
        end
    end

    print("Closing.")
    server:close()
end

main()
