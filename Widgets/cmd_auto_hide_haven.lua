function widget:GetInfo()
	return {
		name      = "Auto Hide Haven",
		desc      = "automatically hide retreat zone which is in danger place\n",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = true,
	}
end

--[[
    local left, right = true, false
    local alt, ctrl, meta, shift = Spring.GetModKeyState()
    local index = Spring.GetCmdDescIndex(command)
    Spring.SetActiveCommand(index, 1, left, right, alt, ctrl, meta, shift)

    Spring.SendCommands("say " .. "a: I gave "..selcnt.." units to "..playername..".")


luarules/gadget/cmd_retreat.lua--------------------


    widgetHandler.customCommands 
    Spring.SendLuaRulesMsg('sethaven|' .. x .. '|' .. y .. '|' .. z )
    ->gadget:RecvLuaMsg
    local function WriteHavenToTeamRulesParam(teamID, havenID)
        if havens[teamID] and havenID <= havens[teamID].count then
            local data = havens[teamID].data[havenID]
            Spring.SetTeamRulesParam(teamID, "haven_x" .. havenID, data.x, alliedTrueTable)
            Spring.SetTeamRulesParam(teamID, "haven_z" .. havenID, data.z, alliedTrueTable)
        end
    end

    local function AddHaven(teamID, x, z)
        if not teamID then
            return
        end
        if not havens[teamID] then
            havens[teamID] = {count = 0, data = {}}
        end
        local teamHavens = havens[teamID]
        teamHavens.count = teamHavens.count + 1
        teamHavens.data[teamHavens.count] = {x = x, z = z}
        Spring.SetTeamRulesParam(teamID, "haven_count", havens[teamID].count, alliedTrueTable)
        WriteHavenToTeamRulesParam(teamID, teamHavens.count)
    end


    local function RemoveHaven(teamID, havenID)
        if havens[teamID] and havenID <= havens[teamID].count then
            havens[teamID].data[havenID] = havens[teamID].data[havens[teamID].count]
            havens[teamID].data[havens[teamID].count] = nil
            havens[teamID].count = havens[teamID].count - 1
            Spring.SetTeamRulesParam(teamID, "haven_count", havens[teamID].count, alliedTrueTable)
            WriteHavenToTeamRulesParam(teamID, havenID)
        end
    end

gui_havens.lua-----------

    function GetTeamHavens(teamID)
        local start = havenCount
        local teamHavenCount = Spring.GetTeamRulesParam(teamID, "haven_count")
        if teamHavenCount then
            havenCount = havenCount + teamHavenCount
            if havenCount then
                for i = 1, teamHavenCount do
                    havens[start + i] = {
                        x = Spring.GetTeamRulesParam(teamID, "haven_x" .. i),
                        z = Spring.GetTeamRulesParam(teamID, "haven_z" .. i)
                    }
                    havens[start + i].y = Spring.GetGroundHeight(havens[start + i].x, havens[start + i].z)
                end
            end
        end
    end
]]

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag

VFS.Include("LuaUI/Libs/SafeZone.lua")
local SafeZone=WG.SafeZone

VFS.Include("LuaUI/Libs/EZDrawer.lua")
local EZDrawer=WG.EZDrawer

local spGetMyTeamID=Spring.GetMyTeamID
local spMarkerAddPoint=Spring.MarkerAddPoint
local spEcho=Spring.Echo
local spGetGroundHeight = Spring.GetGroundHeight
local spSendLuaRulesMsg=Spring.SendLuaRulesMsg

local RADIUS = 160 --retreat zone radius
local DIAM = RADIUS * 2
local RADSQ = RADIUS * RADIUS
---@type unordered_list<{x:WldxPos,z:WldzPos}> -- 
-- ---@type {count:integer,data:{[integer]:{x:number,z:number}}}
local teamHavens=WackyBag.collections.unordered_list.new() --{count = 0, items = {}}--

--- movedHavens[id]=[x,z]
---@type unordered_list<[number,number]>


--- movedHavens[id]=[(from):[x,z],(to):[gx,gz]]
---@type unordered_list<[WldxPos,WldzPos]>
local hidedHavens=WackyBag.collections.unordered_list.new()
---@type Frame
local havenIsSafeTime=5*Game.gameSpeed
---@type Frame
local havenMoveSafeTime=0*Game.gameSpeed

function GetHavens()
    local teamID=spGetMyTeamID()
    local havenCount= Spring.GetTeamRulesParam(teamID, "haven_count")
    local start = havenCount
    if havenCount then
        teamHavens.count=havenCount
        for i = 1, havenCount do
            teamHavens[i] = {
                x = Spring.GetTeamRulesParam(teamID, "haven_x" .. i),
                z = Spring.GetTeamRulesParam(teamID, "haven_z" .. i)
            }
        end
    end
end


local editing=false

function MyHavenUpdate(teamID, allyTeamID)
    spEcho("game_message: " .. "try update")
    if editing then
        return
    end
	local spectating = Spring.GetSpectatingState()
	if (not spectating and Spring.GetLocalTeamID() == teamID) then
		GetHavens()
	end
end

function widget:Initialize()
    if WackyBag.utils.DisableForSpec(widgetHandler) then
        return
    end
    
	GetHavens()
end

local updateTime=30

---@return integer|nil
local function PosHaveHaven(x,z,ignorehaven)
    ignorehaven=ignorehaven or -1
    for enumhavenId = 1, teamHavens.count do
        if(enumhavenId~=ignorehaven)  then
            local dx,dz=teamHavens[enumhavenId].x-x,teamHavens[enumhavenId].z-z
            if (dx*dx+dz*dz)<RADSQ then
                return enumhavenId
            end
        end
    end
    return nil
end

---@return integer|nil
local function PosHaveHideHaven(x,z,ignorehaven)
    ignorehaven=ignorehaven or -1
    for enumhavenId = 1, hidedHavens.count do
        if(enumhavenId~=ignorehaven)  then
            local dx,dz=hidedHavens[enumhavenId][1]-x,hidedHavens[enumhavenId][2]-z
            if (dx*dx+dz*dz)<RADSQ then
                return enumhavenId
            end
        end
    end
    return nil
end

function widget:GameFrame(n)
    if(n % updateTime==0) then
        GetHavens()
        editing=true
        for havenId = 1, teamHavens.count do
            local px,pz=teamHavens[havenId].x,teamHavens[havenId].z
            --spMarkerAddPoint(px,0,pz,"haven" .. havenId)
            local gx,gz=SafeZone.PosToGrid(px,pz)
            if(SafeZone.SafeZoneGrid[gx][gz].DangerTime-SafeZone.GameTime>havenIsSafeTime)then
                if not PosHaveHideHaven(px,pz) then
                    hidedHavens:add({px,pz})
                end
                local py=spGetGroundHeight(px,pz)
                spSendLuaRulesMsg('sethaven|' .. px .. '|' .. py .. '|' .. pz )
            end
        end
        GetHavens()

        for movedHavenId = 1, hidedHavens.count do
            local tarpx,tarpz=hidedHavens[movedHavenId][1],hidedHavens[movedHavenId][2]
            local targx,targz=SafeZone.PosToGrid(tarpx,tarpz)
            if(SafeZone.ValidGridPos(targx,targz) and SafeZone.SafeZoneGrid[targx][targz].DangerTime-SafeZone.GameTime<havenMoveSafeTime) then
                if not PosHaveHaven(tarpx,tarpz) then
                    local tarpy=spGetGroundHeight(tarpx,tarpz)
                    spSendLuaRulesMsg('sethaven|' .. tarpx .. '|' .. tarpy .. '|' .. tarpz )
                end
                hidedHavens:remove(movedHavenId)
                movedHavenId=movedHavenId-1
            end
        end

        editing=false
    end
end

function widget:PlayerChanged (playerID)
    WackyBag.utils.DisableForSpec(widgetHandler)
end