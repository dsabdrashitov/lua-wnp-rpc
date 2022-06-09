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
    print(out:_writeRaw("\nnil:\n"))
    print(out:write(nil))
    print(out:_writeRaw("\n"))
    print(out:write([[some very long text:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ]]))

    print("Closing.")
    close(hFile)
end

function close(handle)
    local ret = lwp.CloseHandle(handle)
    if not ret then
        print("Error: close failed (" .. tostring(lwp.GetLastError()) .. ")")
    end
end

main()
