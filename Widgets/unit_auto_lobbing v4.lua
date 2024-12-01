
function widget:GetInfo()
	return {
		name      = "Auto Lobbing v4",
		desc      = "Lobster automatically dodge likho shot",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end



VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag

VFS.Include("LuaUI/Libs/EZDrawer.lua")
local EZDrawer=WG.EZDrawer


local sqrt=math.sqrt

local myPlayerId;
local myTeamId;
local myAllyTeamId;
local spAreTeamsAllied=Spring.AreTeamsAllied
local spGetUnitVelocity=Spring.GetUnitVelocity

local CMD_DGUN=CMD.DGUN
local CMD_REMOVE=CMD.REMOVE

local lobsterUDId=UnitDefNames["amphlaunch"].id


VFS.Include("LuaUI/Libs/UnitsBag.lua")
local UnitBag=WG.UnitBag


local wbGetProjectiles=WackyBag.utils.get_proj.GetProjList
local spGetProjectileDefID=Spring.GetProjectileDefID
local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetUnitPosition=Spring.GetUnitPosition
local spGetUnitWeaponState=Spring.GetUnitWeaponState
local spGetPlayerInfo=Spring.GetPlayerInfo
local spGetUnitDefID=Spring.GetUnitDefID
local spValidUnitID=Spring.ValidUnitID
local spIsUnitAllied=Spring.IsUnitAllied
local spGetUnitTeam=Spring.GetUnitTeam

local WBUCheckUnit=WackyBag.utils.CheckUnit
local function CheckLobAvaliable(unitId,prev)
	if not prev then
		if WBUCheckUnit(unitId,lobsterUDId,true,true) then
			local x,y,z=Spring.GetUnitPosition(unitId)
			Spring.MarkerAddPoint(x,y,z,"Lob Register")
			return {id=unitId,lastCalled=-1000}
		end
	else
		if not spValidUnitID(unitId) then
			return nil
		end
	end
	return prev
end

local WatchLobsUB=UnitBag.new({
	CheckAndGenUnitInfo=CheckLobAvaliable,
	UpdateSource={UnitFinished=true,UnitGiven=true},
})

local LikhoUD=UnitDefNames["bomberheavy"]
local LikhoUDId=LikhoUD.id
local LikhoWDId=LikhoUD.weapons[1].weaponDef
local LikhoRange=WeaponDefs[LikhoUD.weapons[1].weaponDef].range
local LikhoSpeed=LikhoUD.speed / Game.gameSpeed
local spGetUnitIsDead=Spring.GetUnitIsDead
local function CheckLikhoAvaliable(unitId,prev)
	local x,y,z=spGetUnitPosition(unitId)
	local vx,vy,vz=spGetUnitVelocity(unitId)
	if WBUCheckUnit(unitId,LikhoUDId,nil,false) and x and vx and (spGetUnitIsDead(unitId)==false)then
		if not prev then
			Spring.MarkerAddPoint(x,y,z,"Likho Register")
		end
		return {id=unitId,x=x,y=y,z=z,vx=vx,vy=vy,vz=vz}
	else
		return nil
	end
	return prev
end

local WatchLikhosUB=UnitBag.new({
	CheckAndGenUnitInfo=CheckLikhoAvaliable,
	UpdateSource={UnitEnteredLos=true,UnitFinished=true}
})

--local WatchLikhos={}
--local UnitIdToWatchId={}
--Spring.Echo("LikhoValues: range: ".. LikhoRange .. ", speed: " .. LikhoSpeed)

local lobbing_gather_Range=UnitDefNames["amphlaunch"].customParams.thrower_gather

function widget:Initialize()
	if WackyBag.utils.DisableForSpec(widgetHandler) then
        return
    end

	myTeamId=Spring.GetMyTeamID()
	myPlayerId=Spring.GetMyPlayerID()
	myAllyTeamId=Spring.GetMyAllyTeamID()
	WatchLobsUB.UpdateFromAllUnits()
	WatchLikhosUB.UpdateFromAllUnits()
end
--WatchLobsUB
local JumpDistance=550
local extraDelay=3

local wbInsertOrderToUnit=WackyBag.utils.InsertOrderToUnit
local spGetGroundHeight=Spring.GetGroundHeight
local spGiveOrderToUnit=Spring.GiveOrderToUnit
local spGetProjectileTeamID=Spring.GetProjectileTeamID
local spGetUnitCommands=Spring.GetUnitCommands

local spGetUnitIsCloaked=Spring.GetUnitIsCloaked
local spGetUnitsInCylinder=Spring.GetUnitsInCylinder
--local name,active,spec,teamID,allyTeamID,pingTime,cpuUsage, country, rank = Spring_GetPlayerInfo(p, false)
function widget:GameFrame(time)
	local projs={}

	local _,_,_,_,_,pingTime=spGetPlayerInfo(myPlayerId, false)

	local delayFrame=math.ceil(pingTime*Game.gameSpeed)
	--Spring.Echo("ping: " .. tostring( pingTime))

	if pingTime>1 then
		return
	end

	WatchLobsUB.UpdateAll()
	WatchLikhosUB.UpdateAll()

	for lobId,lobInfo in WatchLobsUB.Enum() do

		---@cast lobInfo { id:UnitId, lastCalled:integer }
		
		local lobx,loby,lobz=spGetUnitPosition(lobInfo.id)
		if lobx then
			local _, loaded=spGetUnitWeaponState(lobInfo.id,1)
			local cmdQueue=spGetUnitCommands(lobInfo.id,1)

			local atGround=(loby-spGetGroundHeight(lobx,lobz))<1


			local cloakedCheck=spGetUnitIsCloaked(lobInfo.id)

			if cloakedCheck then
				for _,CircleUnitId in pairs(spGetUnitsInCylinder(lobx,lobz,lobbing_gather_Range,myTeamId)) do
					--Spring.Echo(type(CircleUnitId) .. " : " .. tostring(CircleUnitId))
					if not spGetUnitIsCloaked(CircleUnitId) then
						cloakedCheck=false
						break
					end
				end
			end

			local dgunCMD=(cmdQueue and cmdQueue[1] and cmdQueue[1].id == CMD_DGUN and cmdQueue[1]) or nil
			if (time-lobInfo.lastCalled)>Game.gameSpeed and not cloakedCheck and loaded and atGround and dgunCMD==nil then

				local lobvx,lobvy,lobvz=spGetUnitVelocity(lobInfo.id)

				for likhoId,likhoInfo in WatchLikhosUB.Enum() do
					-- ---@cast likhoInfo {id:UnitId,x:WldxPos,y:WldyPos,z:WldzPos}
					local likhox,likhoy,likhoz=likhoInfo.x,likhoInfo.y,likhoInfo.z--spGetUnitPosition(likhoInfo.id)
					
					EZDrawer.Add(EZDrawer.DrawerTemplates.DrawOnce(
						function ()
							EZDrawer.DrawerTemplates.DrawLine(lobx,loby,lobz,likhox,likhoy,likhoz,{1,0,0,1},4)
						end
					))

					local likhovx,likhovy,likhovz=likhoInfo.vx,likhoInfo.vy,likhoInfo.vz--spGetUnitVelocity(likhoInfo.id)
					local offset_likho_to_lob_x,offset_likho_to_lob_z=lobx-likhox,lobz-likhoz
					local distance=sqrt(offset_likho_to_lob_x*offset_likho_to_lob_x+offset_likho_to_lob_z*offset_likho_to_lob_z)
					local offsetNormX,offsetNormZ=offset_likho_to_lob_x/distance,offset_likho_to_lob_z/distance

					local LikhoSpeedOnOffset=offsetNormX*likhovx+offsetNormZ*likhovz
					local LobSpeedOnOffset=offsetNormX*lobvx+offsetNormZ*lobvz


					if distance+(-LikhoSpeedOnOffset+LobSpeedOnOffset)*(delayFrame-extraDelay) < LikhoRange--[==[+lobbingRange/2]==] then
						--spGiveOrderToUnit(unitId.id,CMD_DGUN,{jumpX+unitx,jumpY,jumpZ+unitz},0)

						local jumpX,jumpZ=offsetNormX*JumpDistance,offsetNormZ*JumpDistance
						local jumpY=spGetGroundHeight(jumpX,jumpZ)

						wbInsertOrderToUnit(lobInfo.id,true,0,CMD_DGUN,{jumpX+lobx,jumpY,jumpZ+lobz},0)
						lobInfo.lastCalled=time
					end
					
				end
			end

			if (time-lobInfo.lastCalled)<Game.gameSpeed*3 and (not atGround or not loaded) and dgunCMD~=nil then
				spGiveOrderToUnit(lobInfo.id,CMD_REMOVE,{dgunCMD.tag},0)
				--unitInfo.lastCalled=-1000
			end
		end

	end
end