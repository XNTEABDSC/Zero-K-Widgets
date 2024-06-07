if WG.SafeZone==nil then


    VFS.Include("LuaUI/Libs/WackyBagToWG.lua")

    local WackyBag=WG.WackyBag
    local spGetUnitDefID=Spring.GetUnitDefID
    local spGetUnitPosition=Spring.GetUnitPosition
    local spIsUnitAllied        = Spring.IsUnitAllied
    local spGetSpectatingState  = Spring.GetSpectatingState
    local spMarkerAddPoint=Spring.MarkerAddPoint
    local spMarkerErasePosition=Spring.MarkerErasePosition
    local spEcho=Spring.Echo
    local spGetMyTeamID=Spring.GetMyTeamID
    local spValidUnitID = Spring.ValidUnitID
    ---@type framePerSec
    local FramePerSecond=30
    local spGetGroundHeight = Spring.GetGroundHeight
    local spIsPosInRadar		= Spring.IsPosInRadar
    
    --local SafeZone.GridSizeUnit=512
    local MapWidth, MapHeight = Game.mapSizeX, Game.mapSizeZ
    local SafeZone={}
    
    ---@class gridX:integer
    ---@class gridZ:integer

    --- Store where is safe<br>
    --- The world are splited into rectangles.<br>
    --- (SafeZone.SafeZoneGrid[gx][gz].DangerTime - SafeZone.GameTime) shows whether the grid is danger
    WG.SafeZone=SafeZone
    --- edge length of rectangles
    SafeZone.GridSize=256
    --- width,height count of rectangles
    SafeZone.GridWitdh,SafeZone.GridHeight=MapWidth/SafeZone.GridSize,MapHeight/SafeZone.GridSize
    --- current frame, (historical reasons: I d k Spring.GetGameFrame)
    ---@type frame
    SafeZone.GameTime=0
    --- how fast do 'danger' spread. in frame
    ---@type frame
    SafeZone.DangerSpreadTime=5*FramePerSecond
    ---@type frame
    --- set when a grid is danger. in frame
    SafeZone.DangerInitTime=10*FramePerSecond
    --- when the grid is safe. in frame
    ---@type frame
    SafeZone.SafeTime=-10*FramePerSecond
    
    --- from world pos to its grid pos
    ---@param x WldxPos
    ---@param z WldzPos
    ---@return gridX
    ---@return gridZ
    function SafeZone.PosToGrid(x,z)
        if x==0 then
            x=1
        end
        if z==0 then
            z=1
        end
        ---@diagnostic disable-next-line: return-type-mismatch
        return math.ceil(x/SafeZone.GridSize),math.ceil(z/SafeZone.GridSize)
    end

    --- chech whether a grid pos is valid
    ---@param gx gridX
    ---@param gz gridZ
    ---@return boolean
    function SafeZone.ValidGridPos(gx,gz)
        return gx~=nil and gx>=1 and gx<=SafeZone.GridWitdh and gz ~=nil and gz>=1 and gz<=SafeZone.GridHeight
    end

    --- get unit's world pos and grid position
    ---@param unitID unitId
    ---@return WldxPos
    ---@return WldzPos
    ---@return gridX
    ---@return gridZ
    function SafeZone.UnitPosGridPos(unitID)
        local ux,_,uz=spGetUnitPosition(unitID)
        local ugx,ugz=SafeZone.PosToGrid(ux,uz)
        return ux,uz,ugx,ugz
    end

    --- from grid pos to grid's center world pos
    ---@param gx gridX
    ---@param gz gridZ
    ---@return WldxPos
    ---@return WldzPos
    function SafeZone.GridPosToCenter(gx,gz)
        ---@diagnostic disable-next-line: return-type-mismatch
        return (gx-1)*SafeZone.GridSize+(SafeZone.GridSize/2),(gz-1)*SafeZone.GridSize+(SafeZone.GridSize/2)
    end

    --- whether a grid is safe
    function SafeZone.GridSafeState(obj)
        if(obj.DangerTime>SafeZone.GameTime) then
            return 1,"Danger"
        elseif obj.DangerTime-SafeZone.GameTime>SafeZone.SafeTime then
            return 2,"Peace"
        else 
            return 3,"Safe"
        end
    end

    ---@class SafeZoneGridObj
    ---@field DangerTime frame

    --- stores state of grid<br>
    --- SafeZoneGrid[gx][gz]={DangerTime}
    ---@type {[gridX]:{[gridZ]:SafeZoneGridObj}}
    SafeZone.SafeZoneGrid={}
    ---@type {[gridX]:{[gridZ]:SafeZoneGridObj}}
    SafeZone.SafeZoneGridCache={}
    
    ---@return SafeZoneGridObj
    local function CreateSafeZoneGridObj()
        return {
            DangerTime=0
        }
    end

    function SafeZone.InitGrid()
        for gx = 1,SafeZone.GridWitdh  do
            ---@cast gx gridX
            SafeZone.SafeZoneGrid[gx]={}
            SafeZone.SafeZoneGridCache[gx]={}
            local gridx=SafeZone.SafeZoneGrid[gx]
            local gridx2=SafeZone.SafeZoneGridCache[gx]
            for gy = 1,SafeZone.GridHeight  do
                ---@cast gx gridZ
                gridx[gy]=CreateSafeZoneGridObj()
                gridx2[gy]=CreateSafeZoneGridObj()
            end
        end
    end

    --- update grids DangerTime, <br>
    --- DangerTime will be > neighborhoods'DangerTime - SafeZone.DangerSpreadTime, <br>
    --- and > slope neighborhoods'DangerTime - SafeZone.DangerSpreadTime/1.414
    function SafeZone.GridUpdate()
        local DangerSpreadTime=SafeZone.DangerSpreadTime
        local DangerSpreadFrameTime=DangerSpreadTime
        local DangerSpreadFrameTimeSlope=DangerSpreadFrameTime/1.414
        for gx = 1,SafeZone.GridWitdh  do
            local gridx2=SafeZone.SafeZoneGridCache[gx]
            for gz = 1,SafeZone.GridHeight  do
                local max=SafeZone.SafeZoneGrid[gx][gz].DangerTime
                local n
                if(gx>1) then
                    n=SafeZone.SafeZoneGrid[gx-1][gz].DangerTime-DangerSpreadFrameTime
                    if(max <n)then
                        max=n
                    end

                    if(gz>1) then
                        n=SafeZone.SafeZoneGrid[gx-1][gz-1].DangerTime-DangerSpreadFrameTimeSlope
                        if(max <n)then
                            max=n
                        end
                    end
                    if(gz<SafeZone.GridHeight) then
                        n=SafeZone.SafeZoneGrid[gx-1][gz+1].DangerTime-DangerSpreadFrameTimeSlope
                        if(max <n)then
                            max=n
                        end
                    end
                end
                if(gx<SafeZone.GridWitdh) then
                    n=SafeZone.SafeZoneGrid[gx+1][gz].DangerTime-DangerSpreadFrameTime
                    if(max <n)then
                        max=n
                    end
                    if(gz>1) then
                        n=SafeZone.SafeZoneGrid[gx+1][gz-1].DangerTime-DangerSpreadFrameTimeSlope
                        if(max <n)then
                            max=n
                        end
                    end
                    if(gz<SafeZone.GridHeight) then
                        n=SafeZone.SafeZoneGrid[gx+1][gz+1].DangerTime-DangerSpreadFrameTimeSlope
                        if(max <n)then
                            max=n
                        end
                    end
                end
                if(gz>1) then
                    n=SafeZone.SafeZoneGrid[gx][gz-1].DangerTime-DangerSpreadFrameTime
                    if(max <n)then
                        max=n
                    end
                end
                if(gz<SafeZone.GridHeight) then
                    n=SafeZone.SafeZoneGrid[gx][gz+1].DangerTime-DangerSpreadFrameTime
                    if(max <n)then
                        max=n
                    end
                end
                gridx2[gz].DangerTime=max
            end
        end
        local temp=SafeZone.SafeZoneGridCache
        SafeZone.SafeZoneGrid=SafeZone.SafeZoneGridCache
        SafeZone.SafeZoneGridCache=temp
    end

    ---@param gx gridX
    ---@param gz gridZ
    ---@return frame
    function SafeZone.GetZoneDangerTime(gx,gz)
        return SafeZone.SafeZoneGrid[gx][gz].DangerTime-SafeZone.GameTime
    end

    ---@param gx gridX
    ---@param gz gridZ
    ---@param time frame
    function SafeZone.SetZoneDangerTime(gx,gz,time)
        SafeZone.SafeZoneGrid[gx][gz].DangerTime=time+SafeZone.GameTime
    end

    ---@param gx gridX
    ---@param gz gridZ
    ---@param time frame
    function SafeZone.SetZoneDangerTimeUpTo(gx,gz,time)
        local realTime=time+SafeZone.GameTime
        if(SafeZone.SafeZoneGrid[gx][gz].DangerTime<realTime) then
            SafeZone.SafeZoneGrid[gx][gz].DangerTime=realTime
        end
        
    end

    --- set zone to be danger
    ---@param gx gridX
    ---@param gz gridZ
    function SafeZone.SetZoneDanger(gx,gz)
        SafeZone.SetZoneDangerTimeUpTo(gx,gz,SafeZone.DangerInitTime)
    end

    --- update frequency of watch danger units, in frame
    ---@type frame
    SafeZone.WatchDangerUnitsTimeDelta=6

    --- danger units, register when in radar, update per SafeZone.WatchDangerUnitsTimeDelta, set their grid pos to danger
    SafeZone.WatchDangerUnits={}
    function SafeZone.CreateWatchUnit(unitID)
        local posX,posY,posZ=spGetUnitPosition(unitID)
        return{
            id=unitID,
            posX=posX,
            posY=posY,
            posZ=posZ
        }
    end
    --- find closest SafeZone where DangerTime-GameTime < safetime
    ---@param gx gridX
    ---@param gz gridZ
    ---@param safetime frame
    ---@return gridX|nil,gridZ|nil
    function SafeZone.FindClosestSafeZone(gx,gz,safetime)
        safetime=(safetime or SafeZone.SafeTime)
        local maxDist=(SafeZone.GridHeight+SafeZone.GridWitdh)*SafeZone.GridSize
        local newx,newz=nil,nil
        local enumFn=function (dist,dx,dz)
            if(dist>=maxDist) then
                return false
            end
            local rx,rz=gx+dx,gz+dz
            if not SafeZone.ValidGridPos(rx,rz) then
                return true
            end
            local time= SafeZone.SafeZoneGrid[rx][rz].DangerTime-SafeZone.GameTime
            if time<safetime then
                newx,newz=rx,rz
                return false
            end
            return true
        end
        WackyBag.calculates.grid_enum.EnumLoop(enumFn)
        return newx,newz
    end

    ---@return fun():(gridX,gridZ)
    function SafeZone.EnumGrid()
        local x,z=1,1
        return function()
            if x == SafeZone.GridWitdh then
                if z == SafeZone.GridHeight then
                    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
                    return nil
                else
                    z=z+1
                    x=1
                end
            else
                x=x+1
            end
            
            ---@diagnostic disable-next-line: return-type-mismatch
            return x,z
        end
    end

end
return WG.SafeZone