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
    --obj_print(create_test_table())
    test_write()
    test_read()
end

function create_test_table()
    local obj1 = {
        name = "obj1",
        ["127:"] = 127,
    }
    local obj2 = {
        name = "obj2",
        ["65536:"] = 65536,
    }
    obj1["link"] = obj2
    obj2["link"] = obj1

    local result = {
        ["256.0:"] = 256 * 1.0,
        [true] = false,
        [1] = true,
        link = obj1,
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
    out:write(obj)
    out:write(nil)

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

    local obj = inp:read()
    local obj_expected = create_test_table()
    assert(obj_equals(obj, obj_expected))
    obj = inp:read()
    assert(obj == nil)

    print("Closing.")
    close(hFile)
end

function obj_equals(obj1, obj2, traversed1, traversed2)
    if obj1 == obj2 then
        return true
    end
    if type(obj1) ~= "table" then
        return false
    end
    if type(obj2) ~= "table" then
        return false
    end
    traversed1 = traversed1 or {}
    traversed2 = traversed2 or {}
    if traversed1[obj1] then
        return traversed1[obj1] == traversed2[obj2]
    end
    traversed1[obj1] = obj1
    traversed2[obj2] = obj1
    local compared = {}
    for key1, val1 in pairs(obj1) do
        local val2 = obj2[key1]
        if not obj_equals(val1, val2, traversed1, traversed2) then
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

function obj_print(obj, indent, printed)
    indent = indent or ""
    printed = printed or {}
    if type(obj) == "table" then
        if printed[obj] then
            print(indent .. tostring(obj) .. " <printed>")
            return
        end
        printed[obj] = true
        print(indent .. tostring(obj) .. " {")
        for key, val in pairs(obj) do
            obj_print(key, indent .. "  ", printed)
            print(indent .. "  ||")
            obj_print(val, indent .. "  ", printed)
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
