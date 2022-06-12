lua_wnp_rpc = {}

-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local lwp = require("lib.lua-win-pipe-v_1_1.lua-win-pipe")
local OutputPipe = require("output-pipe")
local InputPipe = require("input-pipe")
local IngoingCalls = require("ingoing-calls")

-- Restore path
package.path = prev_path

lua_wnp_rpc.OutputPipe = OutputPipe
lua_wnp_rpc.InputPipe = InputPipe
lua_wnp_rpc.IngoingCalls = IngoingCalls

return lua_wnp_rpc
