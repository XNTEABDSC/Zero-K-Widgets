if WG.WackyBag.utils.get_proj==nil then
    local get_proj={}
    WG.WackyBag.utils.get_proj=get_proj
    local spGetProjectilesInRectangle=Spring.GetProjectilesInRectangle
    local EmptyTable={}
    
    ---@return list<ProjectileId>
    function WG.WackyBag.utils.get_proj.GetProjectiles()
        return spGetProjectilesInRectangle(0,0,Game.mapSizeX,Game.mapSizeZ,false,true) or EmptyTable
    end
    local wbGetProjectiles=WG.WackyBag.utils.get_proj.GetProjectiles
    local GameFrame=0
    local list={}
    local spGetGameFrame=Spring.GetGameFrame
    
    ---@return list<ProjectileId>
    function get_proj.GetProjList(curframe)
        curframe=curframe or Spring.GetGameFrame()
        if(curframe>GameFrame)then
            list=wbGetProjectiles()
        end
        return list
    end
end