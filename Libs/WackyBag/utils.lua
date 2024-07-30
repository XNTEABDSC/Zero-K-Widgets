if WG.WackyBag.utils==nil then
    local utils={}
    WG.WackyBag.utils=utils
    function utils.DisableForSpec(widgetHandler)
        if Spring.GetSpectatingState() then
            widgetHandler:RemoveWidget()
            return true
        end
        return false
    end
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
        Spring.GiveOrderToUnit(
            unitId,
            CMD_INSERT,
            insertparams,
            insertOption
        );
    end
end
