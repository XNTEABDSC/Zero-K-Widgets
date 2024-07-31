
function widget:GetInfo()
	return {
		name      = "LOBBINGLOB v2",
		desc      = "lobster automatically dodge likho shot",
		author    = "XNT",
		date      = "date",
		license   = "HOW",
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

local LikhoUDId=UnitDefNames["bomberheavy"].id
local LikhoWDId=UnitDefNames["bomberheavy"].weapons[1].weaponDef
local LikhoRange=WeaponDefs[UnitDefNames["bomberheavy"].weapons[1].weaponDef].range
local LikhoSpeed=UnitDefNames["bomberheavy"].speed / Game.gameSpeed
--Spring.Echo("LikhoValues: range: ".. LikhoRange .. ", speed: " .. LikhoSpeed)


local wbGetProjectiles=WackyBag.utils.get_proj.GetProjList
local spGetProjectileDefID=Spring.GetProjectileDefID
local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetUnitPosition=Spring.GetUnitPosition
local spGetUnitWeaponState=Spring.GetUnitWeaponState
local spGetPlayerInfo=Spring.GetPlayerInfo
local spGetUnitDefID=Spring.GetUnitDefID
local spValidUnitID=Spring.ValidUnitID
local spIsUnitAllied=Spring.IsUnitAllied


local function CheckAndRegisterLob(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId then
		WatchLobs:add({id=unitID,lastCalled=-1000})
		WatchLobsUSID:add(unitID)
		
		local x,y,z=Spring.GetUnitPosition(unitID)
		--Spring.MarkerAddPoint(x,y,z,"Lob Register")
		
	end
end

local function RemoveLob(unitID)
	local innerId= WatchLobsUSID:removeByUId(unitID)
	WatchLobs:remove(innerId)
end
local function RemoveLikho(unitID)
	local innerId= WatchLikhosUSID:removeByUId(unitID)
	WatchLikhos:remove(innerId)
end

local function CheckAndRegisterLikho(unitID,unitDefID,unitTeam)
	if unitDefID==LikhoUDId and not spIsUnitAllied(unitID) and not WatchLikhosUSID.UIdToSIdList[unitID] then
		WatchLikhos:add({id=unitID})
		WatchLikhosUSID:add(unitID)

		local x,y,z=Spring.GetUnitPosition(unitID)
		--Spring.MarkerAddPoint(x,y,z,"Likho Register")
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
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
		if unitDefID==LikhoUDId and not spAreTeamsAllied(myTeamId,unitTeam) and WatchLikhosUSID.UIdToSIdList[unitID] then
			RemoveLikho(unitID)
			local x,y,z=Spring.GetUnitPosition(unitID)
			--Spring.MarkerAddPoint(x,y,z,"Likho Remove")
		end
	end
end


function widget:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
	if unitTeam==myTeamId and unitDefID==lobsterUDId and WatchLobsUSID.UIdToSIdList[unitID]then
		RemoveLob(unitID)
		local x,y,z=Spring.GetUnitPosition(unitID)
		--Spring.MarkerAddPoint(x,y,z,"Lob Remove")
	elseif unitDefID==LikhoUDId and not spAreTeamsAllied(myTeamId,unitTeam) and WatchLikhosUSID.UIdToSIdList[unitID] then
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
end
local JumpDistance=550
local EscapeSpeed=45/Game.gameSpeed
local extraDelay=6

local wbInsertOrderToUnit=WackyBag.utils.InsertOrderToUnit
local spGetGroundHeight=Spring.GetGroundHeight
local spGiveOrderToUnit=Spring.GiveOrderToUnit
local spGetProjectileTeamID=Spring.GetProjectileTeamID
local spGetUnitCommands=Spring.GetUnitCommands

--local name,active,spec,teamID,allyTeamID,pingTime,cpuUsage, country, rank = Spring_GetPlayerInfo(p, false)
function widget:GameFrame(n)
	local projs={}

	local _,_,_,_,_,pingTime=spGetPlayerInfo(myPlayerId, false)

	local delayFrame=math.ceil(pingTime*Game.gameSpeed/2)
	--Spring.Echo("ping: " .. tostring( pingTime))

	if pingTime>1 then
		return
	end


	for i = 1, WatchLikhos.count do
		if not spGetUnitVelocity(WatchLikhos[i].id) then
			WatchLikhos:remove(i)
			WatchLikhosUSID:removeBySId(i)
			--Spring.Echo("Likho remove")
		end
	end

	for i = 1, WatchLobs.count do
		if not spValidUnitID(WatchLobs[i].id) then
			WatchLobs:remove(i)
			WatchLobsUSID:removeBySId(i)
			--Spring.Echo("Lob remove")
		end
	end


	for LobInfo, id in WatchLobs:enum() do
		local lobx,loby,lobz=spGetUnitPosition(LobInfo.id)
		if lobx then
			local _, loaded=spGetUnitWeaponState(LobInfo.id,1)
			local cmdQueue=spGetUnitCommands(LobInfo.id,1)
			
			local atGround=(loby-spGetGroundHeight(lobx,lobz))<1

			local dgunCMD=(cmdQueue and cmdQueue[1] and cmdQueue[1].id == CMD_DGUN and cmdQueue[1]) or nil
			if (n-LobInfo.lastCalled)>Game.gameSpeed and loaded and atGround and dgunCMD==nil then

				for likhoInfo, _ in WatchLikhos:enum() do
					local likhox,likhoy,likhoz=spGetUnitPosition(likhoInfo.id)

					EZDrawer.Add(EZDrawer.DrawerTemplates.DrawOnce(
						function ()
							EZDrawer.DrawerTemplates.DrawLine(lobx,loby,lobz,likhox,likhoy,likhoz,{1,0,0,1},4)
						end
					))

					local likhovx,likhovy,likhovz=spGetUnitVelocity(likhoInfo.id)
					local offsetx,offsetz=lobx-likhox,lobz-likhoz
					local distance=sqrt(offsetx*offsetx+offsetz*offsetz)
					local offsetNormX,offsetNormZ=offsetx/distance,offsetz/distance

					local LikhoSpeedOnOffset=offsetNormX*likhovx+offsetNormZ*likhovz

					if distance+(-LikhoSpeedOnOffset+EscapeSpeed)*(delayFrame-extraDelay) < LikhoRange then
						--spGiveOrderToUnit(unitId.id,CMD_DGUN,{jumpX+unitx,jumpY,jumpZ+unitz},0)
						
						local jumpX,jumpZ=offsetNormX*JumpDistance,offsetNormZ*JumpDistance
						local jumpY=spGetGroundHeight(jumpX,jumpZ)

						wbInsertOrderToUnit(LobInfo.id,true,0,CMD_DGUN,{jumpX+lobx,jumpY,jumpZ+lobz},0)
						LobInfo.lastCalled=n
					end
				end
			end
			
			if (n-LobInfo.lastCalled)<Game.gameSpeed*3 and (not atGround or not loaded) and dgunCMD~=nil then
				spGiveOrderToUnit(LobInfo.id,CMD_REMOVE,{dgunCMD.tag},0)
				--unitInfo.lastCalled=-1000
			end
		end
		
	end
end