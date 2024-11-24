function widget:GetInfo()
	return {
		name      = "Unit Bag",
		desc      = "Manage units for widget",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = math.huge,
		enabled   = true,
	}
end

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag

VFS.Include("LuaUI/Libs/EZDrawer.lua")
local EZDrawer=WG.EZDrawer

VFS.Include("LuaUI/Libs/UnitsBag.lua")
local UnitBag=WG.UnitBag

local UnitBags=UnitBag.UnitBags

---@type {[string]:list<UnitBag>}
local SourcesToUB={}

---@param ub UnitBag
function AddUnitBagInSrcs(ub,id)
    for key, value in pairs(ub.Params.UpdateSource) do
        if value==true then
            SourcesToUB[key]=SourcesToUB[key] or {}
            SourcesToUB[key][#SourcesToUB[key]+1] = ub
        end
    end
end

UnitBag.AddOnUnitBagNew(AddUnitBagInSrcs)

function UpdateUBForSrc(src,unitId)
    local ubOfSrc=SourcesToUB[src]
    if ubOfSrc then
        for _, ub in pairs(ubOfSrc) do
            ub.UpdateUnit(unitId)
        end
    end
end

function widget:Initialize()
    if WackyBag.utils.DisableForSpec(widgetHandler) then
        return
    end
    for key, UnitId in pairs(Spring.GetAllUnits()) do
        for _, UB in pairs(UnitBags) do
            UB.UpdateUnit(UnitId)
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    UpdateUBForSrc("UnitCreated",unitID)
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
    UpdateUBForSrc("UnitFinished",unitID)
end

function widget:UnitReverseBuilt(unitID, unitDefID, unitTeam)
    UpdateUBForSrc("UnitReverseBuilt",unitID)
end
function widget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
    UpdateUBForSrc("UnitGiven",unitID)
end
function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
    UpdateUBForSrc("UnitTaken",unitID)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    UpdateUBForSrc("UnitDestroyed",unitID)
end

function widget:RenderUnitDestroyed(unitID, unitDefID, unitTeam)
    UpdateUBForSrc("RenderUnitDestroyed",unitID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
    UpdateUBForSrc("UnitEnteredLos",unitID)
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
    UpdateUBForSrc("UnitLeftLos",unitID)
end

function widget:UnitEnteredRadar(unitID, unitTeam, allyTeam, unitDefID)
    UpdateUBForSrc("UnitEnteredRadar",unitID)
end

function widget:UnitLeftRadar(unitID, unitTeam, allyTeam, unitDefID)
    UpdateUBForSrc("UnitLeftRadar",unitID)
end
