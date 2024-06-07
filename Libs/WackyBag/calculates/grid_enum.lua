if WG.WackyBag.calculates.grid_enum==nil then
    ---@class point: [integer,integer]

    ---@class tuple_distance_pos: [number,point]
    
    local grid_enum={}
    WG.WackyBag.calculates.grid_enum=grid_enum
    grid_enum.datas={}
    local datas=grid_enum.datas

    local WackyBag=WG.WackyBag
    local priority_queue=WackyBag.collections.priority_queue
    local sqrt=math.sqrt

    -- ordered by distance, 1/8, points list
    ---@type list<tuple_distance_pos>
    datas.values={ {0,{0,0}} }
    datas.valuesCount=1

    ---@type priority_queue<tuple_distance_pos>
    datas.caches=priority_queue.new(
        ---comment
        ---@param a tuple_distance_pos
        ---@param b tuple_distance_pos
        ---@return boolean
        function (a,b)
            return (a[1]<b[1])
        end
    )

    datas.nextUpdateLine=1

    -- things in radius are calculated
    datas.calculatedDistance=0

    local function Extend1Line()
        local nextLine=datas.nextUpdateLine
        local xdist=nextLine+0.5
        local caches=datas.caches
        for y = 0,nextLine  do
            local ydist=y+0.5
            local dist=sqrt(xdist*xdist+ydist*ydist)
            caches:push({dist,{nextLine,y}})
        end
        datas.nextUpdateLine=datas.nextUpdateLine+1
        datas.calculatedDistance=nextLine+0.5
        while true do
            local n=caches:pop()
            datas.valuesCount=datas.valuesCount+1
            datas.values[datas.valuesCount]=n
            if(n[1]>=datas.calculatedDistance)then
                break
            end
        end
    end

    ---@param fn fun(dist:number,x:integer,y:integer):boolean
    local function ToOct(n,fn)
        local dist=n[1]
        local x0,y0=n[2][1],n[2][2]
        if not fn(dist,x0,y0) then return false end
        if x0~=0 then
            if not fn(dist,-x0,y0) then return false end--if not fn(dist,-x0,y0) then return false end
            if y0==0 then
                if not fn(dist,0,x0) then return false end
                if not fn(dist,0,-x0) then return false end
            end
        end
        if (y0 ~=0) then
            if not fn(dist,x0,-y0) then return false end
            if(x0~=0)then
                if not fn(dist,-x0,y0) then return false end
                if(x0~=y0) then
                    if not fn(dist,y0,x0) then return false end
                    if not fn(dist,y0,-x0) then return false end
                    if not fn(dist,-y0,x0) then return false end
                    if not fn(dist,-y0,-x0) then return false end
                end
            else
                if not fn(dist,y0,0) then return false end
                if not fn(dist,-y0,0) then return false end
            end
        end
        return true
    end

    ---comment
    ---@param fn fun(dist:number,x:integer,y:integer):boolean
    function grid_enum.EnumLoop(fn)
        local index=1
        while true do
            if(index>datas.valuesCount) then
                Extend1Line()
            end
            local n=datas.values[index]
            local res=ToOct(n,fn)
            if not res then
                break
            end
            index=index+1
        end
    end
end