if WG.WackyBag.utils==nil then
    local utils={}
    WG.WackyBag.utils=utils
    function utils.DisableForSpec()
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
end
