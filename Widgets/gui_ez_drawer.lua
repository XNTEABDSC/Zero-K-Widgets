function widget:GetInfo()
	return {
		name      = "EZ Drawer",
		desc      = "very easy to draw things",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = math.huge,
		enabled   = true,
	}
end
VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
VFS.Include("LuaUI/Libs/EZDrawer.lua")

local EZDrawer=WG.EZDrawer
local datas=EZDrawer.datas


local GL_QUADS = GL.QUADS
local GL_LINES=GL.LINES
local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local spGetGameFrame=Spring.GetGameFrame


function widget:DrawWorld()
    if Spring.IsGUIHidden() then
		return
	end
    local currtime=spGetGameFrame()
    local i=1
    while i<=datas.Drawers.count do
        local drawer=datas.Drawers[i]
        if drawer() then
            i=i+1
        else
            datas.Drawers:remove(i)
        end

        --[[
        local drawer=datas.Drawers[i]
        local timeLeft=drawer.timeMark-currtime
        if(timeLeft<0) then
            datas.Drawers:remove(i)
        else
            drawer.fn(timeLeft,drawer.timeMax)
            i=i+1
        end]]
    end
end