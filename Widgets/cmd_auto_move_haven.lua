function widget:GetInfo()
	return {
		name      = "Auto Move Haven",
		desc      = "automatically move retreat zone to safe place\n",
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
---@type unordered_list<[ [WldxPos,WldzPos],([gridX,gridZ]|nil) ]>
local movedHavens=WackyBag.collections.unordered_list.new()

local havenIsSafeTime=0*Game.gameSpeed
local havenMoveSafeTime=-2.5*Game.gameSpeed

function GetHavens()
    local teamID=spGetMyTeamID()
    local havenCount= Spring.GetTeamRulesParam(teamID, "haven_count")
    local start = havenCount
    if havenCount then
        teamHavens.count=havenCount
        for i = 1, havenCount do
            teamHavens.items[i] = {
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
    if WackyBag.utils.DisableForSpec() then
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
            local dx,dz=teamHavens.items[enumhavenId].x-x,teamHavens.items[enumhavenId].z-z
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
        local changed=false
        editing=true
        for havenId = 1, teamHavens.count do
            local px,pz=teamHavens.items[havenId].x,teamHavens.items[havenId].z
            --spMarkerAddPoint(px,0,pz,"haven" .. havenId)
            local gx,gz=SafeZone.PosToGrid(px,pz)
            if(SafeZone.SafeZoneGrid[gx][gz].DangerTime-SafeZone.GameTime>havenIsSafeTime)then
                local newgx,newgz=SafeZone.FindClosestSafeZone(gx,gz,havenMoveSafeTime)
                if newgz==nil or newgx==nil then
                    movedHavens:add({{px,pz},nil})
                else
                    local py=spGetGroundHeight(px,pz)
                    spSendLuaRulesMsg('sethaven|' .. px .. '|' .. py .. '|' .. pz )
                    local newx,newz=SafeZone.GridPosToCenter(newgx,newgz)
                    local duplicateHaven= PosHaveHaven(newx,newz,havenId)~=nil
                    

                    local newy=spGetGroundHeight(newx,newz)
                    movedHavens:add({{px,pz},{newgx,newgz}})
                    EZDrawer.DrawerTemplates.EZDrawTimedVec(px,py,pz,newx,newy,newz,{0,1,0,0.5},16,0.2,Game.gameSpeed*5)
                    
                    if not duplicateHaven then
                        spSendLuaRulesMsg('sethaven|' .. newx .. '|' .. newy .. '|' .. newz )
                        teamHavens.items[havenId].x,teamHavens.items[havenId].z=newx,newz
                    else
                        teamHavens:remove(havenId)
                        havenId=havenId-1
                    end
                    changed=true
                end
            end
        end
        if(changed) then
            GetHavens()
        end

        for movedHavenId = 1, movedHavens.count do
            local tarpx,tarpz=movedHavens[movedHavenId][1][1],movedHavens[movedHavenId][1][2]
            local targx,targz=SafeZone.PosToGrid(tarpx,tarpz)
            local tarpy=spGetGroundHeight(tarpx,tarpz)
            if(SafeZone.ValidGridPos(targx,targz) and SafeZone.SafeZoneGrid[targx][targz].DangerTime-SafeZone.GameTime<havenMoveSafeTime) then
                if(movedHavens[movedHavenId][2]~= nil) then
                    local fromgx,fromgz=movedHavens[movedHavenId][2][1],movedHavens[movedHavenId][2][2]
                    local frompx,frompz=SafeZone.GridPosToCenter(fromgx,fromgz)
                    local frompy=spGetGroundHeight(frompx,frompz)
                    local fromHaven=PosHaveHaven(frompx,frompz,-1)
                    if fromHaven~=nil then
                        -- spMarkerAddPoint(frompx,frompy,frompz,"removed")
                        spSendLuaRulesMsg('sethaven|' .. frompx .. '|' .. frompy .. '|' .. frompz )
                        teamHavens:remove(fromHaven)
                    end
                    EZDrawer.DrawerTemplates.EZDrawTimedVec(frompx,frompy,frompz,tarpx,tarpy,tarpz,{0,1,0,0.5},16,0.2,Game.gameSpeed*5)
                    
                end
                spSendLuaRulesMsg('sethaven|' .. tarpx .. '|' .. tarpy .. '|' .. tarpz )
                movedHavens:remove(movedHavenId)
                movedHavenId=movedHavenId-1
            end
        end

        editing=false
    end
end

function widget:PlayerChanged (playerID)
    WackyBag.utils.DisableForSpec()
end