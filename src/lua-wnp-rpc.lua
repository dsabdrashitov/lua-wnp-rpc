lua_wnp_rpc = {}

-- Change path
local prev_path = package.path
local root_path = debug.getinfo(1).source:match("@(.*\\)") or ""
package.path = root_path .. "?.lua"

-- imports and libs
local OutputPipe = require("output-pipe")
local InputPipe = require("input-pipe")
local IngoingCalls = require("ingoing-calls")
local OutgoingCalls = require("outgoing-calls")
local RPCServer = require("rpc-server")
local RPCClient = require("rpc-client")
local errors = require("errors")

-- Restore path
package.path = prev_path

lua_wnp_rpc.OutputPipe = OutputPipe
lua_wnp_rpc.InputPipe = InputPipe
lua_wnp_rpc.IngoingCalls = IngoingCalls
lua_wnp_rpc.OutgoingCalls = OutgoingCalls
lua_wnp_rpc.RPCServer = RPCServer
lua_wnp_rpc.RPCClient = RPCClient
lua_wnp_rpc.ERROR_PIPE = errors.ERROR_PIPE
lua_wnp_rpc.ERROR_PROTOCOL = errors.ERROR_PROTOCOL

return lua_wnp_rpc
