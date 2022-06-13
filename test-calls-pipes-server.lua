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

local running = true

function main()
    local serverPipe = createServer()
    local ingoing = createIngoing(serverPipe)

    while running do
        ingoing:receiveCall()
    end

    close(serverPipe)
end

function createServer()
    local hPipe = lwp.CreateNamedPipe(
            PIPE_NAME,
            lwp.PIPE_ACCESS_DUPLEX,
            lwp.mask(lwp.PIPE_TYPE_BYTE, lwp.PIPE_READMODE_BYTE, lwp.PIPE_WAIT),
            lwp.PIPE_UNLIMITED_INSTANCES,
            512,
            512,
            1000,
            nil
    )

    if (hPipe == lwp.INVALID_HANDLE_VALUE) then
        error("Error: invalid handle")
    else
        print("Created.")
    end

    local ret = lwp.ConnectNamedPipe(hPipe, nil)
    if (not ret) and (lwp.GetLastError() ~= lwp.ERROR_PIPE_CONNECTED) then
        print("Error: connect failed (" .. tostring(lwp.GetLastError()) .. ")")
        close(hPipe)
        return
    else
        print("Connected.")
    end

    return hPipe
end

function stop()
    running = false
end

function createIngoing(pipe)
    function rootFunc(password)
        assert(password == "password", "password check failed")
        return {
            ["print"] = print,
            ["assert"] = assert,
            ["stop"] = stop,
        }
    end
    local result = wnprpc.IngoingCalls:new(pipe, pipe, rootFunc)
    return result
end

function close(handle)
    local ret = lwp.CloseHandle(handle)
    if not ret then
        print("Error: close failed (" .. tostring(lwp.GetLastError()) .. ")")
    end
    print("Closed.")
end

main()
