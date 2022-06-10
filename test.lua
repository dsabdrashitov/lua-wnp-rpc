-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local wnprpc = require("out.production.lua-wnp-rpc.lua-wnp-rpc")

-- Restore path
package.path = prev_path

--PIPE_NAME = "\\\\.\\pipe\\lwp_test"
FILE_NAME = "tmp\\file.txt"

function main()
    test_write()
    test_read()
end

function test_write()
    local hFile = lwp.CreateFile(
            FILE_NAME,
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

    local obj = {
        ["127:"] = 127,
        ["256:"] = 256,
        ["256.0:"] = 256 * 1.0,
        [true] = false,
        [1] = true,
        ["obj"] = {["a"] = "a", ["b"] = "b"}
    }
    print(out:write(obj))
    print(out:write(nil))

    print("Closing.")
    close(hFile)
end

function test_read()
    local hFile = lwp.CreateFile(
            FILE_NAME,
            lwp.mask(lwp.GENERIC_READ),
            lwp.FILE_NO_SHARE,
            nil,
            lwp.OPEN_EXISTING,
            lwp.FILE_ATTRIBUTE_DEFAULT,
            nil
    )
    if (hFile == lwp.INVALID_HANDLE_VALUE) then
        print("Error: invalid handle")
        print(tostring(lwp.GetLastError()))
        return
    else
        print("Opened.")
    end

    local inp = wnprpc.InputPipe:new(hFile)

    local ok, obj = inp:read()
    print(ok)
    rprint(obj)
    ok, obj = inp:read()
    print(ok)
    rprint(obj)
    --ok, obj = inp:read()
    --rprint(ok, obj)

    print("Closing.")
    close(hFile)
end

function rprint(obj, indent)
    indent = indent or ""
    if type(obj) == "table" then
        print(indent .. tostring(obj) .. " {")
        for key, val in pairs(obj) do
            rprint(key, indent .. "  ")
            print(indent .. "  ||")
            rprint(val, indent .. "  ")
            print(indent .. "  ,")
        end
        print(indent .. "}")
    elseif type(obj) == "string" then
        print(indent .. "\"" .. obj .. "\"")
    else
        print(indent .. tostring(obj))
    end
end

function close(handle)
    local ret = lwp.CloseHandle(handle)
    if not ret then
        print("Error: close failed (" .. tostring(lwp.GetLastError()) .. ")")
    end
end

main()
