lua_wnp_rpc = {}

-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local lwp = require("lib.lua-win-pipe.lua-win-pipe")

-- Restore path
package.path = prev_path

print(lwp.FILE_FLAG_FIRST_PIPE_INSTANCE)

return lua_wnp_rpc
