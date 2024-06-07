function widget:GetInfo()
	return {
		name      = "arti drawer",
		desc      = "draw arti land pos",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = true,
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