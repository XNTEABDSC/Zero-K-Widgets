
WG={}

VFS={}

Spring={}

widget={}
widgetHandler={}
Game={}
Game.mapSizeX=1
Game.mapSizeZ=1
Game.gameSpeed=30

VFS.Include=function (filename)
    return dofile("D:/Program Files (x86)/Steam/steamapps/common/Zero-K/" .. filename)
end

VFS.Include("LuaUI/Libs/WackyBagToWG.lua")

local WackyBag=WG.WackyBag

local priority_queue=WackyBag.collections.priority_queue

---@type priority_queue<number>
local tqueue=priority_queue.new()

tqueue:push(10)
tqueue:push(5)

tqueue:push(6)
tqueue:push(3)
tqueue:push(7)

for i in tqueue:enum() do
    print(i)
end


local grid_enum=WackyBag.calculates.grid_enum
grid_enum.EnumLoop(function (dist,x,y)
    print( string.format("dist:%f, xy:(%d,%d)",dist,x,y) )
    return dist<10
end)