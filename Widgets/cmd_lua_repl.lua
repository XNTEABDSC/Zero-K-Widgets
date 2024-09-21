
--Spring.GetModelPieceList
--Spring.GetModelPieceMap

function widget:GetInfo()
	return {
		name      = "lua repl",
		desc      = "do lua in chat",
		author    = "XNT",
		date      = "date",
		license   = "zzz",
		layer     = 0,
		enabled   = false,
	}
end

function GMLog(str)
	Spring.Echo("game_message: " .. str)
end

local replMark='>'

local myplayer
local myplayerName
local luaStartStr

_G=getfenv()

local replstate={}

local function EchoUnmatched(str)
	Spring.Echo("game_message: ".. "repl unmatched command: " .. str)
end

local function pack(...)
	return {...},select("#",...)
end

local function checktuple(fn,arg1,...)
	if arg1~=nil then
		return fn(arg1,...)
	else
		return nil
	end
end

local function MatchStrAndDo(pattern,myfn)
	return function (str)
		--Spring.Echo("game_message: " .. "trying " .. pattern)
		local function getargs(from,to,...)
			if from==nil then
				return false
			else
				return myfn(...)
			end
		end
		return getargs(string.find(str,pattern))
		--return checktuple(fn,string.match(str,pattern))
	end
end

local function dostring(str)
	local f,err=loadstring(str)
	if not f then
		Spring.Echo("game_message: repl error loadstring: " .. err)
	else
		setfenv(f,_G)
		local result,reslen
		local success,errmsg=pcall(
			function ()
				result,reslen=pack(f())
			end
		)
		if not success then
			Spring.Echo("game_message: repl error do string: " .. errmsg)
			return nil
		else
			return result,reslen
		end
	end
end

local function list2str(list,sperator,start,to)
	sperator=sperator or ", "
	start=start or 1
	to=to or #list
	local res= tostring( list[start] )
	for i = start+1, to do
		res=res .. sperator .. tostring(list[i])
	end
	return res
end

ANS=nil

local function repldotring(opstr)
	if not opstr then
		return false
	end
	local result,reslen=dostring(opstr)
	if reslen and reslen>=1 then
		Spring.Echo("game_message: " .. "result: " .. list2str(result,", ",1,reslen))
	end
	return true
end

local function replevalstr(opstr)
	if not opstr then
		return false
	end
	local result,reslen=dostring("return ".. opstr .. "")
	if result and reslen and reslen>=1 then
		ANS=result[1]
		Spring.Echo("game_message: " .. list2str(result,", ",1,reslen))
	end
	return true
end

ChunkInfo={
	curline=1,
	totalline=0,
	editing=false,
}

local function chunkAdd(str)
	--table.insert(ChunkInfo,ChunkInfo.curline,str)
	for i = ChunkInfo.totalline, ChunkInfo.curline,-1 do
		ChunkInfo[i+1]=ChunkInfo[i]
	end
	ChunkInfo[ChunkInfo.curline]=str
	Spring.Echo("game_message: " .. str)
	ChunkInfo.curline=ChunkInfo.curline+1
	ChunkInfo.totalline=ChunkInfo.totalline+1
	return true;
end

local function chunkDel(linestr)
	local pos
	if linestr then
		pos= tonumber(linestr)
		if not pos then
			Spring.Echo("game_message: " .. "repl chunk bad number " .. linestr)
			return true;
		end
	else
		pos=ChunkInfo.curline
	end
	
	for i = ChunkInfo.curline, ChunkInfo.totalline-1,1 do
		ChunkInfo[i]=ChunkInfo[i+1]
	end

	ChunkInfo.totalline=ChunkInfo.totalline-1
	if ChunkInfo.totalline+1<ChunkInfo.curline then
		ChunkInfo.curline=ChunkInfo.totalline+1
	end
	Spring.Echo("game_message: " .. "repl chunk removed line " .. tostring(pos))
	return true;
end

local function chunkType(linestr)
	if ChunkInfo.totalline==0 then
		Spring.Echo("game_message: " .. "empty")
		return true
	end
	local pos= linestr and tonumber(linestr)
	if pos then
		Spring.Echo("game_message: " .. (ChunkInfo[pos] or ("repl chunk no line " .. linestr)))
	else
		for i = 1, ChunkInfo.totalline do
			Spring.Echo("game_message: " .. ChunkInfo[i])
		end
	end
	return true;
end

local function chunkGoto(linestr)
	local pos= linestr and tonumber(linestr)
	if pos then
		if pos == -1 then
			ChunkInfo.curline=ChunkInfo.totalline+1
			return true
		end
		if pos>ChunkInfo.totalline+1 then
			Spring.Echo("game_message: " .. "repl chunk totalline: " .. ChunkInfo.totalline)
			return true
		end
		ChunkInfo.curline=pos
	else
		Spring.Echo("game_message: " .. "repl chunk bad number " .. linestr)
	end
	return true
end

local function chunkClear()
	for i = 1, ChunkInfo.totalline do
		ChunkInfo[i]=nil
	end
	ChunkInfo.curline=1
	ChunkInfo.totalline=0
	Spring.Echo("game_message: " .. "repl chunk cleared")
	return true
end

local function chunkDo()
	local fullstr=""
	for i = 1, ChunkInfo.totalline do
		fullstr=fullstr .. ChunkInfo[i] .. "\n"
	end
	repldotring(fullstr)
	return true
end

replstate.cmdChain={
	MatchStrAndDo("^%.do (.*)",repldotring),
	MatchStrAndDo("^@(.*)",repldotring),
	MatchStrAndDo("^%.eval (.*)",replevalstr),
	MatchStrAndDo("^>(.*)",replevalstr),

	MatchStrAndDo("^%.cadd (.*)",chunkAdd),
	MatchStrAndDo("^%|>(.*)",chunkAdd),
	MatchStrAndDo("^%.cdel (.*)",chunkDel),
	MatchStrAndDo("^%.cdel",chunkDel),
	MatchStrAndDo("^%|%-(.*)",chunkDel),
	MatchStrAndDo("^%|%-",chunkDel),

	MatchStrAndDo("^%.ctype (.*)",chunkType),
	MatchStrAndDo("^%.ctype",chunkType),

	MatchStrAndDo("^%.cclr",chunkClear),
	MatchStrAndDo("^%.cdo",chunkDo),

	MatchStrAndDo("^%.cgoto (.*)",chunkGoto),
	MatchStrAndDo("^%.cgoto",chunkGoto),
	MatchStrAndDo("^%|%->(.*)",chunkGoto),
	MatchStrAndDo("^%|%->",chunkGoto),

	
	MatchStrAndDo("^%|(.*)",chunkAdd),

	MatchStrAndDo("^(.*)",EchoUnmatched)
}
replstate.OnNotMatched=EchoUnmatched

local function ReplInput(str)
	--local MY_G=getfenv(1)
	--Spring.Echo("game_message: " .. "repl get: " .. str)
	--[=[
	do
		local opstr=string.match(str,".do (.*)")
		if opstr then
			local result,reslen=dostring(opstr)
			if reslen and reslen>=1 then
				Spring.Echo("game_message: " .. "result: " .. list2str(result,", ",1,reslen))
			end
			return true;
		end
		return false;
	end

	do
		local opstr=string.match(str,">(.*)")
		if opstr then
			
		end
		
	end
]=]
	--Spring.Echo("game_message: " .. "repl str: " .. str)
	for key, value in pairs(replstate.cmdChain) do
		if(value(str)) then
			return;
		end
	end
	replstate.OnNotMatched(str)
end

function widget:AddConsoleLine(msg,priority)
	--[=[
	if math.random()<0.25 then
		Spring.Echo("game_message: get:" .. msg)
	end]=]
	local s,e,str=string.find(msg,luaStartStr)
	if s then
		--Spring.Echo("game_message: get it")
		ReplInput(str)
		return false
	end
end

function widget:Initialize()
	myplayer=Spring.GetMyPlayerID()
	myplayerName=Spring.GetPlayerInfo(myplayer)
	luaStartStr="^[<%[]" .. myplayerName .. "[>%]]" .. " Allies: ".. replMark .. "(.*)"
	
	--Spring.Echo(luaStartStr1)
	--Spring.Echo( tostring( string.find("<XNTWSAD> Allies: >131",luaStartStr1)))
	--luaStartLen=1+#myplayerName+1+1+7+1+#replMark
end