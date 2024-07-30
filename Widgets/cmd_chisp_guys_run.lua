function widget:GetInfo()
	return {
		name      = "Crisp Guys Run",
		desc      = "Call units which has 99% retreat and no range<=750m weapon to avoid danger zone",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = true,
	}
end
--[[
    function widget:UnitFinished(unitID, unitDefID, unitTeam)
		if UnitDefs[unitDefID].canReclaim and not UnitDefs[unitDefID].isFactory and (unitTeam==GetMyTeamID()) then
			ConStack[unitID%UPDATE_FRAME][unitID] = ConController:new(unitID);
		end
    end
]]

