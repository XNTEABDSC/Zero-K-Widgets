function widget:GetInfo()
	return {
		name      = "arty drawer",
		desc      = "draw artillery projectile path",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end

local getordef=WG.WackyBag.utils.SetGetOrDef

---@class WpnInfoAndProjs
---@field WDId WeaponDefId
---@field aoe number
---@field lineWidth number
---@field isnotparabola boolean
---@field name string
---@field Projs list<ProjectileId>
---@field edgeEffectiveness number

---@type list<WpnInfoAndProjs>
local WatchWpnAndProjs={
}
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
local WatchWpnDrawPrevState={

}
local WatchWpnDrawTime={
	default=Game.gameSpeed*8,
	nuclear_missile=Game.gameSpeed*20,
	raveparty_blue_shocker=Game.gameSpeed*20,
	raveparty_green_stamper=Game.gameSpeed*20,
	raveparty_orange_roaster=Game.gameSpeed*20,
	raveparty_red_killer=Game.gameSpeed*20,
	raveparty_violet_slugger=Game.gameSpeed*20,
	raveparty_yellow_slammer=Game.gameSpeed*20,
}


--local aoeColor             = {1, 0, 0, 0.75}

local WatchWpnDrawColor={
	default={1, 0, 0, 0.5}
}

getordef(WatchWpnDrawTime)
getordef(WatchWpnDrawColor)

do
	local trackedMissiles = include("LuaRules/Configs/tracked_missiles.lua")
	for wpnId, data in pairs(trackedMissiles) do
		WatchWpnDrawColor[WeaponDefs[wpnId].name]=data.color
	end
	WatchWpnDrawColor["raveparty_blue_shocker"]=WatchWpnDrawColor["empmissile_emp_weapon"]
	WatchWpnDrawColor["raveparty_orange_roaster"]=WatchWpnDrawColor["napalmmissile_weapon"]
	WatchWpnDrawColor["raveparty_violet_slugger"]=WatchWpnDrawColor["missileslow_weapon"]
	WatchWpnDrawColor["raveparty_green_stamper"]=WatchWpnDrawColor["seismic_seismic_weapon"]
end

local wbGetProjectiles=WG.WackyBag.utils.get_proj.GetProjList
local wbPosInWld=WG.WackyBag.utils.PosInWld

local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetProjectileVelocity=Spring.GetProjectileVelocity
local spGetProjectileGravity=Spring.GetProjectileGravity
local spGetGroundHeight=Spring.GetGroundHeight


local WDIdToWatchWpn={}

local function SetWatchWeaponDef(wd)
	local innerId=#WatchWpnAndProjs+1
	WatchWpnAndProjs[innerId]={
		WDId=wd.id,
		aoe=(wd.damageAreaOfEffect>8 and wd.damageAreaOfEffect) or tonumber(wd.customParams.area_damage_radius) or 0,
		lineWidth=2,--math.log(wd.damages[0]+1)/2,
		Projs={},
		isnotparabola=(wd.flightTime~=nil and wd.flightTime>0),
		name=wd.name,
		edgeEffectiveness=wd.edgeEffectiveness,
		--drawtime=(WatchWpnDrawTime[wpnname])
	}
	WDIdToWatchWpn[wd.id]=innerId
end


local function GetWatchWeaponDefs()
	--[===[
	local function SetWatchWeaponDef(wpnname)
		local wd=WeaponDefNames[wpnname]
		SetWatchWeaponDef(wd)
	end
	for key, wpnname in pairs(WatchWpnNames) do
		SetWatchWeaponDef(wpnname)
	end]===]
	for wdid, wd in pairs(WeaponDefs) do
		--Spring.Utilities.TableEcho(wd.damages,wd.name .. ".damage")
		if  wd.damages[1]>1 and
			(wd.range and wd.range>740) and
			not (wd.beamTime and wd.beamTime>1) and
			not ((wd.customParams or wd.customparams or {}).isaa) and
			not (wd.wobble and wd.wobble>0) and
			not wd.tracks and
			--(wd.weaponVelocity and wd.weaponVelocity<500 or false) and
			--(wd.startVelocity or wd.weaponVelocity) and
			--wd.range/(wd.startVelocity or wd.weaponVelocity)>1.5 and
			true then
			Spring.Echo("select weapon " .. wd.name)
			SetWatchWeaponDef(wd)
		end
	end
end


local spGetProjectileDefID=Spring.GetProjectileDefID

local function CheckProjs()
	for _, WDInfo in pairs(WatchWpnAndProjs) do
		local ProjList=WDInfo.Projs
		local ProjIndex= 1
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
	for key, value in pairs(wbGetProjectiles()) do
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
local numAoECircles=10
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

local circleDivs           = 64
local PI=math.pi
local cos                    = math.cos
local sin                    = math.sin
local circleList
local scatterLineWidthMult=1024

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local PrintTable=Spring.Utilities.TableEcho--WG.WackyBag.utils.PrintTable

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
local function DrawAoe(tx,ty,tz,aoe,alpha2,color,linewidth)
	glLineWidth(math.max(0.05, linewidth* aoe / mouseDistance))
	
	for i = 1, numAoECircles do
		local proportion = i / (numAoECircles + 1)
		local radius = aoe * proportion
		local alpha = alpha2*color[4] * (1 - proportion)
		glColor(color[1], color[2], color[3], alpha)
		DrawCircle(tx, ty, tz, radius)
	end

	glColor(1,1,1,1)
	glLineWidth(1)
end


local function DrawAoE(tx, ty, tz, aoe,aoeColor,alphaMult, edgeEffectiveness,linewidth)
	glLineWidth(linewidth)
	--glLineWidth(math.max(0.05, linewidth * aoe / mouseDistance*64))
	
	for i = 1, numAoECircles-1 do
		local proportion = i / (numAoECircles)
		local radius = aoe * proportion
		local alphaMultByCircle=(1 - proportion) / (1 - proportion * edgeEffectiveness)
		local alpha = aoeColor[4] * alphaMultByCircle  * alphaMult
		glColor(aoeColor[1], aoeColor[2], aoeColor[3], alpha)
		DrawCircle(tx, ty, tz, radius)
	end

end


---@type {[ProjectileId]:{proOwnerID:UnitId,weaponDefID:WeaponDefId}}


---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPath(proID,wpndef , drawtime)
	local initTimeCount=drawtime--Game.gameSpeed*8
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

	return function ()
		timeCount=timeCount-1
		if 0>=timeCount then
			return nil
		end
		
		local GroundHeight=spGetGroundHeight(posx,posz)
		if GroundHeight<0 then
			GroundHeight=0
		end
		local heightDef=GroundHeight-posy
		if heightDef>0 then
			local vlen=heightDef/vely
			posx,posy,posz=posx+velx*vlen,posy+vely*vlen,posz+velz*vlen
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

---comment
---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPrevPath(proID,wpndef, drawtime)
	local initTimeCount=drawtime --
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

	return function ()
		timeCount=timeCount-1
		if 0>=timeCount then
			return nil
		end
		if spGetGroundHeight(posx,posz)>posy or 0>posy then
			return nil
		end
		local oldposx,oldposy,oldposz=posx,posy,posz
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		vely=vely+grav
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end

---@param proID ProjectileId
---@return fun():( WldxPos|nil,WldyPos|nil,WldzPos|nil,number|nil )
local function EnumProjPathStraight(proID,wpndef , drawtime)
	local initTimeCount=drawtime--Game.gameSpeed*8
	local timeCount=initTimeCount
	local posx,posy,posz=spGetProjectilePosition(proID)
	local velx,vely,velz=spGetProjectileVelocity(proID)
	if (vely/math.sqrt(velx*velx+velz*velz))>-0.1  then
		return function ()
			return nil
		end
	end
	return function ()
		timeCount=timeCount-1
		if 0>=timeCount then
			return nil
		end
		local GroundHeight=spGetGroundHeight(posx,posz)
		if GroundHeight<0 then
			GroundHeight=0
		end
		local heightDef=GroundHeight-posy
		if heightDef>0 then
			local vlen=heightDef/vely
			posx,posy,posz=posx+velx*vlen,posy+vely*vlen,posz+velz*vlen
			local tl=(timeCount-vlen)/initTimeCount
			timeCount=-1
			return posx,posy,posz,tl
		end
		local oldposx,oldposy,oldposz=posx,posy,posz
		posx,posy,posz=posx+velx,posy+vely,posz+velz
		return oldposx,oldposy,oldposz,timeCount/initTimeCount
	end
end

function widget:DrawWorld()
	CheckProjs()
	--CheckProjs()
	mouseDistance= GetMouseDistance() or 1000
	local AOEDraws={}

	for WDInnerId, WDInfo in pairs(WatchWpnAndProjs) do
		local WDName=WDInfo.name
		local aoe=WDInfo.aoe
		local lineWidth=WDInfo.lineWidth
		local WDId=WDInfo.WDId
		local color=WatchWpnDrawColor[WDName]
		local drawtime=WatchWpnDrawTime[WDName]--WDInfo.drawtime
        glLineWidth(lineWidth)
		local landPos={}
		local ee=WDInfo.edgeEffectiveness
		if WDInfo.isnotparabola then
			for i, projid in pairs(WDInfo.Projs) do
				function DrawPathLine()
					local enumf=EnumProjPathStraight(projid,WDId,drawtime)
					local x,y,z,tl
					while true do
						local x_,y_,z_,tl_=enumf()
						if(x_==nil) or not wbPosInWld(x_,z_) then
							break;
						end
						x,y,z,tl=x_,y_,z_,tl_
						glColor(color[1],color[2],color[3],color[4]* tl )
						glVertex(x,y,z)
					end
					if tl and 0.1<tl then
						--
						--glBeginEnd(GL_LINE_STRIP,DrawAoE,x,y,z,aoe,color,tl,ee,lineWidth)
						AOEDraws[#AOEDraws+1] = function ()
							DrawAoE(x,y,z,aoe,color,tl,ee,lineWidth)
						end
					end
					
				end
				glBeginEnd(GL_LINE_STRIP,DrawPathLine)
			end
		else
			for i, projid in pairs(WDInfo.Projs) do
				function DrawPathLine()
					local enumf=EnumProjPath(projid,WDId,drawtime)
					local x,y,z,tl
					while true do
						local x_,y_,z_,tl_=enumf()
						if(x_==nil) or not wbPosInWld(x_,z_) then
							break;
						end
						x,y,z,tl=x_,y_,z_,tl_
						glColor(color[1],color[2],color[3],color[4]* tl )
						glVertex(x,y,z)
					end
					if tl and 0.1<tl then
						--glBeginEnd(GL_LINE_STRIP,DrawAoE,x,y,z,aoe,color,tl,ee,lineWidth)
						--DrawAoE(x,y,z,aoe,color,tl,ee,lineWidth)
						AOEDraws[#AOEDraws+1] = function ()
							DrawAoE(x,y,z,aoe,color,tl,ee,lineWidth)
						end
					end
				end
				glBeginEnd(GL_LINE_STRIP,DrawPathLine)
				function DrawPrevPathLine()
					local enumf=EnumProjPrevPath(projid,WDId,drawtime)
					local x,y,z,tl=enumf()
					while x~=nil and wbPosInWld(x,z) do
						glColor(color[1],color[2],color[3],color[4]* tl )
						glVertex(x,y,z)
						x,y,z,tl=enumf()
					end
				end
				glBeginEnd(GL_LINE_STRIP,DrawPrevPathLine)
			end
		end
		
	end
	for i = 1, #AOEDraws do
		local t=AOEDraws[i]
		t()
		--glBeginEnd(GL_LINE_STRIP,t)
	end

end

function widget:Initialize()
	GetWatchWeaponDefs()
	SetupDisplayLists()

end

function widget:Shutdown()
	DeleteDisplayLists()
end

local setted=false
function widget:GameFrame(n)
	if n%3==0 then
		UpdateProjs()
	else
		--CheckProjs()
	end
end