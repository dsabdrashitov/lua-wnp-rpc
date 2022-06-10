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

function create_test_table()
    local result = {
        ["127:"] = 127,
        ["256:"] = 256,
        ["256.0:"] = 256 * 1.0,
        [true] = false,
        [1] = true,
        ["obj"] = {["a"] = "a", ["b"] = "b"}
    }
    return result
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

    local obj = create_test_table()
    print(assert(out:write(obj)))
    print(assert(out:write(nil)))

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
    print(assert(ok))
    local obj_expected = create_test_table()
    assert(obj_equals(obj, obj_expected))
    ok, obj = inp:read()
    print(assert(ok))
    assert(obj == nil)

    print("Closing.")
    close(hFile)
end

function obj_equals(obj1, obj2)
    if obj1 == obj2 then
        return true
    end
    if type(obj1) ~= "table" then
        return false
    end
    if type(obj2) ~= "table" then
        return false
    end
    local compared = {}
    for key1, val1 in pairs(obj1) do
        local val2 = obj2[key1]
        if not obj_equals(val1, val2) then
            return false
        end
        compared[key1] = true
    end
    for key2 in pairs(obj2) do
        if not compared[key2] then
            return false
        end
    end
    return true
end

function obj_print(obj, indent)
    indent = indent or ""
    if type(obj) == "table" then
        print(indent .. tostring(obj) .. " {")
        for key, val in pairs(obj) do
            obj_print(key, indent .. "  ")
            print(indent .. "  ||")
            obj_print(val, indent .. "  ")
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
