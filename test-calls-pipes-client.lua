-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local wnprpc = require("out.production.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

PIPE_NAME = "\\\\.\\pipe\\wnprpc_test"

function main()
    local clientPipe = createClient()
    local outgoing = createOutgoing(clientPipe)

    print(pcall(function() outgoing:rootCall("something", true) end))
    local g = outgoing:rootCall("password")

    print_output(pcall(g["print"], "hello", true, nil, 42, 366.239))
    print_output(pcall(g["assert"], true, "error0", nil, 42, 366.239))
    print_output(pcall(g["assert"], false, nil, "error1"))
    print_output(pcall(g["assert"], false, "error2", nil))
    print_output(pcall(g["stop"]))

    close(clientPipe)
end

function createClient()
    local ret = lwp.WaitNamedPipe(PIPE_NAME, 15000)
    if not ret then
        print("Error: WaitNamedPipe failed (" .. tostring(lwp.GetLastError()) .. ")")
        return
    end

    local hPipe = lwp.CreateFile(
            PIPE_NAME,
            lwp.mask(lwp.GENERIC_READ, lwp.GENERIC_WRITE),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.OPEN_EXISTING,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )

    if (hPipe == lwp.INVALID_HANDLE_VALUE) then
        error("Error: invalid handle (" .. tostring(lwp.GetLastError()) .. ")")
    else
        print("Opened.")
    end

    return hPipe
end

function createOutgoing(pipe)
    local result = wnprpc.OutgoingCalls:new(pipe, pipe)
    return result
end

function print_output(...)
    print("return:")
    for k, v in pairs({...}) do
        print(tostring(k) .. " = " .. tostring(v))
    end
end

function close(handle)
    local ret = lwp.CloseHandle(handle)
    if not ret then
        print("Error: close failed (" .. tostring(lwp.GetLastError()) .. ")")
    end
    print("Closed.")
end

main()
