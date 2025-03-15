if WG.WackyBag.utils==nil then
    local utils={}
    WG.WackyBag.utils=utils
    
    utils.MapSizeUnit=512
    --utils.FramePerSecond=Game.gameSpeed
    --utils.GetFrame=Spring.GetGameFrame
    utils.GridWitdh,utils.GridHeight=Game.mapSizeX/utils.MapSizeUnit,Game.mapSizeZ/utils.MapSizeUnit

    function utils.PrintTable(table)
        for key, value in pairs(table) do
            Spring.Echo(tostring (key) .. ":" .. tostring(value))
        end
    end

    local function FindLocal(searchName)
        local getlocal = debug.getlocal
        for level = 3, 13 do
            local i, name, value = 0, "",{}
            while name do
                i = i + 1
                name, value = getlocal(level, i)
                --Spring.Echo(name, value)
                if name == searchName then
                    --Spring.Echo('FOUND', name, value)
                    return value
                end
            end
        end
    end
    if not utils.springRestricted then
        local springRestricted = FindLocal('springRestricted')
        --Spring.Echo("springRestricted is ", springRestricted)
        utils.springRestricted=springRestricted
        for key, value in pairs(springRestricted) do
            Spring[key]=value
        end
    end
    
    VFS.Include(WG.WackyBag.path .. "utils/get_proj.lua")

    local spGiveOrderToUnit=Spring.GiveOrderToUnit
    local CMD_INSERT=CMD.INSERT
    function utils.InsertOrderToUnit(unitId,DoLocatePosition,Tag,CmdId,params,option)

        local insertparams={Tag,CmdId,option}
        ---@type any
        local insertOption=0

        for index, value in ipairs(params) do
            insertparams[index+3]=value
        end
        
        if DoLocatePosition then
            insertOption={"alt"}
        end
        spGiveOrderToUnit(
            unitId,
            CMD_INSERT,
            insertparams,
            insertOption
        );
    end
    
    local CMD_REMOVE=CMD.REMOVE
    function utils.RemoveOrderOfUnit(unitId,cmdtag)
        spGiveOrderToUnit(unitId,CMD_REMOVE,{cmdtag},0)
    end

    local GetOrDefMetatable={
        __index=function (t,k)
            return rawget(t,k) or rawget(t,"default")
        end
    }
    function utils.SetGetOrDef(t)
        setmetatable(t,GetOrDefMetatable)
    end

    function utils.PosInWld(x,z)
        return x>=0 and x<Game.mapSizeX and z>=0 and z<Game.mapSizeZ
    end
    function utils.curryget(t)
        return function (k)
            return t[k]
        end
    end

    --local spIsUnitAllied=Spring.IsUnitAllied
    local spValidUnitID=Spring.ValidUnitID 
    local spGetUnitDefID=Spring.GetUnitDefID
    local spGetUnitTeam =Spring.GetUnitTeam
    local spGetUnitAllyTeam=Spring.GetUnitAllyTeam

    local spGetMyTeamID=Spring.GetMyTeamID
    local spGetMyAllyTeamID=Spring.GetMyAllyTeamID
    --local spGetUnitDefID=Spring.GetUnitDefID

    ---Common check unit's validity, ud, team, allyteam
    ---
    ---team/allyteam : nil(don't check)|true(= mine)|false(~= mine)|TeamId
    ---
    ---@param unitId UnitId
    ---@param udid UnitDefId|nil
    ---@param team TeamId|boolean|nil
    ---@param allyteam AllyteamId|boolean|nil
    ---@return boolean
    function utils.CheckUnit(unitId,udid,team,allyteam)

        if not spValidUnitID(unitId) then
            return false
        end

        if (udid~=nil) and not (spGetUnitDefID(unitId)==udid) then
            return false
        end

        if allyteam~=nil then
            if allyteam==false then
                allyteam = spGetMyAllyTeamID()
                if allyteam==spGetUnitAllyTeam(unitId) then
                    return false
                end
            else
                if allyteam==true then
                    allyteam = spGetMyAllyTeamID()
                end
                if allyteam~=spGetUnitAllyTeam(unitId) then
                    return false
                end
            end
        end

        if team~=nil then
            if team==false then
                team = spGetMyTeamID()
                if team == spGetUnitTeam(unitId) then
                    return false
                end
            else
                if team==true then
                    team = spGetMyTeamID()
                end
                if team~=spGetUnitTeam(unitId) then
                    return false
                end
            end
            
        end

        
        return true
    end
    do
        local inv_piover2=1/(math.pi/2)
        local atan=math.atan
        function utils.inf_to_n1_1_atan(x)
            return atan(x)*inv_piover2
        end
    end
    VFS.Include(WG.WackyBag.path .. "utils/for_widget.lua")

    function utils.DisableForSpec(widgetHandler)
        --local testGet=getfenv(1).widgetHandler
            --Spring.Echo("DisableForSpec Autoget: " .. tostring(testGet) .. "Eq: ".. tostring(testGet==widgetHandler))
            if Spring.GetSpectatingState() then
                widgetHandler:RemoveWidget()
                return true
            end
            return false
    end
    -- math.tanh
    function utils.ListToTable(list,tablevalue)
        tablevalue=tablevalue or true
        local res={}
        for key, value in pairs(list) do
            res[value]=tablevalue
        end
        return res
    end
end
