
if not (Spring.GetConfigInt("LuaSocketEnabled", 0) == 1) then
	Spring.Echo("LuaSocketEnabled is disabled")
	return false
end

function widget:GetInfo()
return {
	name    = "ip console for spring",
	desc    = "opens a telnet console on localhost:8201",
	author  = "abma",
	date    = "Feb. 2012",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = true,
}
end

--VFS.Include(LUAUI_DIRNAME .. "Widgets/socket/socket.lua")

local socket = socket


local host = "localhost"
local port = 8201


-- initiates a connection to host:port, returns true on success
local function SocketListen(host, port)
	server = socket.bind(host, port)
	if server==nil then
		Spring.Echo("Error binding to " .. host .. ":" .. port)
		return false
	end
	server:settimeout(0)
    AddConnection(server)
	return true
end

function widget:Initialize()
	SocketListen(host, port)
end

local data
-- called when data was received through a connection
local function SocketDataReceived(sock, str)
	Spring.SendCommands(str)
end

local headersent
-- called when data can be written to a socket
local function SocketWriteAble(sock)
	if data~=nil then
		sock:send(data)
		data=nil
	end
end

-- called when a connection is closed
local function SocketClosed(sock)
	Spring.Echo("closed connection")
end

local function ClientConnected(sock)
	local client, err = sock:accept()
	if client == nil  then
		Spring.Echo("Accept failed: " .. err)
	end
	client:settimeout(0)
	set:insert(client)
	ip, port = sock:getsockname()
	Spring.Echo("Accepted connection from " .. ip ..":" .. port)
end

function widget:AddConsoleLine(line)
	if data == nil then
		data = line
	else
		data = data .."\n" .. line
	end
end

function widget:Update()
	if set==nil or #set<=0 then
		return
	end
	-- get sockets ready for read
	local readable, writeable, err = socket.select(set, set, 0)
	if err~=nil then
		-- some error happened in select
		if err=="timeout" then
			-- nothing to do, return
			return
		end
		Spring.Echo("Error in select: " .. error)
	end
	for _, input in ipairs(readable) do
		if input==server then -- server socket got readable (client connected)
			ClientConnected(input)
		else
			local s, status, partial = input:receive('*a') --try to read all data
			if status == "timeout" or status == nil then
				SocketDataReceived(input, s or partial)
			elseif status == "closed" then
				SocketClosed(input)
				input:close()
				set:remove(input)
			end
		end
	end
	for __, output in ipairs(writeable) do
		SocketWriteAble(output)
	end
end