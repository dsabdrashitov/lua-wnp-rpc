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
    write_test()
    execute_test()
end

function write_test()
    local hFile = lwp.CreateFile(
            FILE_FUNCIN,
            lwp.mask(lwp.GENERIC_WRITE),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.CREATE_ALWAYS,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )
    if (hFile == lwp.INVALID_HANDLE_VALUE) then
        print("Error: invalid handle")
        print(tostring(lwp.GetLastError()))
        return
    else
        print("Created.")
    end

    local out = wnprpc.OutputPipe:new(hFile)

    print(assert(out:write(0)))
    print(assert(out:write(3)))
    print(assert(out:write(false)))
    print(assert(out:write(nil)))
    print(assert(out:write("error1")))

    print(assert(out:write(0)))
    print(assert(out:write(3)))
    print(assert(out:write(false)))
    print(assert(out:write("error2")))
    print(assert(out:write(nil)))

    print(assert(out:write(0)))
    print(assert(out:write(2)))
    print(assert(out:write(true)))
    print(assert(out:write("error3")))

    print("Closing.")
    close(hFile)
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

    local ingoing = wnprpc.IngoingCalls:new(wnprpc.InputPipe:new(inFile), wnprpc.OutputPipe:new(outFile), assert)
    print(ingoing:receiveCall())
    print(ingoing:receiveCall())
    print(ingoing:receiveCall())

    print("Closing.")
    close(inFile)
    close(outFile)

    --print_output(assert((function() return true, "world"  end)(), "hello"))
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
