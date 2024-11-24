-- ---@diagnostic disable: missing-return
---@meta Spring

Spring={}
---@class UnitId : integer
---@class UnitDefId:integer

---@class PlayerId:integer
---@class TeamId:integer
---@class AllyteamId:integer

---@class timeSec:number

---@class Frame:integer
---@class FramePerSec:integer
---@operator div(FramePerSec):timeSec
---@operator mul(timeSec):Frame

---@class WldDist:number
---@operator div(Frame):WldSpeed
---@operator add(WldDist):WldDist
---@operator add(WldSpeed):WldDist
---@alias WldxPos WldDist
---@alias WldyPos WldDist
---@alias WldzPos WldDist
--[=[
---@class WldxPos:number
---@operator div(frame):WldxVel
---@operator add(WldxPos):WldxPos
---@operator add(WldxVel):WldxPos
---@class WldyPos:number
---@operator div(frame):WldyVel
---@operator add(WldyPos):WldyPos
---@operator add(WldyVel):WldyPos
---@class WldzPos:number
---@operator div(frame):WldzVel
---@operator add(WldzPos):WldzPos
---@operator add(WldzVel):WldzPos
]=]

---@class WldSpeed:number
---@operator mul(Frame):WldDist
---@operator unm:WldSpeed

---@alias WldxVel WldSpeed
---@alias WldyVel WldSpeed
---@alias WldzVel WldSpeed
--[=[
---@class WldxVel:number
---@operator mul(frame):WldxPos
---@operator add(WldxVel):WldxVel
---@operator sub(WldxVel):WldxVel
---@operator unm:WldxVel
---@class WldyVel:number
---@operator mul(frame):WldyPos
---@operator add(WldyVel):WldyVel
---@operator sub(WldyVel):WldyVel
---@operator unm:WldyVel
---@class WldzVel:number
---@operator mul(frame):WldzPos
---@operator add(WldzVel):WldzVel
---@operator sub(WldzVel):WldzVel
---@operator unm:WldzVel
]=]

--- show message to console. `"game_message: ".. msg` to show `msg` at chat (client only)
---@param ... any message to be shown
function Spring.Echo(...)end


---@param UnitId UnitId
---@return UnitDefId
---@nodiscard
function Spring.GetUnitDefID(UnitId)end

---check whether UnitId is valid
---@param UnitId UnitId
---@return boolean
function Spring.ValidUnitID(UnitId)end

---check whether unit is dead
---@param UnitId UnitId
---@return boolean
function Spring.GetUnitIsDead(UnitId)end

---check whether unit belongs to you
---@param UnitId UnitId
function Spring.IsUnitAllied(UnitId)end

--- return unit's base position (bottom),<br>
--- unit's middle position with returnMidPos<br>
--- unit's aim position with returnAimPos<br>
--- extra values are pushed behind<br>
--- eg `posx,posy,posz,aimx,aimy,aimz=spGetUnitPosition(UnitId,false,true)`
---@param UnitId UnitId
---@return WldxPos
---@return WldyPos
---@return WldzPos
---@return WldxPos
---@return WldyPos
---@return WldzPos
---@return WldxPos
---@return WldyPos
---@return WldzPos
function Spring.GetUnitPosition(UnitId,returnMidPos,returnAimPos)end

---@param UnitId UnitId
---@return WldxVel
---@return WldyVel
---@return WldzVel
---@return WldSpeed
function Spring.GetUnitVelocity(UnitId)end

--- get the height of the ground at the pos
---@param x WldxPos
---@param z WldzPos
---@return WldyPos
function Spring.GetGroundHeight(x,z)end

---@return AllyteamId
function Spring.GetMyAllyTeamID()end

---@return TeamId
function Spring.GetMyTeamID()end

---comment
---@param unitId UnitId
---@return TeamId
function Spring.GetUnitTeam(unitId)end

---comment
---@param unitId UnitId
---@return AllyteamId
function Spring.GetUnitAllyTeam(unitId)end

--- return true when spec
---@return boolean
function Spring.GetSpectatingState()end

---whether pos is in radar of allyteamId
---@param x WldxPos
---@param y WldyPos
---@param z WldzPos
---@param allyteamId AllyteamId
---@return boolean
function Spring.IsPosInRadar(x,y,z,allyteamId)end

---whether pos is in los of allyteamId
---@param x WldxPos
---@param y WldyPos
---@param z WldzPos
---@param allyteamId AllyteamId
---@return boolean
function Spring.IsPosInLos(x,y,z,allyteamId)end

---add a marker
---@param x WldxPos
---@param y WldyPos
---@param z WldzPos
---@param msg string
---@param onlyLocal boolean|nil true to add marker to local only
function Spring.MarkerAddPoint(x,y,z,msg,onlyLocal)end

---remove marker at pos
---@param x WldxPos
---@param y WldyPos
---@param z WldzPos
function Spring.MarkerErasePosition(x,y,z)end

---returns units in Cylinder
---@param x WldxPos
---@param z WldzPos
---@param radius WldDist
---@param teamId TeamId
---@return list<UnitId>
function Spring.GetUnitsInCylinder(x,z,radius,teamId)end


Game={}
--- FramePerSec
---@type FramePerSec
Game.gameSpeed=30
---@type WldxPos
Game.mapSizeX=512
---@type WldzPos
Game.mapSizeZ=512


---@class WeaponDefId:integer
---@class WeaponDefName:string
---@class WeaponDef:any --:{id:WeaponDefId,[any]:any}
---@field id WeaponDefId
---@field name WeaponDefName
---@field damageAreaOfEffect number
---@field damages list<number>
---@field flightTime number

---@type table<WeaponDefId,WeaponDef>
WeaponDefs={}

---@type table<WeaponDefName,WeaponDef>
WeaponDefNames={}


---@class ProjectileId:number

---comment
---@param projectileID ProjectileId
---@return WldxPos
---@return WldyPos
---@return WldzPos
function Spring.GetProjectilePosition(projectileID)end


---@param projectileID ProjectileId
---@return WldxVel
---@return WldyVel
---@return WldzVel
function Spring.GetProjectileVelocity(projectileID)end

---@param projId ProjectileId
---@return WeaponDefId
function Spring.GetProjectileDefID(projId)end

---@return Frame
function Spring.GetGameFrame()end

CMD={}