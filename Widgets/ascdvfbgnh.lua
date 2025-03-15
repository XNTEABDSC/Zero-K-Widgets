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
    "amphassault","amphimpulse","cloakarty","cloakraid","cloakriot","cloakskirm","gunshipaa","gunshipassault",
    "gunshipkrow","gunshipraid","hoveraa","hoverarty","hoverriot","hoverskirm","shieldaa",
    "shipaa","shiparty","shipassault","shipriot","shipskirm","spideraa","spiderassault","spiderriot","spiderscout",
    "spiderskirm","staticarty","striderarty","tankaa","tankarty","tankassault","tankriot","turretaaclose",
    "turretaafar","turretaaflak","turretaalaser","turretantiheavy","turretheavy","turretheavylaser",
    "turretlaser","turretmissile","vehaa","vehassault","vehraid","vehriot",
    --,"turretgauss","hoverraid"
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
        if ud.speed==0 then
            return
        end
        if ud.canKamikaze then
            return
        end
        local unitData={
            hp=ud.health,
            speed=ud.speed,
            mass=ud.mass,
            size=ud.moveDef.xsize,
            cost =ud.metalCost,
            name=ud.name
        }
        local weaponDatas={

        }
        local function TrySelectWeapon(wd)
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
                edgeEffectiveness =wd.edgeEffectiveness ,

            }
            if wd.customParams.isaa then
                weapondata.isaa=true
                weapondata.damage=wd.damages[Game.armorTypes["plane"]]
            end
            if wd.beamtime>0.25 then
                weapondata.isBurstBeam=true
            end

            weaponDatas[#weaponDatas+1] = weapondata
        end
        for i = 1, #ud.weapons  do
            local wd=WeaponDefs[ud.weapons[i].weaponDef]
            local res=TrySelectWeapon(wd)
            if res~=nil and res==false then
                return
            end
            weaponDatas[#weaponDatas+1] = res
        end

        unitData.weaponDatas=weaponDatas

        selectedUnitData[#selectedUnitData+1] = unitData
        return
    end
    for _, udname in pairs(ChoosedUnits) do
        TrySelectUnit(UnitDefNames[udname])
    end

    --[=[
    for udid, ud in pairs(UnitDefs) do
        TrySelectUnit(ud)
    end]=]
    local file = io.open("GetSelectedThings.json", 'w')
    file:write(Spring.Utilities.json.encode(selectedUnitData))
    file:close()
end

function widget:Initialize()
    GetSelectedThings()
    --table.save(selectedUnitData,"awdcfvfbgnh.lua")
end