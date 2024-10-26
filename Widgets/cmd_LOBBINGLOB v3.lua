
function widget:GetInfo()
	return {
		name      = "LOBBINGLOB v3",
		desc      = "lobster automatically dodge likho shot",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end


if not WG.EZDrawer then
	VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
end
local WackyBag=WG.WackyBag

if not WG.EZDrawer then
	VFS.Include("LuaUI/Libs/EZDrawer.lua")
end
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


--[==[
---@class WatchLobInfo
---@field id UnitId
---@field lastCalled number
---@type unordered_list<WatchLobInfo>
local WatchLobs=WackyBag.collections.unordered_list.new()
local WatchLobsUSID=WackyBag.collections.uid_sid_list.new()
]==]
local WatchLobs={}


--[==[
---@class WatchLikhosInfo
---@field id UnitId

---@type unordered_list<WatchLikhosInfo>
local WatchLikhos=WackyBag.collections.unordered_list.new()
local WatchLikhosUSID=WackyBag.collections.uid_sid_list.new()
]==]
local WatchLikhos={}
--local UnitIdToWatchId={}

local LikhoUDId=UnitDefNames["bomberheavy"].id
local LikhoWDId=UnitDefNames["bomberheavy"].weapons[1].weaponDef
local LikhoRange=WeaponDefs[UnitDefNames["bomberheavy"].weapons[1].weaponDef].range
local LikhoSpeed=UnitDefNames["bomberheavy"].speed / Game.gameSpeed
--Spring.Echo("LikhoValues: range: ".. LikhoRange .. ", speed: " .. LikhoSpeed)

local lobbingRange=UnitDefNames["amphlaunch"].customParams.thrower_gather


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


local function CheckAndRegisterLob(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId and not WatchLobs[unitID] then
		WatchLobs[unitID]={id=unitID,lastCalled=-1000}
		--WatchLobs:add({id=unitID,lastCalled=-1000})
		--WatchLobsUSID:add(unitID)
		
		local x,y,z=Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z,"Lob Register")
		
	end
end

local function RemoveLob(unitID)
	WatchLobs[unitID]=nil
	--local innerId= WatchLobsUSID:removeByUId(unitID)
	--WatchLobs:remove(innerId)
end
local function RemoveLikho(unitID)
	WatchLikhos[unitID]=nil
	--local innerId= WatchLikhosUSID:removeByUId(unitID)
	--WatchLikhos:remove(innerId)
end

local function CheckAndRegisterLikho(unitID,unitDefID,unitTeam)
	if unitDefID==LikhoUDId and not spIsUnitAllied(unitID) and not WatchLikhos[unitID] then
		WatchLikhos[unitID]={id=unitID}

		local x,y,z=Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z,"Likho Register")
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	CheckAndRegisterLob(unitID,unitDefID,unitTeam)
	CheckAndRegisterLikho(unitID, unitDefID,unitTeam)
end

function widget:UnitEnteredLos(unitID, unitTeam)
	--Spring.Echo("WAHT A LOB")
	CheckAndRegisterLikho(unitID, spGetUnitDefID(unitID),unitTeam)
end

--[=[]=]
function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	if(allyTeam==myAllyTeamId) then
		if unitDefID==LikhoUDId and not spAreTeamsAllied(myTeamId,unitTeam) and WatchLikhos[unitID] then
			RemoveLikho(unitID)
			local x,y,z=Spring.GetUnitPosition(unitID)
			--Spring.MarkerAddPoint(x,y,z,"Likho Remove")
		end
	end
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId and WatchLobs[unitID]then
		RemoveLob(unitID)
		local x,y,z=Spring.GetUnitPosition(unitID)
		--Spring.MarkerAddPoint(x,y,z,"Lob Remove")
	elseif unitDefID==LikhoUDId and not spAreTeamsAllied(myTeamId,unitTeam) and WatchLikhos[unitID] then
		RemoveLikho(unitID)
		local x,y,z=Spring.GetUnitPosition(unitID)
		--Spring.MarkerAddPoint(x,y,z,"Likho Remove")
	end
end



function widget:Initialize()
	if WackyBag.utils.DisableForSpec(widgetHandler) then
        return
    end

	myTeamId=Spring.GetMyTeamID()
	myPlayerId=Spring.GetMyPlayerID()
	myAllyTeamId=Spring.GetMyAllyTeamID()

	for key, UnitId in pairs(Spring.GetAllUnits()) do
		local UnitDefId=spGetUnitDefID(UnitId)
		local UnitTeam=spGetUnitTeam(UnitId)
		if UnitDefId and UnitTeam and spGetUnitPosition(UnitId) then
			CheckAndRegisterLob(UnitId,UnitDefId,UnitTeam)
			CheckAndRegisterLikho(UnitId,UnitDefId,UnitTeam)
		end
	end
end
local JumpDistance=550
local EscapeSpeed=45/Game.gameSpeed
local extraDelay=8

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

	local delayFrame=math.ceil(pingTime*Game.gameSpeed/2)
	--Spring.Echo("ping: " .. tostring( pingTime))

	if pingTime>1 then
		return
	end


	for likhoId,likhoInfo in pairs(WatchLikhos) do
		if not spGetUnitVelocity(likhoId) then
			RemoveLikho(likhoId)
			--WatchLikhos:remove(i)
			--Spring.Echo("Likho remove")
		end
	end

	for lobId,lobInfo in pairs(WatchLobs) do
		if not spValidUnitID(lobId) then
			RemoveLob(lobId)
			--Spring.Echo("Lob remove")
		end
	end


	for lobId,lobInfo in pairs(WatchLobs) do
		local lobx,loby,lobz=spGetUnitPosition(lobInfo.id)
		if lobx then
			local _, loaded=spGetUnitWeaponState(lobInfo.id,1)
			local cmdQueue=spGetUnitCommands(lobInfo.id,1)

			local atGround=(loby-spGetGroundHeight(lobx,lobz))<1

			
			local cloakedCheck=spGetUnitIsCloaked(lobInfo.id)

			if cloakedCheck then
				for _,CircleUnitId in pairs(spGetUnitsInCylinder(lobx,lobz,lobbingRange,myTeamId)) do
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

				for likhoId,likhoInfo in pairs(WatchLikhos) do
					local likhox,likhoy,likhoz=spGetUnitPosition(likhoInfo.id)

					EZDrawer.Add(EZDrawer.DrawerTemplates.DrawOnce(
						function ()
							EZDrawer.DrawerTemplates.DrawLine(lobx,loby,lobz,likhox,likhoy,likhoz,{1,0,0,1},4)
						end
					))

					local likhovx,likhovy,likhovz=spGetUnitVelocity(likhoInfo.id)
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