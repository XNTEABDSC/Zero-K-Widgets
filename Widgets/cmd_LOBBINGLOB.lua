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

local myTeamId;

local CMD_DGUN=CMD.DGUN

local lobsterUDId=UnitDefNames["amphlaunch"].id


---@class WatchUnitInfo
---@field id UnitId

---@type unordered_list<WatchUnitInfo>
local WatchUnits=WackyBag.collections.unordered_list.new()
local UnitIdToWatchId={}
local DodgeWDIds={
	[ UnitDefNames["bomberheavy"].weapons[1].weaponDef ]=true,
	[ UnitDefNames["bomberriot"].weapons[1].weaponDef ]=true
}


local wbGetProjectiles=WackyBag.utils.get_proj.GetProjList
local spGetProjectileDefID=Spring.GetProjectileDefID
local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetUnitPosition=Spring.GetUnitPosition
local spGetUnitWeaponState=Spring.GetUnitWeaponState

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitTeam==myTeamId and unitDefID==lobsterUDId then
		local innerId= WatchUnits:add({id=unitID})
		UnitIdToWatchId[unitID]=innerId
		local x,y,z=Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z,"UnitRegister")
	end
end

function widget:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId and UnitIdToWatchId[unitID]then
		local innerIdA=UnitIdToWatchId[unitID]
			local innerIdB=WatchUnits.count
			local UnitIdB=WatchUnits[innerIdB]
			WatchUnits:remove(innerIdA)
			UnitIdToWatchId[UnitIdB]=innerIdA
			
			local x,y,z=Spring.GetUnitPosition(unitID)
			Spring.MarkerAddPoint(x,y,z,"UnitRemove")
	else
	end
end



function widget:Initialize()
	if WackyBag.utils.DisableForSpec() then
        return
    end

	myTeamId=Spring.GetMyTeamID()
end
local dodgeDistance=300
local JumpDistance=550

local wgInsertOrderToUnit=WackyBag.utils.InsertOrderToUnit
local spGetGroundHeight=Spring.GetGroundHeight
local spGiveOrderToUnit=Spring.GiveOrderToUnit
local spGetProjectileTeamID=Spring.GetProjectileTeamID
local spGetUnitCommands=Spring.GetUnitCommands
function widget:GameFrame(n)
	for _, projId in pairs(wbGetProjectiles(n)) do
		local projx,projy,projz=spGetProjectilePosition(projId)
		local WDId=spGetProjectileDefID(projId)
		local projTeam=spGetProjectileTeamID(projId)
		if projTeam~=myTeamId and DodgeWDIds[WDId] then
			for unitInfo, id in WatchUnits:enum() do
				local _, loaded=spGetUnitWeaponState(unitInfo.id,1)
				local cmdQueue=spGetProjectileTeamID(unitInfo.id,1)

				if loaded and (not cmdQueue or not cmdQueue[1] or cmdQueue[1].id ~=CMD_DGUN) then
					local unitx,unity,unitz=spGetUnitPosition(unitInfo.id)
					local offsetx,offsetz=unitx-projx,unitz-projz
					local dist=sqrt(offsetx*offsetx+offsetz*offsetz)

					local tarx,tarz=unitx,unitz
					local offsetNormX,offsetNormZ=offsetx/dist,offsetz/dist
					local jumpX,jumpZ=offsetNormX*JumpDistance,offsetNormZ*JumpDistance
					local jumpY=spGetGroundHeight(jumpX,jumpZ)
					if dist<dodgeDistance then
						--spGiveOrderToUnit(unitId.id,CMD_DGUN,{jumpX+unitx,jumpY,jumpZ+unitz},0)
						wgInsertOrderToUnit(unitInfo.id,true,0,CMD_DGUN,{jumpX+unitx,jumpY,jumpZ+unitz},0)
					end
				end
			end
		end
	end
end