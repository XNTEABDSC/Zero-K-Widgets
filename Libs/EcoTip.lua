if(WG.EcoTip==nil) then

    VFS.Include("LuaUI/Libs/SafeZone.lua")
    local SafeZone = WG.SafeZone

    local spGetTeamRulesParam =Spring.GetTeamRulesParam
    local spGetTeamList = Spring.GetTeamList
    local spGetGameFrame=Spring.GetGameFrame
    --local spAreTeamsAllied=Spring.AreTeamsAllied
    
	local myTeamId=Spring.GetMyTeamID()
	local myPlayerId=Spring.GetMyPlayerID()
	local myAllyTeamId=Spring.GetMyAllyTeamID()

    local spGetTeamResources=Spring.GetTeamResources
    --WG.metalSpots
    --Spring.TestBuildOrder 
    VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
    local WackyBag=WG.WackyBag

    local atan1=WackyBag.utils.inf_to_n1_1_atan

    local EcoTip={}
    WG.EcoTip=EcoTip

    EcoTip.ratio_eco_all_should=0.4
    EcoTip.ratio_eco_all_current=0.4

    EcoTip.ratio_bp_eco_all_should=0.5

    EcoTip.eco_value_current=1.0

    EcoTip.eco_value_should=1.0

    EcoTip.bp_eco_should=1.0

    local UpdateDelay=60

    local LastUpdate=0

    function EcoTip.Update(currentFrame)
        currentFrame=currentFrame or spGetGameFrame()
        if currentFrame-LastUpdate < UpdateDelay then
            return
        end
        LastUpdate=currentFrame

        local ratio_eco_all_should=EcoTip.ratio_eco_all_should

        local total_value=0
        local eco_value=0

        for _, TeamId in pairs(spGetTeamList(myAllyTeamId)) do
            total_value=total_value+spGetTeamRulesParam(TeamId,"stats_history_unit_value_current")
            eco_value=eco_value+spGetTeamRulesParam(TeamId,"stats_history_unit_value_econ_current")
        end

        local current_ratio_eco_other=eco_value/(total_value-eco_value)
        EcoTip.ratio_eco_all_current=eco_value/total_value
        local ratio_bp_eco_other= (ratio_eco_all_should*ratio_eco_all_should)/current_ratio_eco_other

        EcoTip.eco_value_current=eco_value

        EcoTip.eco_value_should=total_value*ratio_eco_all_should

        EcoTip.ratio_bp_eco_all_should=1/(1+1/ratio_bp_eco_other)

        local _,_,_,metalIncome=spGetTeamResources(myTeamId,"metal")

        EcoTip.bp_eco_should=metalIncome*EcoTip.ratio_bp_eco_all_should


    end
end