if WG.WackyBag.collections.unordered_list==nil then
    --- when remove one, the latest will be moved to the vacancy
   local unordered_list= {}
    WG.WackyBag.collections.unordered_list=unordered_list

    unordered_list.metatable={}
    unordered_list.metatable.__index=function (tb,index)
        return unordered_list.metatable[index]
    end
    ---@class unordered_list<T>:{ [integer]:T,count:integer, add:(fun(self:unordered_list<T>,item:T):integer),remove:(fun(self:unordered_list<T>,index:integer):T),enum:(fun(self:unordered_list<T>):(fun():(T,integer)))}
    ---@generic T
    ---@param o any
    ---@return unordered_list<T>
    function unordered_list.new(o)
        o=o or {}
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
        self[self.count]=item
        return self.count
    end

    ---@generic T
    ---@param self unordered_list<T>
    ---@param index integer
    ---@return T
    function unordered_list.metatable:remove(index)
        local res=self[index]
        self[index]=self[self.count]
        self.count=self.count-1
        return res
    end

    ---@generic T
    ---@param self unordered_list<T>
    ---@return fun():(T,integer)
    function unordered_list.metatable:enum()
        local id=0
        return function ()
            id=id+1
            if (id>self.count) then
                return nil
            end
            return self[id],id
        end
    end
end