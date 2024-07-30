function widget:GetInfo()
	return {
		name      = "arti drawer",
		desc      = "draw arti land pos",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
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
local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_POINTS              = GL.POINTS

local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetProjectileVelocity=Spring.GetProjectileVelocity
local spGetProjectileGravity=Spring.GetProjectileGravity
local spGetGroundHeight=Spring.GetGroundHeight


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
---@type {[WeaponDefId]:{aoe:number}}
local NeededWpnInfo={}

local function GetWatchWeaponDefs()
	
	--[[
	Spring.Echo("TEST")
	for id,weaponDef in pairs(WeaponDefs) do
		for name,param in weaponDef:pairs() do
		  Spring.Echo(name,param)
		end
	end
	]]
	for id, _ in pairs(WeaponDefs) do
		local value=WeaponDefs[id]
		Spring.Echo("Wpn: " .. id)
		
		--Spring.Echo("game_message: check wpn: " .. value.name .. ", dmg: " .. tostring( value.damages) .. ", range: " .. tostring( value.range) ..", vel: " .. tostring(value.startvelocity))
		

		if value.damages and (value.damages[0]>0) and 
		(not value.flightTime or value.flightTime<=0.1 or value.flightTime>6)  and (not value.beamburst) and
		( value.range and 400<value.range and value.projectilespeed and 0<value.projectilespeed and value.projectilespeed<500 and 2<value.range/(value.projectilespeed*Game.gameSpeed) )then -- and  
			
			Spring.Echo("Get Weapon: " .. id .. "," .. value.name)
			if( value.name=="SHIELDGUN") then
				Spring.Echo("game_message: Felon's Weapon Vel: ".. value.projectilespeed)
			end
			PrintTable(value.damages)
			-- Script.SetWatchWeapon(value.id,true)
			NeededWpnInfo[value.id]={
				aoe=value.damageAreaOfEffect,
				lineWidth=math.log(value.damages[0]+1,4)
			}
		end
	end
end

---@type {[ProjectileId]:{proOwnerID:unitId,weaponDefID:WeaponDefId}}


---comment
---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPath(proID,wpndef)
	local initTimeCount=Game.gameSpeed*8
	local timeCount=initTimeCount
	local posx,posy,posz=spGetProjectilePosition(proID)
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
		if spGetGroundHeight(posx,posz)>posy then
			return nil
		end
		local oldposx,oldposy,oldposz=posx,posy,posz
		vely=vely+grav
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end


---comment
---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPrevPath(proID,wpndef)
	local initTimeCount=Game.gameSpeed*8
	local timeCount=initTimeCount
	local posx,posy,posz=spGetProjectilePosition(proID)
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
		vely=vely+grav
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end

local spGetProjectileDefID=Spring.GetProjectileDefID
local spGetProjectilesInRectangle=Spring.GetProjectilesInRectangle--Spring.GetVisibleProjectiles
function widget:DrawWorld()
	mouseDistance= GetMouseDistance() or 1000
	for _, projid in pairs(spGetProjectilesInRectangle(0,0,Game.mapSizeX,Game.mapSizeZ)) do
		local WDId=spGetProjectileDefID(projid)
		if NeededWpnInfo[WDId] then
			do
				local enumf=EnumProjPath(projid,WDId)
				local oldx,oldy,oldz,oldtl=enumf()
				for x,y,z,tl in enumf do
					EZDrawer.DrawerTemplates.DrawLine(oldx,oldy,oldz,x,y,z,{aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl },NeededWpnInfo[WDId].lineWidth*scatterLineWidthMult/mouseDistance)
					oldx,oldy,oldz,oldtl=x,y,z,tl
				end
				if oldtl and 0.1<oldtl and NeededWpnInfo[WDId] then -- hit ground
					DrawAoe(oldx,oldy,oldz,NeededWpnInfo[WDId].aoe,oldtl)
				end
			end
			
			do
				local enumPrev=EnumProjPrevPath(projid,WDId)
				local oldx,oldy,oldz,oldtl=enumPrev()
				for x,y,z,tl in enumPrev do
					EZDrawer.DrawerTemplates.DrawLine(oldx,oldy,oldz,x,y,z,{aoeColor[1],aoeColor[2],aoeColor[3],aoeColor[4]* tl },NeededWpnInfo[WDId].lineWidth*scatterLineWidthMult/mouseDistance)
					oldx,oldy,oldz,oldtl=x,y,z,tl
				end
			end



		end
			
	end
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
function widget:GameFrame()
	
end