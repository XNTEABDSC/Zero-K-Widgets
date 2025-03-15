if WG.WackyBag.utils.ForWidget==nil then
    WG.WackyBag.utils.ForWidget=function (widget)
        local o={}
        local widgetHandler=widget.widgetHandler
        function o.DisableForSpec()
            --local testGet=getfenv(1).widgetHandler
            --Spring.Echo("DisableForSpec Autoget: " .. tostring(testGet) .. "Eq: ".. tostring(testGet==widgetHandler))
            if Spring.GetSpectatingState() then
                widgetHandler:RemoveWidget()
                return true
            end
            return false
        end
        
        local spGiveOrderToUnit = Spring.GiveOrderToUnit
        local spGiveOrder=Spring.GiveOrder

        local function GiveNotifyingOrder(cmdID, cmdParams, cmdOpts)
            if widgetHandler:CommandNotify(cmdID, cmdParams, cmdOpts) then
                return
            end
            spGiveOrder(cmdID, cmdParams, cmdOpts.coded)
        end
        o.GiveNotifyingOrder=GiveNotifyingOrder
        
        local function GiveNotifyingOrderToUnit(uID, cmdID, cmdParams, cmdOpts)
            if widgetHandler:UnitCommandNotify(uID, cmdID, cmdParams, cmdOpts) then
                return
            end
            spGiveOrderToUnit(uID, cmdID, cmdParams, cmdOpts.coded)
        end
        o.GiveNotifyingOrderToUnit=GiveNotifyingOrderToUnit
        return o
    end
end