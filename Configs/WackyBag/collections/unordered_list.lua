if WG.WackyBag.collections.unordered_list==nil then

    ---@class unordered_list<T>:{ [integer]:T,count:integer,items:{[integer]:T}, add:(fun(self:unordered_list<T>,item:T):integer),remove:(fun(self:unordered_list<T>,index:integer):T)}
    local unordered_list= {}
    WG.WackyBag.collections.unordered_list=unordered_list

    unordered_list.metatable={}
    unordered_list.metatable.__index=function (tb,index)
        if(type(index)=="number")then
            return tb.items[index]
        else
            return unordered_list.metatable[index]
        end
    end

    ---@generic T
    ---@param o any
    ---@return unordered_list<T>
    function unordered_list.new(o)
        o=o or {}
        o.items ={}
        o.count=0
        setmetatable(o,unordered_list.metatable)
        return o
    end

    ---@generic T
    ---@param self unordered_list<T>
    ---@param item T
    ---@return integer
    function unordered_list.metatable:add(item)
        self.count=self.count+1
        self.items[self.count]=item
        return self.count
    end

    ---@generic T
    ---@param self unordered_list<T>
    ---@param index integer
    ---@return T
    function unordered_list.metatable:remove(index)
        local res=self.items[index]
        self.items[index]=self.items[self.count]
        self.count=self.count-1
        return res
    end

end