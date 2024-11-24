function widget:GetInfo()
	return {
		name      = "Eco Tip",
		desc      = "tell you how to make money",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = true,
	}
end

VFS.Include("LuaUI/Libs/SafeZone.lua")
local SafeZone = WG.SafeZone

--local spGetTeamResources=Spring.GetTeamResources
--WG.metalSpots
--Spring.TestBuildOrder 
VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag


VFS.Include("LuaUI/Libs/EcoTip.lua")
local EcoTip=WG.EcoTip

local Chili

local Screen0

local ChWindow

local TipWindow

local fontSize = 12

local ChLabel

local EcoRatioCurLabel

local BpRatioShouldLabel

local function UpdateChili(frame)
    EcoTip.Update(frame)
    EcoRatioCurLabel:SetCaption(
        "Eco Ratio: " .. EcoTip.ratio_eco_all_current .. "\n" ..
        "Bp Ratio Should: " .. EcoTip.ratio_bp_eco_all_should .. "\n" ..
        "Bp Should: " .. EcoTip.bp_eco_should
    )
    --BpRatioShouldLabel:SetCaption()
end

function widget:Initialize()
    if WackyBag.utils.DisableForSpec(widgetHandler) then
        return
    end
    if not WG.Chili then
        widgetHandler:RemoveWidget()
        return
    end
    Chili=WG.Chili
    Screen0=Chili.Screen0
    ChWindow=Chili.Window
    ChLabel=Chili.Label
    TipWindow=ChWindow:New{
		classname = "main_window_small_tall",
		name      = 'Eco Tip',
		x         =  50,
		y         = 150,
		width     = 200,
		height    = 50,
		minWidth  = 150,
		minHeight = 50,
		padding = {16, 8, 16, 8},
		dockable  = true,
		dockableSavePositionOnly = true,
		draggable = true,
		resizable = true,
		tweakResizable = true,
		parent = Screen0,
	}

    EcoRatioCurLabel=ChLabel:New{
        parent=TipWindow,
		x      = 0,
		y      = 0,
		height = 20,
        caption = "Eco Ratio: "
    }
    --[=[
    BpRatioShouldLabel=ChLabel:New{
        parent=TipWindow,
		x      = 0,
		y      = 20,
		height = 20,
        caption = "Bp Ratio Should: "
    }]=]
end

function widget:GameFrame(n)
    UpdateChili(n)
end