--[=====[

function widget:GetInfo()
	return {
		name      = "LOBBINGLOB",
		desc      = "lobster automatically dodge likho shot",
		author    = "XNT",
		date      = "date",
		license   = "HOW",
		layer     = 0,
		enabled   = false,
	}
end

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag
local sqrt=math.sqrt

local myPlayerId;
local myTeamId;
local myAllyTeamId;
local spAreTeamsAllied=Spring.AreTeamsAllied
local spGetMyPlayerID=Spring.GetMyPlayerID

local CMD_DGUN=CMD.DGUN
local CMD_REMOVE=CMD.REMOVE

local lobsterUDId=UnitDefNames["amphlaunch"].id
local LikhoUDId=UnitDefNames["bomberheavy"].id


---@class WatchLobInfo
---@field id UnitId
---@field lastCalled number

---@type unordered_list<WatchLobInfo>
local WatchLobs=WackyBag.collections.unordered_list.new()
local WatchLobsUSID=WackyBag.collections.uid_sid_list.new()



---@class WatchLikhosInfo
---@field id UnitId

---@type unordered_list<WatchLikhosInfo>
local WatchLikhos=WackyBag.collections.unordered_list.new()


local WatchLikhosUSID=WackyBag.collections.uid_sid_list.new()

--local UnitIdToWatchId={}
local LikhoWDId=UnitDefNames["bomberheavy"].weapons[1].weaponDef


local wbGetProjectiles=WackyBag.utils.get_proj.GetProjList
local spGetProjectileDefID=Spring.GetProjectileDefID
local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetUnitPosition=Spring.GetUnitPosition
local spGetUnitWeaponState=Spring.GetUnitWeaponState
local spGetPlayerInfo=Spring.GetPlayerInfo

local function CheckAndRegisterLob(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId then
		WatchLobs:add({id=unitID,lastCalled=-1000})
		WatchLobsUSID:add(unitID)
		--[[
		local x,y,z=Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z,"UnitRegister")
		]]
	end
end

local function CheckAndReisterLikho(unitID,unitDefID,unitTeam)
	if unitDefID==LikhoUDId and not spAreTeamsAllied(unitTeam,myTeamId) then
		WatchLikhos:add({id=unitID})
		WatchLikhosUSID:add(unitID)
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	CheckAndRegisterLob(unitID,unitDefID,unitTeam)
end

function widget:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId and WatchLikhosUSID.UIdToSIdList[unitID]then
		local innerId= WatchLobsUSID:removeByUId(unitID)
		WatchLobs:remove(innerId)

		local x,y,z=Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z,"UnitRemove")
	else
	end
end



function widget:Initialize()
	if WackyBag.utils.DisableForSpec(widgetHandler) then
        return
    end

	myTeamId=Spring.GetMyTeamID()
	myPlayerId=spGetMyPlayerID()
end
local dodgeDistance=300
local JumpDistance=550

local wgInsertOrderToUnit=WackyBag.utils.InsertOrderToUnit
local spGetGroundHeight=Spring.GetGroundHeight
local spGiveOrderToUnit=Spring.GiveOrderToUnit
local spGetProjectileTeamID=Spring.GetProjectileTeamID
local spGetUnitCommands=Spring.GetUnitCommands

--local name,active,spec,teamID,allyTeamID,pingTime,cpuUsage, country, rank = Spring_GetPlayerInfo(p, false)
function widget:GameFrame(n)
	local projs={}

	local _,_,_,_,_,pingTime=spGetPlayerInfo(myPlayerId, false)

	if pingTime>1 then
		return
	end

	for _, projId in pairs(wbGetProjectiles(n)) do
		
		local WDId=spGetProjectileDefID(projId)
		local projTeam=spGetProjectileTeamID(projId)
		if not spAreTeamsAllied(projTeam,myTeamId) and DodgeWDIds[WDId] then
			projs[#projs+1] =projId
		end
	end

	for unitInfo, id in WatchLobs:enum() do
		--local flag=
		local _, loaded=spGetUnitWeaponState(unitInfo.id,1)
		local cmdQueue=spGetUnitCommands(unitInfo.id,1)
		local unitx,unity,unitz=spGetUnitPosition(unitInfo.id)
		local atGround=(unity-spGetGroundHeight(unitx,unitz))<1

		local dgunCMD=(cmdQueue and cmdQueue[1] and cmdQueue[1].id == CMD_DGUN and cmdQueue[1]) or nil

		for _, projId in pairs(projs) do
			local projx,projy,projz=spGetProjectilePosition(projId)
			if (n-unitInfo.lastCalled)>Game.gameSpeed and loaded and atGround and dgunCMD==nil then
			
				local offsetx,offsetz=unitx-projx,unitz-projz
				local dist=sqrt(offsetx*offsetx+offsetz*offsetz)

				if dist<dodgeDistance then
					--spGiveOrderToUnit(unitId.id,CMD_DGUN,{jumpX+unitx,jumpY,jumpZ+unitz},0)

					local offsetNormX,offsetNormZ=offsetx/dist,offsetz/dist
					local jumpX,jumpZ=offsetNormX*JumpDistance,offsetNormZ*JumpDistance
					local jumpY=spGetGroundHeight(jumpX,jumpZ)

					wgInsertOrderToUnit(unitInfo.id,true,0,CMD_DGUN,{jumpX+unitx,jumpY,jumpZ+unitz},0)
					unitInfo.lastCalled=n
				end
			end
		end
		
		if (n-unitInfo.lastCalled)<Game.gameSpeed*3 and (not atGround or not loaded) and dgunCMD~=nil then
			spGiveOrderToUnit(unitInfo.id,CMD_REMOVE,{id,dgunCMD.tag},0)
			--unitInfo.lastCalled=-1000
		end
	end
end

]=====]