function widget:GetInfo()
	return {
		name      = "Auto Move Haven",
		desc      = "automatically move retreat zone to safe place",
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

VFS.Include("LuaUI/Configs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag

VFS.Include("LuaUI/Configs/SafeZone.lua")
local SafeZone=WG.SafeZone

VFS.Include("LuaUI/Configs/EZDrawer.lua")
local EZDrawer=WG.EZDrawer

local spGetMyTeamID=Spring.GetMyTeamID
local spMarkerAddPoint=Spring.MarkerAddPoint
local spEcho=Spring.Echo
local spGetGroundHeight = Spring.GetGroundHeight
local spSendLuaRulesMsg=Spring.SendLuaRulesMsg

local RADIUS = 160 --retreat zone radius
local DIAM = RADIUS * 2
local RADSQ = RADIUS * RADIUS

local teamHavens={count = 0, data = {}}

function GetHavens()
    local teamID=spGetMyTeamID()
    local havenCount= Spring.GetTeamRulesParam(teamID, "haven_count")
    local start = havenCount
    if havenCount then
        teamHavens.count=havenCount
        for i = 1, havenCount do
            teamHavens.data[i] = {
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
    --widgetHandler:RegisterGlobal("HavenUpdate", HavenUpdate)
    --[[
    local rawFn=HavenUpdate
    spEcho("game_message: havenUpdateFn".. tostring(HavenUpdate))
    HavenUpdate=function ()
        spEcho("game_message: ".."do add fn")
        rawFn()
        MyHavenUpdate()
    end
    ]]
	GetHavens()
end

local updateTime=30

function widget:GameFrame(n)
    if(n % updateTime==0) then
        GetHavens()
        local changed=false
        editing=true
        for havenId = 1, teamHavens.count do
            local px,pz=teamHavens.data[havenId].x,teamHavens.data[havenId].z
            --spMarkerAddPoint(px,0,pz,"haven" .. havenId)
            local gx,gz=SafeZone.PosToGrid(px,pz)
            if(SafeZone.SafeZoneGrid[gx][gz].DangerTime>SafeZone.GameTime)then
                local newgx,newgz=SafeZone.FindClosestSafePlace(gx,gz,-2.5)
                if(newgz==nil) then
                else
                    local py=spGetGroundHeight(px,pz)
                    spSendLuaRulesMsg('sethaven|' .. px .. '|' .. py .. '|' .. pz )

                    local newx,newz=SafeZone.GridPosToCenter(newgx,newgz)
                    teamHavens.data[havenId].x,teamHavens.data[havenId].z=newx,newz
                    local duplicateHaven=false
                    for enumhavenId = 1, teamHavens.count do
                        if(enumhavenId~=havenId)  then
                            local dx,dz=teamHavens.data[enumhavenId].x-newx,teamHavens.data[enumhavenId].z-newz
                            if (dx*dx+dz*dz)<RADSQ then
                                duplicateHaven=true
                                break
                            end
                        end
                    end

                    local newy=spGetGroundHeight(newx,newz)
                    if not duplicateHaven then
                        spSendLuaRulesMsg('sethaven|' .. newx .. '|' .. newy .. '|' .. newz )
                    end
                    
                    EZDrawer.Add(EZDrawer.DrawerTemplates.DrawTimed(function (tl,tm)
                        EZDrawer.DrawerTemplates.DrawVecVer(px,py,pz,newx,newy,newz,{0,1,0,0.5*(tl/tm)},16,0.2)
                    end,Game.gameSpeed*5))


                    changed=true
                end
            end
        end
        if(changed) then
            GetHavens()
        end
        editing=false
    end
end

function widget:PlayerChanged (playerID)
    WackyBag.utils.DisableForSpec()
end