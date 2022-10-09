# lua-wnp-rpc
RPC for Lua over windows named pipes

Goal is to make Lua <-> python RPC over NamedPipe. This library is Lua part. It is 
reference protocol implementation. Python library [dsa-pywnprpc] shall be just a port of this one.

Note that protocol is not thread-safe. Since Lua is in general single-threaded there 
should not be any problems. But if your setup is multi-threaded, it 
is your responsibility to prevent concurrent access to pipe. For example there is a
library [lua-win-critical-section].

Example of using the library is in files `example-server.lua` and `example-client.lua`.
There is also example client in python library [dsa-pywnprpc].

[lua-win-critical-section]:https://github.com/dsabdrashitov/lua-win-critical-section
[dsa-pywnprpc]:https://github.com/dsabdrashitov/pywnprpc
