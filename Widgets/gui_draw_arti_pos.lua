function widget:GetInfo()
	return {
		name      = "arti drawer",
		desc      = "draw artillery projectile path",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end

---@class WpnInfoAndProjs
---@field WDId WeaponDefId
---@field aoe number
---@field lineWidth number
---@field Projs list<ProjectileId>

---@type list<WpnInfoAndProjs>
local WatchWpnAndProjs={}

local WatchWpnNames={
	"bomberheavy_arm_pidr",
	"chicken_blimpy_dodobomb",
	"cloakarty_hammer_weapon",
	"empmissile_emp_weapon",
	"jumparty_napalm_sprayer",
	"missileslow_weapon",
	"napalmmissile_weapon",
	"nuclear_missile",
	"raveparty_blue_shocker",
	"raveparty_green_stamper",
	"raveparty_orange_roaster",
	"raveparty_red_killer",
	"raveparty_violet_slugger",
	"raveparty_yellow_slammer",
	"seismic_seismic_weapon",
	"shiparty_plasma",
	"shipcarrier_disarm_rocket",
	"shipheavyarty_plasma",
	"spidercrabe_arm_crabe_gauss",
	"staticarty_plasma",
	"staticheavyarty_plasma",
	"staticnuke_crblmssl",
	"tacnuke_weapon",
	"tankheavyarty_plasma",
	"tankarty_core_artillery",
	"veharty_mine",
	"vehheavyarty_cortruck_rocket"
}

local wgGetProjectiles=WG.WackyBag.utils.get_proj.GetProjList

local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetProjectileVelocity=Spring.GetProjectileVelocity
local spGetProjectileGravity=Spring.GetProjectileGravity
local spGetGroundHeight=Spring.GetGroundHeight


local WDIdToWatchWpn={}


local function GetWatchWeaponDefs()
	local function SetWatchWeaponDef(wd)
		local innerId=#WatchWpnAndProjs+1
		WatchWpnAndProjs[innerId]={
			WDId=wd.id,
			aoe=wd.damageAreaOfEffect,
			lineWidth=math.log(wd.damages[0]+1,2),
			Projs={}
		}
		WDIdToWatchWpn[wd.id]=innerId
	end
	for key, value in pairs(WatchWpnNames) do
		SetWatchWeaponDef(WeaponDefNames[value])
	end
end


local spGetProjectileDefID=Spring.GetProjectileDefID

local function CheckProjs()
	for _, WDInfo in pairs(WatchWpnAndProjs) do
		local ProjList=WDInfo.Projs
		local ProjIndex=1
		local ProjCount=#ProjList
		while ProjIndex<ProjCount do
			local ProjId=ProjList[ProjIndex]
			if spGetProjectilePosition(ProjId)==nil	then
				ProjList[ProjIndex]=ProjList[ProjCount]
				ProjList[ProjCount]=nil
				ProjCount=ProjCount-1
			else
				ProjIndex=ProjIndex+1
			end
		end
		if ProjIndex==ProjCount then
			local ProjId=ProjList[ProjIndex]
			if spGetProjectilePosition(ProjId)==nil	then
				ProjList[ProjIndex]=nil
			end
		end
	end
end

local function UpdateProjs()
	for _, WDInfo in pairs(WatchWpnAndProjs) do
		WDInfo.Projs={}
	end
	WatchProjs={}
	for key, value in pairs(wgGetProjectiles()) do
		local WDInnerId=WDIdToWatchWpn[spGetProjectileDefID(value)]
		if WDInnerId~=nil then
			local l=WatchWpnAndProjs[WDInnerId].Projs
			l[#l+1] = value
		end
	end
end

--[[
local spGetVisibleProjectiles     = SpringRestricted.GetVisibleProjectiles
---@type list<projId>
projs=spGetVisibleProjectiles()

local spGetProjectilePosition     = Spring.GetProjectilePosition
local spGetProjectileDefID        = Spring.GetProjectileDefID
local spGetProjectileVelocity     = Spring.GetProjectileVelocity
local spGetProjectileType         = Spring.GetProjectileType
]]
local aoeLineWidthMult     = 64
local numAoECircles=9
local mouseDistance = 1000

local spGetCameraPosition=Spring.GetCameraPosition
local spTraceScreenRay         = Spring.TraceScreenRay
local spGetMouseState          = Spring.GetMouseState
local spGetUnitPosition=Spring.GetUnitPosition
local spGetFeaturePosition=Spring.GetFeaturePosition
local sqrt=math.sqrt
local function GetMouseTargetPosition()
	local mx, my = spGetMouseState()
	local mouseTargetType, mouseTarget = spTraceScreenRay(mx, my, false, true, false, true)
	if (mouseTargetType == "ground") then
		return mouseTarget[1], mouseTarget[2], mouseTarget[3], true
	elseif (mouseTargetType == "unit") then
		return spGetUnitPosition(mouseTarget)
	elseif (mouseTargetType == "feature") then
		local _, coords = spTraceScreenRay(mx, my, true, true, false, true)
		if coords and coords[3] then
			return coords[1], coords[2], coords[3], true
		else
			return spGetFeaturePosition(mouseTarget)
		end
	else
		return nil
	end
end
local function GetMouseDistance()
	local cx, cy, cz = spGetCameraPosition()
	local mx, my, mz = GetMouseTargetPosition()
	if (not mx) then
		return nil
	end
	local dx = cx - mx
	local dy = cy - my
	local dz = cz - mz
	return sqrt(dx*dx + dy*dy + dz*dz)
end

local aoeColor             = {1, 0, 0, 0.75}
local circleDivs           = 64
local PI=math.pi
local cos                    = math.cos
local sin                    = math.sin
local circleList
local scatterLineWidthMult=1024

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local PrintTable=WG.WackyBag.utils.PrintTable

VFS.Include("LuaUI/Libs/EZDrawer.lua")
local EZDrawer=WG.EZDrawer

local glBeginEnd             = gl.BeginEnd
local glCallList             = gl.CallList
local glCreateList           = gl.CreateList
local glColor                = gl.Color
local glDeleteList           = gl.DeleteList
local glDepthTest            = gl.DepthTest
local glDrawGroundCircle     = gl.DrawGroundCircle
local glLineStipple          = gl.LineStipple
local glLineWidth            = gl.LineWidth
local glPointSize            = gl.PointSize
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local GL_LINES               = GL.LINES
local GL_LINE_STRIP           = GL.LINE_STRIP
local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_POINTS              = GL.POINTS



local function UnitCircleVertices()
	for i = 1, circleDivs do
		local theta = 2 * PI * i / circleDivs
		glVertex(cos(theta), 0, sin(theta))
	end
end

local function DrawUnitCircle()
	glBeginEnd(GL_LINE_LOOP, UnitCircleVertices)
end

local function SetupDisplayLists()
	circleList = glCreateList(DrawUnitCircle)
end

local function DeleteDisplayLists()
	glDeleteList(circleList)
end

local function DrawCircle(x, y, z, radius)
	glPushMatrix()
	glTranslate(x, y, z)
	glScale(radius, radius, radius)

	glCallList(circleList)

	glPopMatrix()
end

--- from gui_attack_aoe
local function DrawAoe(tx,ty,tz,aoe,alpha2)
	glLineWidth(math.max(0.05, aoeLineWidthMult * aoe / mouseDistance))
	
	for i = 1, numAoECircles do
		local proportion = i / (numAoECircles + 1)
		local radius = aoe * proportion
		local alpha = alpha2*aoeColor[4] * (1 - proportion)
		glColor(aoeColor[1], aoeColor[2], aoeColor[3], alpha)
		DrawCircle(tx, ty, tz, radius)
	end

	glColor(1,1,1,1)
	glLineWidth(1)
end


---@type {[ProjectileId]:{proOwnerID:UnitId,weaponDefID:WeaponDefId}}


---comment
---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPath(proID,wpndef)
	local initTimeCount=Game.gameSpeed*8
	local timeCount=initTimeCount
	local posx,posy,posz=spGetProjectilePosition(proID)
	--[[
	if posx==nil then
		Spring.Echo("Odd proj. id: " .. proID .. ", def: " .. WeaponDefs[wpndef].name)
		--Spring.SetNoPause(false)
		return function ()
			return nil
		end
	end]]
	local velx,vely,velz=spGetProjectileVelocity(proID)
	local grav= spGetProjectileGravity( proID )
	if 1<WeaponDefs[wpndef].flightTime then
		grav=0
	end

	return function ()
		timeCount=timeCount-1
		if 0>=timeCount then
			return nil
		end
		local GroundHeight=spGetGroundHeight(posx,posz)
		local heightDef=GroundHeight-posy
		if heightDef>0 then
			local vlen=heightDef/vely
			posx,posy,posz=posx-velx*vlen,posy-vely*vlen,posz-velz*vlen
			local tl=(timeCount-vlen)/initTimeCount
			timeCount=-1
			return posx,posy,posz,tl
		end
		local oldposx,oldposy,oldposz=posx,posy,posz
		vely=vely+grav
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end
--[====[
---@param proID ProjectileId
---@param wpndef WeaponDefId
---@param fn fun(x:number,y:number,z:number,tl:number)
---@return number
---@return number
---@return number
---@return number
local function EnumProjPathF(proID,wpndef,fn)
	local initTimeCount=Game.gameSpeed*8
	local timeCount=initTimeCount
	local posx,posy,posz=spGetProjectilePosition(proID)
	local velx,vely,velz=spGetProjectileVelocity(proID)
	local grav= spGetProjectileGravity( proID )
	if 1<WeaponDefs[wpndef].flightTime then
		grav=0
	end

	while 0>=timeCount and spGetGroundHeight(posx,posz)>posy do
		timeCount=timeCount-1
		if 0>=timeCount then
			return nil
		end
		if spGetGroundHeight(posx,posz)>posy then
			return nil
		end
		local oldposx,oldposy,oldposz=posx,posy,posz
		vely=vely+grav
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end
]====]

---comment
---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPrevPath(proID,wpndef)
	local initTimeCount=Game.gameSpeed*8
	local timeCount=initTimeCount
	local posx,posy,posz=spGetProjectilePosition(proID)
	--[[
	if posx==nil then
		Spring.Echo("Odd proj. id: " .. proID .. ", def: " .. WeaponDefs[wpndef].name)
		--Spring.SetNoPause(false)
		return function ()
			return nil
		end
	end]]
	local velx,vely,velz=spGetProjectileVelocity(proID)
	velx,vely,velz=-velx,-vely,-velz
	local grav= spGetProjectileGravity( proID )
	if 1<WeaponDefs[wpndef].flightTime then
		return function ()
			return nil
		end
	end

	return function ()
		timeCount=timeCount-1
		if 0>=timeCount then
			return nil
		end
		if spGetGroundHeight(posx,posz)>posy then
			return nil
		end
		local oldposx,oldposy,oldposz=posx,posy,posz
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		vely=vely+grav
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end

function widget:DrawWorld()
	CheckProjs()
	--CheckProjs()
	mouseDistance= GetMouseDistance() or 1000
	local AOEDraws={}

	for _, WDInfo in pairs(WatchWpnAndProjs) do
		local aoe=WDInfo.aoe
		local lineWidth=WDInfo.lineWidth
		local WDId=WDInfo.WDId
		
        glLineWidth(lineWidth)
		local landPos={}
		for i, projid in pairs(WDInfo.Projs) do

			function DrawPathLine()
				
				local enumf=EnumProjPath(projid,WDId)

				
				local x,y,z,tl
				while true do
					local x_,y_,z_,tl_=enumf()
					if(x_==nil) then
						break;
					end
					x,y,z,tl=x_,y_,z_,tl_
					glColor(aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl )
					glVertex(x,y,z)
				end
				if tl and 0.1<tl then
					AOEDraws[#AOEDraws+1] = {x,y,z,aoe,tl}
				end
				
				
				



				--[[
				for x,y,z,tl in enumf() do
					glColor(aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl )
					glVertex(x,y,z)
				end
				]]
				--[[
				local oldx,oldy,oldz,oldtl=enumf()
				for x,y,z,tl in enumf do
					glColor(aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* oldtl )
					glVertex(oldx,oldy,oldz)
					--EZDrawer.DrawerTemplates.DrawLine(oldx,oldy,oldz,x,y,z,{},WatchWpnInfo[WDId].lineWidth*scatterLineWidthMult/mouseDistance)
					oldx,oldy,oldz,oldtl=x,y,z,tl
				end
				glVertex(oldx,oldy,oldz)
				]]
			end
			glBeginEnd(GL_LINE_STRIP,DrawPathLine)
			
			function DrawPrevPathLine()
				local enumf=EnumProjPrevPath(projid,WDId)
				local x,y,z,tl=enumf()
				while x~=nil do
					glColor(aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl )
					glVertex(x,y,z)
					x,y,z,tl=enumf()
				end
			end
			glBeginEnd(GL_LINE_STRIP,DrawPrevPathLine)
		end
	end

	for i = 1, #AOEDraws do
		local t=AOEDraws[i]
		DrawAoe(t[1],t[2],t[3],t[4],t[5])
	end

	--[==[
	for _, projid in pairs(WatchProjs) do
		local WDId=spGetProjectileDefID(projid)
		if WatchWpnInfo[WDId] then
			do
				local enumf=EnumProjPath(projid,WDId)
				local oldx,oldy,oldz,oldtl=enumf()
				for x,y,z,tl in enumf do
					EZDrawer.DrawerTemplates.DrawLine(oldx,oldy,oldz,x,y,z,{aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl },WatchWpnInfo[WDId].lineWidth*scatterLineWidthMult/mouseDistance)
					oldx,oldy,oldz,oldtl=x,y,z,tl
				end
				if oldtl and 0.1<oldtl and WatchWpnInfo[WDId] then -- hit ground
					DrawAoe(oldx,oldy,oldz,WatchWpnInfo[WDId].aoe,oldtl)
				end
			end
			
			do
				local enumPrev=EnumProjPrevPath(projid,WDId)
				local oldx,oldy,oldz,oldtl=enumPrev()
				for x,y,z,tl in enumPrev do
					EZDrawer.DrawerTemplates.DrawLine(oldx,oldy,oldz,x,y,z,{aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl },WatchWpnInfo[WDId].lineWidth*scatterLineWidthMult/mouseDistance)
					oldx,oldy,oldz,oldtl=x,y,z,tl
				end
			end



		end
			
	end
	]==]
end

function widget:Initialize()
	GetWatchWeaponDefs()
	SetupDisplayLists()

	--widgetHandler:RegisterGlobal(widget, "lupsProjectiles_AddProjectile", MyProjectileCreated) --proID, proOwnerID, weaponID
	--widgetHandler:RegisterGlobal(widget, "lupsProjectiles_RemoveProjectile", MyProjectileDestroyed)
end

function widget:Shutdown()
	DeleteDisplayLists()
	--widgetHandler:DeregisterGlobal(widget, "lupsProjectiles_AddProjectile", MyProjectileCreated) --proID, proOwnerID, weaponID
	--widgetHandler:DeregisterGlobal(widget, "lupsProjectiles_RemoveProjectile", MyProjectileDestroyed)
end

local setted=false
function widget:GameFrame(n)
	if n%5==0 then
		UpdateProjs()
	else
		--CheckProjs()
	end
end