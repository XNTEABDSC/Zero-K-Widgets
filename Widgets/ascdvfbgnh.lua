function widget:GetInfo()
	return {
		name      = "ascdvfbgnh",
		desc      = "ascdvfbgnh",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = 0,
		enabled   = false,
	}
end

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag

local TableEcho=Spring.Utilities.TableEcho

local NoWDCP={
    "stays_underwater","shield_drain",
}

local NoWDType=WackyBag.utils.ListToTable{
    "Shield","Star",
}

local ChoosedUnits={

    --"cloakskirm",
    "amphassault","amphimpulse",
    "cloakarty","cloakraid","cloakriot",
    "gunshipaa","gunshipassault",
    "gunshipkrow","gunshipraid",
    "hoveraa","hoverarty","hoverriot","hoverskirm",
    "shieldaa",
    "shipaa","shiparty","shipassault","shipriot","shipskirm",
    "spideraa","spiderassault","spiderriot","spiderscout",
    "spiderskirm","staticarty","striderarty","tankaa","tankarty","tankassault","tankriot","turretaaclose",
    "turretaafar","turretaaflak","turretaalaser","turretantiheavy","turretheavy","turretheavylaser",
    "turretlaser","turretmissile","vehaa","vehassault","vehraid","vehriot",
    "turretgauss","hoverraid"
}

local function GetEverything()
    local myUDs={}
    for udid, ud in pairs(UnitDefs) do
        local myud={}
        for key, value in ud:pairs() do
            myud[key]=value
        end
        local mywds={}
        local weapons=ud.weapons
        for _, weapons_value in pairs(weapons) do
            local wd=WeaponDefs[weapons_value.weaponDef]
            local mywd={}
            for key2, value2 in wd:pairs() do
                mywd[key2]=value2
            end
            mywds[#mywds+1] = mywd
        end
        myud.weaponDefs=mywds
        myUDs[#myUDs+1] = myud
    end
    local file = io.open("all_zk_uds.json", 'w')
    file:write(Spring.Utilities.json.encode(myUDs))
    file:close()
end

local function GetSelectedThings()
    local selectedUnitData={}
    local function TrySelectUnit(ud)
        if ud.customParams.commtype then
            return
        end
        if ud.damageModifier then
            return
        end
        if ud.canKamikaze then
            return
        end
        local unitData={
            hp=ud.health,
            speed=ud.speed,
            mass=ud.mass,
            size=ud.xsize,
            cost=ud.metalCost,
            name=ud.name,
            losRadius =ud.losRadius ,
            radarRadius =ud.radarRadius ,
        }
        ---@type string
        local moveDefName=ud.moveDef and ud.moveDef.name
        if moveDefName then
            moveDefName=moveDefName:lower()
            unitData.moveDefName=moveDefName
            if moveDefName:find("bot") then
                local l,r=moveDefName:find("bot")
                local prefix=moveDefName:sub(1,l-1)
    
                ---maxwaterdepth>1000
                unitData.move_ground=true
                unitData.move_slope=true
                if prefix:find("a") then -- amph
                    unitData.move_water=true
                end
                if prefix:find("t") then
                    unitData.move_hill=true
                end
            elseif moveDefName:find("tank") then
                unitData.move_ground=true
                
            elseif moveDefName:find("hover") then
                unitData.move_ground=true
                unitData.move_water=true
                local l,r=moveDefName:find("hover")
                local prefix=moveDefName:sub(1,l-1)
                if prefix:find("b") then -- amph
                    unitData.move_slope=true
                end
            elseif moveDefName:find("boat") then
                unitData.move_water=true
            end
            
        else
            unitData.move_air=true
        end

        local weaponDatas={

        }
        local function TrySelectWeapon(wd,udwd)
            if NoWDType[ wd.type] then
                return false
            end

            if wd.damages[0]<=11 then
                return nil
            end
            if wd.damages[Game.armorTypes["shield"]]~=wd.damages[0] then
                return false
            end

            for key, value in pairs(NoWDCP) do
                if wd.customParams[value] then
                    return false
                end
            end
            local weapondata={
                damage=wd.damages[0],
                type=wd.type,
                range=wd.range,
                reload =wd.reload,
                projectilespeed =wd.projectilespeed,
                tracks =wd.tracks,
                accuracy =wd.accuracy +wd.sprayAngle ,
                projectiles =wd.projectiles * wd.salvoSize,
                aoe=wd.damageAreaOfEffect,
                --edgeEffectiveness =wd.edgeEffectiveness ,

            }
            local targets=udwd.onlyTargets
            if targets.land then
                weapondata.target_land=true
            end
            if targets.gunship then
                weapondata.target_air=true
            end
            if wd.waterWeapon then
                weapondata.target_water=true
            end

            if wd.customParams.isaa then
                weapondata.isaa=true
                weapondata.damage=
                --weapondata.damage*10
                wd.damages[Game.armorTypes["planes"]]
            end

            local wdcp=wd.customParams
            if wdcp.script_burst then
                weapondata.reload=tonumber(wdcp.script_reload)
                weapondata.projectiles=weapondata.projectiles * tonumber(wdcp.script_burst)
            end
            --[=[
            if wd.beamtime>0.25 then
                weapondata.isBurstBeam=true
            end]=]

            return weapondata
        end
        for i = 1, #ud.weapons  do
            local wd=WeaponDefs[ud.weapons[i].weaponDef]
            local res=TrySelectWeapon(wd,ud.weapons[i])
            if res~=nil and res==false then
                return
            end
            weaponDatas[#weaponDatas+1] = res
        end

        unitData.weaponDatas=weaponDatas

        return unitData
    end
    for _, udname in pairs(ChoosedUnits) do
        local res=TrySelectUnit(UnitDefNames[udname])
        if res then
            selectedUnitData[#selectedUnitData+1] = res
        end
    end

    --[=[
    for udid, ud in pairs(UnitDefs) do
        TrySelectUnit(ud)
    end]=]
    local file = io.open("get_states_selected.json", 'w')
    file:write(Spring.Utilities.json.encode(selectedUnitData))
    file:close()
end

function widget:Initialize()
    GetSelectedThings()
    --table.save(selectedUnitData,"awdcfvfbgnh.lua")
end