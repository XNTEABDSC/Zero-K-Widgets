if not (Spring.GetConfigInt("LuaSocketEnabled", 0) == 1) then
	Spring.Echo("LuaSocketEnabled is disabled")
	return false
end

local socket = socket


local connections={}

local connections_data={}

local function AddConnection(sock)
    connections[sock]=sock
	connections_data[sock]={
		input_cache="",
		send_tasks={}
	}
end



local send_tasks={
	send_all_unitdefs=function ()

		return{
			event_type="send_all_unitdefs",

		}
	end
}
local function RemoveConnection(sock)
    connections[sock]=nil
end

local server

local using_host = "localhost"
local using_port = 21234

function widget:GetInfo()
return {
	name    = "net control handler",
	desc    = "listen " .. using_host .. ":" .. using_port .. " to share data and control",
	author  = "XNTEABDSC",
	date    = "2025",
	license = "GNU GPL, v2 or later",
	layer   = 0,
	enabled = false,
}
end


local function SocketListen(host, port)
	server = socket.bind(host, port)
	if server==nil then
		Spring.Echo("Error binding to " .. host .. ":" .. port)
		return nil
	end
	server:settimeout(0)
    AddConnection(server)
	return server
end


function widget:Initialize()
	SocketListen(using_host,using_port)
end

local function ConnectClient(server)
	local client, err = server:accept()
	if client == nil  then
		Spring.Echo("Accept failed: " .. err)
        return
	end
	client:settimeout(0)
	AddConnection(client)
	local ip, port = server:getsockname()
	Spring.Echo("Accepted connection from " .. ip ..":" .. port)
end

local function CloseClient(sock)
    Spring.Echo("closed connection")
    sock:close()
    RemoveConnection(sock)
end

local function WriteSocket(sock)
    --sock:send(data)
end

local function ReceiveSocket(sock,data)

    --[=[
    local s, status, partial = input:receive('*a') --try to read all data
    if status == "timeout" or status == nil then
        SocketDataReceived(input, s or partial)
    elseif status == "closed" then
        SocketClosed(input)
        input:close()
        set:remove(input)
    end
    ]=]
end
local spGiveOrderToUnit=Spring.GiveOrderToUnit;

function widget:Update()
    local readable, writeable, err = socket.select(connections, connections, 0)
	if err~=nil then
		-- some error happened in select
		if err=="timeout" then
			-- nothing to do, return
			return
		end
		Spring.Echo("Error in select: " .. error)
	end

	for _, input in ipairs(readable) do
		local data=connections_data[input]
		if input==server then -- server socket got readable (client connected)
			ConnectClient(input)
		else
			local s, status, partial = input:receive('*a') --try to read all data
			if status == "closed" then
				CloseClient(input)
			else
				data.input_cache=data.input_cache .. (s or partial)
			end

			if status == nil then
				ReceiveSocket(input, data.input_cache)
				data.input_cache=""
			end
		end
	end
	for _, output in ipairs(writeable) do
		WriteSocket(output)
	end
end