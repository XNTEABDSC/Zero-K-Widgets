
function widget:GetInfo()
	return {
		name      = "Effective Lobbing v4",
		desc      = "Lobster will lob effectively",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end



VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local CMD_DGUN=CMD.DGUN
local CMD_REMOVE=CMD.REMOVE
local WackyBag=WG.WackyBag
local wbInsertOrderToUnit=WackyBag.utils.InsertOrderToUnit
local spGetGroundHeight=Spring.GetGroundHeight
local spGiveOrderToUnit=Spring.GiveOrderToUnit
local spGetProjectileTeamID=Spring.GetProjectileTeamID
local spGetUnitCommands=Spring.GetUnitCommands

local spGetUnitIsCloaked=Spring.GetUnitIsCloaked
local spGetUnitsInCylinder=Spring.GetUnitsInCylinder
local spAreTeamsAllied=Spring.AreTeamsAllied
local spGetUnitVelocity=Spring.GetUnitVelocity
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

local myTeamId=Spring.GetMyTeamID()
local LobUD=UnitDefNames["amphlaunch"]
local LobUDID=LobUD.id
local lobbing_gather_Range=LobUD.customParams.thrower_gather

function ChooseEffectiveLobs(lobIDs)

	-- Units2BeLobedInfo[UnitId]={alreadyLobbed=, lobs2InRange=}
	local Units2BeLobedInfo={}
	-- Lobs2LobUnitsInfo[lobID]={totalCount=,currentCount=,Units2InRange=}
	local Lobs2LobUnitsInfo={}

	for _, lobID in pairs(lobIDs) do
		local Units2InRange={}
		local totalCount=0
		
		local lobx,loby,lobz=spGetUnitPosition(lobID)

		for _,UnitId in pairs(spGetUnitsInCylinder(lobx,lobz,lobbing_gather_Range,myTeamId)) do
			if UnitId~=lobID then -- lob don't throw it self
				local BeLobedInfo=Units2BeLobedInfo[UnitId] or {alreadyLobbed=false, lobs2InRange={}}
				BeLobedInfo.lobs2InRange[lobID]=true
				Units2BeLobedInfo[UnitId]=BeLobedInfo
	
				Units2InRange[UnitId]=true
				totalCount=totalCount+1
			end

		end

		Lobs2LobUnitsInfo[lobID]={totalCount=totalCount,currentCount=totalCount,Units2InRange=Units2InRange}

	end
	local ChoosedLobs={}
	-- if a lob's throw can make percentage of unit thrown in its range then chance chance to choose it
	local stageInfos={
		{
			percentage=0.8,
			chance=0.5,
		},
		{
			percentage=0.5,
			chance=0.5,
		},
		{
			percentage=0.2,
			chance=0.7,
		},
		{
			percentage=0,
			chance=1,
		}
	}
	for _, stageInfo in pairs(stageInfos) do
		local percent=stageInfo.percentage
		local chance=stageInfo.chance
		for lobID,lobInfo in pairs(Lobs2LobUnitsInfo) do
			if lobInfo.currentCount/lobInfo.totalCount>percent and math.random()<chance then
				ChoosedLobs[#ChoosedLobs+1]=lobID -- choose
				Lobs2LobUnitsInfo[lobID]=nil -- remove it from checking list

				for udid, _ in pairs(lobInfo.Units2InRange) do
					if Units2BeLobedInfo[udid] then
						for anotherlobUD, _ in pairs(Units2BeLobedInfo[udid].lobs2InRange) do
							local anotherLobInfo=Lobs2LobUnitsInfo[anotherlobUD]
							if anotherLobInfo then
								anotherLobInfo.Units2InRange[udid]=nil
								anotherLobInfo.currentCount=anotherLobInfo.currentCount-1
							end
						end
						Units2BeLobedInfo[udid]=nil
					else
						-- impossible
					end
				end
			end
		end
	end
	return ChoosedLobs
end
local spGetSelectedUnits=Spring.GetSelectedUnits
local spGiveOrderToUnit=Spring.GiveOrderToUnit
local spGiveOrderToUnitArray=Spring.GiveOrderToUnitArray
local waitinglobs={}
local function AddLobCMD(lobId,cmd)
	waitinglobs[lobId]=cmd
	--waitinglobs[#waitinglobs+1]=lobId
end
function widget:UnitCommandNotify(uID, cmdID, cmdParams, cmdOpts)
	if cmdID~=CMD_DGUN or spGetUnitDefID(uID)~=LobUDID then
		return nil
	end
	local lobId=uID
	local lobx,loby,lobz=spGetUnitPosition(lobId)
	if lobx then
		local _, loaded=spGetUnitWeaponState(lobId,1)
		local cmdQueue=spGetUnitCommands(lobId,1)
		local dgunCMD=(cmdQueue and cmdQueue[1] and cmdQueue[1].id == CMD_DGUN and cmdQueue[1]) or nil

		local atGround=true--(loby-spGetGroundHeight(lobx,lobz))<1
		if loaded and dgunCMD==nil and atGround then
			AddLobCMD(lobId,{cmdID, cmdParams, cmdOpts})
			return true
		end
	end

end
function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID~=CMD_DGUN then
		return nil
	end
	local selectedUnits=spGetSelectedUnits()
	local selectedLobs={}
	local HasLobs=false
	for key, lobId in pairs(selectedUnits) do
		if spGetUnitDefID(lobId)==LobUDID then
			HasLobs=true
			local lobx,loby,lobz=spGetUnitPosition(lobId)
			if lobx then
				local _, loaded=spGetUnitWeaponState(lobId,1)
				local cmdQueue=spGetUnitCommands(lobId,1)
				local dgunCMD=(cmdQueue and cmdQueue[1] and cmdQueue[1].id == CMD_DGUN and cmdQueue[1]) or nil

				local atGround=true--(loby-spGetGroundHeight(lobx,lobz))<1
				if loaded and dgunCMD==nil and atGround then
					selectedLobs[#selectedLobs+1]=lobId
				end
			end
		end
	end
	if HasLobs then
		for key, value in pairs(selectedLobs) do
			AddLobCMD(value,{cmdID, cmdParams, cmdOptions})
		end
		--local effectiveLobs=ChooseEffectLobs(selectedLobs)
		--spGiveOrderToUnitArray(effectiveLobs,cmdID,cmdParams,cmdOptions)
		return true
	else
		return false
	end
end

function widget:GameFrame()
	local lobIdList={}
	for lobId, value in pairs(waitinglobs) do
		lobIdList[#lobIdList+1]=lobId
	end
	local effectiveLobs=ChooseEffectiveLobs(lobIdList)
	for key, lobId in pairs(effectiveLobs) do
		local cmd=waitinglobs[lobId]
		spGiveOrderToUnit(lobId,cmd[1],cmd[2],cmd[3])
	end
	waitinglobs={}
	--spGiveOrderToUnitArray(effectiveLobs,cmdID,cmdParams,cmdOptions)
end