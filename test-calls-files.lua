-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local wnprpc = require("out.production.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

FILE_FUNCIN_ROOT = "tmp\\funcin_root.txt"
FILE_FUNCOUT_ROOT = "tmp\\funcout_root.txt"
FILE_FUNCIN_MAIN = "tmp\\funcin_main.txt"
FILE_FUNCOUT_MAIN = "tmp\\funcout_main.txt"

function main()
    write_root_call()
    execute(FILE_FUNCIN_ROOT, FILE_FUNCOUT_ROOT, 1)
    read_root_replies()
    execute(FILE_FUNCIN_MAIN, FILE_FUNCOUT_MAIN, 3)
    read_main_replies()
end

function write_root_call()
    local outFile = lwp.CreateFile(
            FILE_FUNCIN_ROOT,
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

    out:_sendCall(0)

    print("Closing.")
    close(outFile)
end

function execute(inputName, outputName, count)
    local outFile = lwp.CreateFile(
            outputName,
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
            inputName,
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

    local ingoing = wnprpc.IngoingCalls:new(inFile, outFile, function()
        return {
            ["print"] = print,
            ["assert"] = assert,
        }
    end)
    print("print.id=" .. tostring(ingoing.localFunctions:getId(print)))
    print("assert.id=" .. tostring(ingoing.localFunctions:getId(assert)))

    for _ = 1, count do
        ingoing:receiveCall()
    end

    print("Closing.")
    close(inFile)
    close(outFile)
end

function read_root_replies()
    local inFile = lwp.CreateFile(
            FILE_FUNCOUT_ROOT,
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

    local outFile = lwp.CreateFile(
            FILE_FUNCIN_MAIN,
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

    local out = wnprpc.OutgoingCalls:new(inFile, outFile)
    
    local g = out:_receiveReply()

    out:_sendCall(findId(g["print"], out), "hello", 3333, true, nil, 366.239, {a=1})
    out:_sendCall(findId(g["assert"], out), false, "error1")
    out:_sendCall(findId(g["assert"], out), true, "error2", nil, 42)

    print("Closing.")
    close(inFile)
    close(outFile)
end

function findId(func, out)
    for k, v in pairs(out.remoteFunctions.id2function) do
        if v == func then
            return k
        end
    end
    return nil
end

function read_main_replies()
    local inFile = lwp.CreateFile(
            FILE_FUNCOUT_MAIN,
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

    print_output(pcall(out._receiveReply, out))
    print_output(pcall(out._receiveReply, out))
    print_output(pcall(out._receiveReply, out))

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
