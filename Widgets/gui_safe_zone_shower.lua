

function widget:GetInfo()
	return {
		name      = "SafeZone Shower",
		desc      = "easy way to draw SafeZone",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 10,
		enabled   = true,
	}
end


local spGetSpectatingState=Spring.GetSpectatingState
local spGetGroundHeight = Spring.GetGroundHeight
VFS.Include("LuaUI/Configs/SafeZone.lua")
local SafeZone= WG.SafeZone

local GL_QUADS = GL.QUADS
local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex


local FramePerSecond=30
local TimeBase=-SafeZone.SafeTime*FramePerSecond
local MapSizeUnit=SafeZone.GridSize
local MapWidth, MapHeight = Game.mapSizeX, Game.mapSizeZ
local GridWitdh,GridHeight=SafeZone.GridWitdh,SafeZone.GridHeight

local function DisableForSpec()
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget()
	end
end

local colors={
    {1,0,0},
    {1,1,0},
    {0,1,0}
}
local function ChooseColor(dangerTime)
    if(dangerTime>TimeBase) then
        return colors[1]
    elseif dangerTime>0 then
        return {1,1-dangerTime/TimeBase,0}
    elseif dangerTime>-TimeBase then
        return {1+dangerTime/TimeBase,1,0}
    else
        return colors[3]
    end
end 


local Use_SafeZone_Drawer=false
local SafeZone_Drawer_Command_On=false
local DrawOn=false

local function DrawSafeZoneCmd()
    DrawOn = not DrawOn
end

local function TrySetSafeZone_MarkerCommandButton()
    if spGetSpectatingState()==false and WG.GlobalCommandBar and Use_SafeZone_Drawer and not SafeZone_Drawer_Command_On then
		WG.GlobalCommandBar.AddCommand("LuaUI/Images/dynamic_comm_menu/eye.png", "", DrawSafeZoneCmd)
        SafeZone_Drawer_Command_On=true
	end
end

---@diagnostic disable: lowercase-global
options_path = 'Settings/Unit Behaviour/SafeZone'
options_order = { 'SafeZone_Drawer'}
options = {
---@diagnostic enable: lowercase-global
    SafeZone_Drawer = {
        name = 'Use SafeZone Drawer',
        desc = "A better way to show SafeZone, which do exist",
        type = 'bool',
        value = false,
        OnChange = function(self)
			Use_SafeZone_Drawer = self.value
            TrySetSafeZone_MarkerCommandButton()
		end
    }
}
local function DrawRect(x,z,w,h)
    local function VertexXZ(x,z)
        glVertex(x, spGetGroundHeight(x,z) , z)
    end
    VertexXZ(x,z)
    VertexXZ(x,z+h)
    VertexXZ(x+w,z+h)
    VertexXZ(x+w,z)
end

function widget:Initialize()
    DisableForSpec()
    
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() then
		return
	end
    if DrawOn then
        glLineWidth(2.0)
        glColor(1, 0, 0,0.15)
        for gx = 1, GridWitdh do
            for gz = 1, GridHeight do
                --local dangerId=SafeZone.GridSafeState(SafeZone.SafeZoneGrid[gx][gz])
                local color=ChooseColor(SafeZone.SafeZoneGrid[gx][gz].DangerTime-SafeZone.GameTime)
                glColor(color[1],color[2],color[3],0.15)
                glBeginEnd(GL_QUADS,DrawRect,(gx-1)*MapSizeUnit,(gz-1)*MapSizeUnit,MapSizeUnit,MapSizeUnit)
            end
        end
    end
end


function widget:PlayerChanged (playerID)
	DisableForSpec()
end