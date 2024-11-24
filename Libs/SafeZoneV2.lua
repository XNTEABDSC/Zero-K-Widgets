if WG.SafeZoneV2==nil then
    VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
    local WackyBag=WG.WackyBag
    local SafeZoneV2={}
    WG.SafeZoneV2=SafeZoneV2
    local MapWidth, MapHeight = Game.mapSizeX, Game.mapSizeZ
    local GridSize=256
    SafeZoneV2.GridSize=GridSize
    ---@class gridX:integer
    ---@class gridZ:integer
    ---@type gridX
---@diagnostic disable-next-line: assign-type-mismatch
    local GridWitdh=MapWidth/SafeZoneV2.GridSize
    SafeZoneV2.GridWitdh=GridWitdh
    ---@type gridZ
---@diagnostic disable-next-line: assign-type-mismatch
    local GridHeight=MapHeight/SafeZoneV2.GridSize
    SafeZoneV2.GridHeight=GridHeight
    
    --- from world pos to its grid pos
    ---@param x WldxPos
    ---@param z WldzPos
    ---@return gridX
    ---@return gridZ
    local function PosToGrid(x,z)
        if x==0 then
            x=0.1
        end
        if z==0 then
            z=0.1
        end
        ---@diagnostic disable-next-line: return-type-mismatch
        return math.ceil(x/GridSize),math.ceil(z/GridSize)
    end
    SafeZoneV2.PosToGrid=PosToGrid

    
    ---@param gx gridX
    ---@param gz gridZ
    ---@return boolean
    local function ValidGridPos(gx,gz)
        return gx~=nil and gx>=1 and gx<=GridWitdh and gz ~=nil and gz>=1 and gz<=GridHeight
    end

    SafeZoneV2.ValidGridPos=ValidGridPos

    local GridPosToCenter
    do
        local GridSizeHalf=GridSize/2
        ---@param gx gridX
        ---@param gz gridZ
        ---@return WldxPos
        ---@return WldzPos
        GridPosToCenter= function (gx,gz)
            ---@diagnostic disable-next-line: return-type-mismatch
            return gx*GridSize-GridSizeHalf,gz*GridSize-GridSizeHalf
        end
    end

    SafeZoneV2.GridPosToCenter=GridPosToCenter

    ---@type {[gridX]:{[gridZ]:number}}
    local UnitValueGrid={}

    local function Init()
        for x = 1, GridWitdh do
            local newLine={}
            UnitValueGrid[x]=newLine
            for z = 1, GridHeight do
                newLine[z]=0
            end
        end
    end
    SafeZoneV2.Init=Init

    
end