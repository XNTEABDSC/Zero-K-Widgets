function widget:GetInfo()
	return {
		name    = "Op Impaler",
		desc    = "inf",
		author  = "XNT",
		date    = "dk",
		license = "",
		layer   = 10000,
		enabled = false,
	}
end

local CMD_Target         = 34925

local spGetUnitPosition  = Spring.GetUnitPosition
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetSelectedUnits = Spring.GetSelectedUnits

local TravelHeight       = 800
local RotateRadius       = 750.0 / 2

function widget:Initialize()
	Spring.Echo("game_message: " .. "OpImpaler init")
end

local function SetTarForImpaler(unitID, tx, ty, tz, options)
	local _, _, _, ux, uy, uz = spGetUnitPosition(unitID, true)
	local ox, oy, oz = tx - ux, ty - uy, tz - uz
	local odir = math.atan2(oz, ox)

	local odistv = math.sqrt(ox * ox + oz * oz)
	local odisth = oy

	Spring.Echo("SetTarForImpaler :" .. "odist:" .. odistv .. ",odir:" .. odir)

	if (odistv < 1500) then
		Spring.GiveOrderToUnit(unitID, CMD_Target, { tx, ty, tz, 0 }, options)
		return
	end
	local circlev = RotateRadius
	local circleh = TravelHeight

	local distv_ccl_o = odistv - RotateRadius
	local disth_ccl_o = odisth - TravelHeight
	local Ang_ccl_o = math.atan(distv_ccl_o / disth_ccl_o)

	local dist_ccl_o = math.sqrt(distv_ccl_o * distv_ccl_o + disth_ccl_o * disth_ccl_o)
	local Ang_ccl_tar = math.acos(RotateRadius / dist_ccl_o)

	local distv_tar = RotateRadius + RotateRadius * math.sin(Ang_ccl_tar)
	local disth_tar = TravelHeight + RotateRadius * math.cos(Ang_ccl_tar) * (-1)

	local xtar = distv_tar * math.cos(odir) + ux
	local ztar = distv_tar * math.sin(odir) + uz
	local ytar = disth_tar + uy
	Spring.Echo("game_message: " .. "Find tar:" .. '(' .. xtar .. ',' .. ytar .. ',' .. ztar .. ')')
	Spring.GiveOrderToUnit(unitID, CMD_Target, { xtar, ytar, ztar, -1 }, options)
end

function widget:CommandNotify(cmdID, params, options)
	Spring.Echo("game_message: " .. "OpImpaler - cmdID:" .. cmdID)
	Spring.Echo("game_message: " .. "OpImpaler - #params:" .. #params)
	--Spring.Echo("game_message: " .. "OpImpaler - params:" .. GetListStr(params))
	if (cmdID == CMD_Target) then
		local cx, cy, cz = 0, 0, 0
		if (#params == 4) then
			Spring.Echo("game_message: " ..
			"OpImpaler - params:" .. "(" .. params[1] .. ',' .. params[2] .. ',' .. params[3] .. ',' .. params[4] .. ')')
			cx, cy, cz = params[1], params[2], params[3]
		end
		if (#params == 1) then
			local _, _, _, ux, uy, uz = spGetUnitPosition(params[1], true)
			cx, cy, cz = ux, uy, uz
			Spring.Echo("game_message: " ..
			"OpImpaler - tar:" ..
			"(" .. UnitDefs[spGetUnitDefID(params[1])].name .. ',' .. cx .. ',' .. cy .. ',' .. cz .. ')')
		end

		local selUnits = spGetSelectedUnits()
		local AllImpaler = true
		for i = 1, #selUnits do
			if UnitDefs[spGetUnitDefID(selUnits[i])].name ~= "vehheavyarty" then
				AllImpaler = false
				break
			end
		end

		if AllImpaler ~= true then
			return
		end
		Spring.Echo("game_message: " .. "All Impaler, do sth")
		for i = 1, #selUnits do
			Spring.Echo("game_message: " .. "call")
			Spring.Echo("game_message: " .. "callfor:" .. selUnits[i])
			SetTarForImpaler(selUnits[i], cx, cy, cz, options)
			Spring.Echo("game_message: " .. "called")
		end
		return true
	end
end

local function GetListStr(list)
	local res = "["
	for i = 1, #list do
		res = res .. list[i].tostring() .. ','
	end
	res = res .. "]"
	return res
end

