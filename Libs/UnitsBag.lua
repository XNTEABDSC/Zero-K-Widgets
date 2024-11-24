if(WG.UnitBag==nil) then
    local UnitBag={}

    WG.UnitBag=UnitBag;
    
    ---@type list<UnitBag>
    local UnitBags={}
    UnitBag.UnitBags=UnitBags

    
    ---@class WidgetCallin
    ---@field UnitCreated boolean|nil
    ---@field UnitFinished boolean|nil
    ---@field UnitReverseBuilt boolean|nil
    ---@field UnitDestroyed boolean|nil
    ---@field RenderUnitDestroyed boolean|nil
    ---@field UnitGiven boolean|nil
    ---@field UnitTaken boolean|nil
    ---@field UnitEnteredLos boolean|nil
    ---@field UnitLeftLos boolean|nil
    ---@field UnitEnteredRadar boolean|nil
    ---@field UnitLeftRadar boolean|nil


    ---@class UnitBagParams
    ---@field CheckAndGenUnitInfo fun(unitId:UnitId,prev:any):any
    ---@field UpdateSource WidgetCallin


    ---@type list<fun(UnitBag,integer)>
    local OnUnitBagNew={}

    ---do fn on all exist UnitBag and later created
    ---@param fn fun(UnitBag,integer)
    function UnitBag.AddOnUnitBagNew(fn)
        for id, ub in pairs(UnitBags) do
            fn(ub,id)
        end
        OnUnitBagNew[#OnUnitBagNew+1] = fn
    end

    -- ---@class UnitBag<T>:{Units:{[UnitId]:T},}

    ---create a UnitBag
    ---@param Params UnitBagParams
    ---@return UnitBag
    function UnitBag.new(Params)
        
        ---@class UnitBag --<T> {Units:{[UnitId]:T}}
        local o={}

        --[=[
        ---@generic T
        ---@type {[UnitId]:T}
        ]=]
        ---@type {[UnitId]:any}
        local Units={}
        o.Units=Units

        o.Params=Params

        local CheckAndGenUnitInfo=Params.CheckAndGenUnitInfo

        ---do CheckAndGenUnitInfo and register
        ---@param unitId UnitId
        local function UpdateUnit(unitId,infoOld)
            infoOld=infoOld or Units[unitId]
            local infoNew=CheckAndGenUnitInfo(unitId,infoOld)
            Units[unitId]=infoNew
            return infoNew
        end
        o.UpdateUnit=UpdateUnit

        ---UpdateUnit foreach
        function o.UpdateAll()
            for udid, info in pairs(Units) do
                UpdateUnit(udid,info)
            end
        end

        ---pairs(Units)
        function o.Enum()
            return pairs(Units)
        end


        local Id=#UnitBags+1
        UnitBags[Id]=o
        o.Id=Id

        for _, fn in pairs(OnUnitBagNew) do
            fn(o,Id)
        end

        return o
    end
end