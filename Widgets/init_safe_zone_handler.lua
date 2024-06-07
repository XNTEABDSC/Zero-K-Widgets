function widget:GetInfo()
	return {
		name      = "SafeZone Handler",
		desc      = "easy way to find the place where is safe",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = math.huge,
		enabled   = true,
	}
end

VFS.Include("LuaUI/Libs/SafeZone.lua")

local spGetUnitDefID=Spring.GetUnitDefID
local spGetUnitPosition=Spring.GetUnitPosition
local spIsUnitAllied        = Spring.IsUnitAllied
local spGetSpectatingState  = Spring.GetSpectatingState
local spMarkerAddPoint=Spring.MarkerAddPoint
local spMarkerErasePosition=Spring.MarkerErasePosition
local spEcho=Spring.Echo
local spGetMyTeamID=Spring.GetMyTeamID
local spGetMyAllyTeamID=Spring.GetMyAllyTeamID
local spValidUnitID = Spring.ValidUnitID
local spGetGroundHeight = Spring.GetGroundHeight
local spIsPosInRadar		= Spring.IsPosInRadar
local spIsPosInLos = Spring.IsPosInLos
local SafeZone=WG.SafeZone

---@type framePerSec
local FramePerSecond=30
local MapSizeUnit=SafeZone.GridSize
local MapWidth, MapHeight = Game.mapSizeX, Game.mapSizeZ
local GridWitdh,GridHeight=SafeZone.GridWitdh,SafeZone.GridHeight



-- The rest of the code is there to disable the widget for spectators
local function DisableForSpec()
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end


local function WatchUnitUpdate()
    --local count=0
    for id,obj in pairs(SafeZone.WatchDangerUnits) do
        --count= count+ 1
        local posX,posY,posZ=spGetUnitPosition(id)
        if(posX == nil) then
            spMarkerAddPoint(obj.posX,obj.posY,obj.posZ,"odd nil unit pos")
        
        else
            obj.posX=posX
            obj.posY=posY
            obj.posZ=posZ

            local gx,gz=SafeZone.PosToGrid(posX,posZ)
            if SafeZone.ValidGridPos(gx,gz) then
                SafeZone.SetZoneDanger(gx,gz)
            end
        end
        
        
    end
    --spEcho("game_message: ".. "watch unit count:" .. count)
end

local function CheckRadarField()
    for gx = 1, GridWitdh do
        ---@cast gx gridX
        for gz = 1, GridHeight do
            ---@cast gz gridZ
            local px,pz=SafeZone.GridPosToCenter(gx,gz)
            local py=spGetGroundHeight(px,pz)+256

            if not spIsPosInLos(px,py,pz,spGetMyAllyTeamID()) then
                if not spIsPosInRadar(px,py,pz,spGetMyAllyTeamID()) then
                    SafeZone.SetZoneDanger(gx,gz)
                else
                    SafeZone.SetZoneDangerTimeUpTo(gx,gz,0)
                end
            end
        end
    end
    
end

local Use_SafeZone_Marker=false
local SafeZone_Marker_Command_On=false

local RemoveMarkerOfShowSafeZoneFlag=0

local function ShowSafeZone()
    for gx,gz in SafeZone.EnumGrid() do
        local px,pz=SafeZone.GridPosToCenter(gx,gz)
        local _,SafeStr=SafeZone.GridSafeState(SafeZone.SafeZoneGrid[gx][gz])
        spMarkerAddPoint(px,spGetGroundHeight(px,pz),pz,SafeStr,true)
    end
    RemoveMarkerOfShowSafeZoneFlag=2;
end

local function RemoveMarkerOfShowSafeZone()
    if RemoveMarkerOfShowSafeZoneFlag>1 then
        RemoveMarkerOfShowSafeZoneFlag=RemoveMarkerOfShowSafeZoneFlag-1
    elseif RemoveMarkerOfShowSafeZoneFlag==1 then
        for gx,gz in SafeZone.EnumGrid() do
            local px,pz=SafeZone.GridPosToCenter(gx,gz)
            spMarkerErasePosition(px,spGetGroundHeight(px,pz),pz)
        end
    end
end

local function TrySetSafeZone_MarkerCommandButton()
    if spGetSpectatingState()==false and WG.GlobalCommandBar and Use_SafeZone_Marker and not SafeZone_Marker_Command_On then
		WG.GlobalCommandBar.AddCommand("LuaUI/Images/dynamic_comm_menu/eye.png", "", ShowSafeZone)
        SafeZone_Marker_Command_On=true
	end
end

function widget:Initialize()
    DisableForSpec()
    Spring.Echo("game_message: " .."mapsize: (" .. MapWidth .. "," .. MapHeight .. ")")
    
    SafeZone.InitGrid()
    TrySetSafeZone_MarkerCommandButton()

end



function widget:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
    --Spring.Echo("game_message: " .."UnitEnteredRadar")
    --Spring.Echo("game_message: " .. tostring(spGetSpectatingState()))
    if spGetSpectatingState()==false and spValidUnitID(unitID) and not spIsUnitAllied(unitID) --[=[ and (#unitDefID[spGetUnitDefID(unitID)].weapons)>0]=]  then
        
    SafeZone.WatchDangerUnits[unitID]=SafeZone.CreateWatchUnit(unitID)

        local ux,uz,ugx,ugz=SafeZone.UnitPosGridPos(unitID)
        if SafeZone.ValidGridPos(ugx,ugz) then
            if(
                SafeZone.SafeZoneGrid[ugx][ugz].DangerTime-SafeZone.GameTime
                < SafeZone.SafeTime) then
                spMarkerAddPoint(ux,0,uz,"warning",true)
            end
            SafeZone.SetZoneDanger(ugx,ugz)
        end
        

        --local ux,uy,uz=spGetUnitPosition(unitID)
        --spMarkerAddPoint(ux,uy,uz,"unit in radar",true)
        --spEcho("unit in radar")
    end
end


function widget:GameFrame(n)
    SafeZone.GameTime=n
    if spGetSpectatingState() then
        return;
    end

    for unitId, obj in pairs(SafeZone.WatchDangerUnits) do
        if not spValidUnitID(unitId) then
            --spMarkerAddPoint(obj.posX,obj.posY,obj.posZ,"remove invalid",true)
            SafeZone.WatchDangerUnits[unitId]=nil
        end
    end
    
    if(n%SafeZone.WatchDangerUnitsTimeDelta==0) then
        CheckRadarField()
        WatchUnitUpdate()
        SafeZone.GridUpdate()
        RemoveMarkerOfShowSafeZone()
    end
    
    --Spring.Echo("GameTime:".. GameTime)
end

---@diagnostic disable: lowercase-global
options_path = 'Settings/Unit Behaviour/SafeZone'
options_order = { 'SafeZone_Marker'}
options = {
---@diagnostic enable: lowercase-global
    SafeZone_Marker = {
        name = 'Use SafeZone Marker',
        desc = "A way to show SafeZone, which do exist",
        type = 'bool',
        value = false,
        OnChange = function(self)
			Use_SafeZone_Marker = self.value
            TrySetSafeZone_MarkerCommandButton()
		end
    }
}

function widget:PlayerChanged (playerID)
	DisableForSpec()
end
