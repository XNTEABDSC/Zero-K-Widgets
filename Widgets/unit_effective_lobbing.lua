
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
local lobbing_gather_Range=UnitDefNames["amphlaunch"].customParams.thrower_gather

function ChooseEffectLobs(lobIDs)

	local Units2BeLobedInfo={}
	local Lobs2LobUnitsInfo={}

	for _, lobID in pairs(lobIDs) do
		local Units2InRange={}
		local totalCount=0
		
		local lobx,loby,lobz=spGetUnitPosition(lobID)

		for _,UnitId in pairs(spGetUnitsInCylinder(lobx,lobz,lobbing_gather_Range,myTeamId)) do

			local BeLobedInfo=Units2BeLobedInfo[UnitId] or {alreadyLobbed=false, lobs2InRange={}}
			BeLobedInfo.lobs2InRange[lobID]=true
			Units2BeLobedInfo[UnitId]=BeLobedInfo

			Units2InRange[UnitId]=true
			totalCount=totalCount+1

		end

		Lobs2LobUnitsInfo[lobID]={totalCount=totalCount,currentCount=totalCount,Units2InRange=Units2InRange}

	end
	local ChoosedLobs={}
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
			percentage=0.2,
			chance=1,
		}
	}
	local function ChooseLob(lobID)

		ChoosedLobs[#ChoosedLobs+1]=lobID

		local LobUnitsInfo=Lobs2LobUnitsInfo[lobID]
		Lobs2LobUnitsInfo[lobID]=nil

		for udid, _ in pairs(LobUnitsInfo[lobID].Units2InRange) do
			if Units2BeLobedInfo[udid] then
				for anotherlobUD, _ in pairs(Units2BeLobedInfo[udid].lobs2InRange) do
					local dwa=Lobs2LobUnitsInfo[anotherlobUD]
					if dwa then
						dwa.Units2InRange[udid]=nil
						dwa.currentCount=dwa.currentCount-1
					end
				end
				Units2BeLobedInfo[udid]=nil
			else
				-- impossible
			end
		end
	end
	for _, stageInfo in pairs(stageInfos) do
		local percent=stageInfo.percentage
		local chance=stageInfo.chance
		for lobUD,lobInfo in pairs(Lobs2LobUnitsInfo) do
			if lobInfo.currentCount/lobInfo.totalCount>percent and math.random()<chance then
				ChooseLob(lobUD)
			end
		end
	end
	return ChoosedLobs
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	
end