-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local wnprpc = require("out.production.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

FILE_FUNCIN = "tmp\\funcin.txt"
FILE_FUNCOUT = "tmp\\funcout.txt"

function main()
    write_calls()
    execute_test()
    read_replies()
end

function write_calls()
    local outFile = lwp.CreateFile(
            FILE_FUNCIN,
            lwp.mask(lwp.GENERIC_WRITE),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.CREATE_ALWAYS,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )
    if (outFile == lwp.INVALID_HANDLE_VALUE) then
        print("Error: invalid handle")
        print(tostring(lwp.GetLastError()))
        return
    else
        print("Created.")
    end

    local out = wnprpc.OutgoingCalls:new(nil, outFile)

    out:_sendCall(0, false, nil, "error1")
    out:_sendCall(0, false, "error2", nil)
    out:_sendCall(0, true, "error3", nil, "something")

    print("Closing.")
    close(outFile)
end

function execute_test()
    local outFile = lwp.CreateFile(
            FILE_FUNCOUT,
            lwp.mask(lwp.GENERIC_WRITE),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.CREATE_ALWAYS,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )
    if (outFile == lwp.INVALID_HANDLE_VALUE) then
        print("Error: invalid handle")
        print(tostring(lwp.GetLastError()))
        return
    else
        print("Created.")
    end

    local inFile = lwp.CreateFile(
            FILE_FUNCIN,
            lwp.mask(lwp.GENERIC_READ),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.OPEN_EXISTING,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )
    if (inFile == lwp.INVALID_HANDLE_VALUE) then
        print("Error: invalid handle")
        print(tostring(lwp.GetLastError()))
        return
    else
        print("Opened.")
    end

    local ingoing = wnprpc.IngoingCalls:new(inFile, outFile, assert)
    ingoing:receiveCall()
    ingoing:receiveCall()
    ingoing:receiveCall()

    print("Closing.")
    close(inFile)
    close(outFile)
end

function read_replies()
    local inFile = lwp.CreateFile(
            FILE_FUNCOUT,
            lwp.mask(lwp.GENERIC_READ),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.OPEN_EXISTING,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )
    if (inFile == lwp.INVALID_HANDLE_VALUE) then
        print("Error: invalid handle")
        print(tostring(lwp.GetLastError()))
        return
    else
        print("Opened.")
    end

    local out = wnprpc.OutgoingCalls:new(inFile, nil)

    print_output(pcall(function() return out:_receiveReply() end))
    print_output(pcall(function() return out:_receiveReply() end))
    print_output(pcall(function() return out:_receiveReply() end))

    print("Closing.")
    close(inFile)
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
end

main()
