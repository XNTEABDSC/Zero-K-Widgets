--"LuaUI/Libs/WackyBagToWG.lua"
if (WG.WackyBag==nil) then
    
    local WackyBag={}
    WG.WackyBag = WackyBag
    WackyBag.path="LuaUI/Libs/WackyBag/"
    VFS.Include(WackyBag.path .. "utils.lua")
    WackyBag.collections={}
    --WackyBag.collections.priority_queue = VFS.Include(WackyBag.path .. "collections/priority_queue.lua")
    VFS.Include(WackyBag.path .. "collections/priority_queue.lua")
    VFS.Include(WackyBag.path .. "collections/unordered_list.lua")
    VFS.Include(WackyBag.path .. "collections/uid_sid_list.lua")
    WackyBag.structures={}
    WackyBag.calculates={}
    --WackyBag.calculates.grid_enum = VFS.Include(WackyBag.path .. "calculates/grid_enum.lua")
    VFS.Include(WackyBag.path .. "calculates/grid_enum.lua")
    VFS.Include(WackyBag.path .. "calculates/convolution.lua")
    
end
return WG.WackyBag
---@class list<T>:{[integer]:T}
---@class color:{[1]:number,[2]:number,[3]:number,[4]:number}