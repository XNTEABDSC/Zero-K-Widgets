function widget:GetInfo()
	return {
		name      = "Auto sim city",
		desc      = "automatically build eco\n",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end


--[[
local place, feature = Spring.TestBuildOrder(buildTestUnitDefID, x, 0 ,z, direction)
x,y,z=Spring.Pos2BuildPos(unitDefID, x, y, z, facing)
]]
