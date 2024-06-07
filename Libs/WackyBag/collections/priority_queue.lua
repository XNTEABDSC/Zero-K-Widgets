if WG.WackyBag.collections.priority_queue==nil then
    
    ---@class priority_queue<T>: {[integer]:T, items:{[integer]:T},count:integer,comp: (fun(a:T,b:T):boolean) , push:fun(self:priority_queue<T>,item:T) , pop:(fun(self:priority_queue<T>):T) , enum:(fun(self:priority_queue<T>):fun():(T|nil)) }
    --[[
    ---@class priority_queue<T>
    ---@field count integer
    ---@field comp fun(a:T,b:T):boolean
    ---@field push fun(self:priority_queue, item:T)
    ---@field pop fun(self:priority_queue):T
    ---@field enum fun(self:priority_queue):fun():T
    ---@field items {[integer]:T}
    ]]
     --[[
    ---@class priority_queue
    ---@field count integer
    ---@field comp fun(a:any,b:any):boolean
    ---@field push fun(self:priority_queue, item:any)
    ---@field pop fun(self:priority_queue):any
    ---@field enum fun(self:priority_queue):fun():any
    ---@field items {[integer]:any}
     --]]

    ---@type {new:fun():priority_queue}

    local priority_queue= {}
    WG.WackyBag.collections.priority_queue=priority_queue
    priority_queue.metatable={}
    priority_queue.metatable.__index=function (tb,index)
        if(type(index)=="number")then
            return tb.items[index]
        else
            return priority_queue.metatable[index]
        end
    end

    ---@generic T
    ---@param comp (fun(a:T,b:T):boolean)|nil
    ---@param o any|nil
    ---@return priority_queue<T>
    function priority_queue.new(comp,o)
        comp=comp or function(a,b)
            return a<b
        end
        o=o or {}
        o.count=0
        o.items={}
        o.comp=comp
        --[[
        ---@type priority_queue
        o={
            count=0,
            items={},
            comp=comp
        }]]
        setmetatable(o,priority_queue.metatable)
        ---@cast o priority_queue<string>
        
        return o
    end

    --[[
    ---@param self priority_queue
    function priority_queue:__index(i)
        return self.items[i]
    end
    ]]

    ---@generic T
    ---@param self priority_queue<T>
    function priority_queue.metatable:push(item)
        local current_index=self.count+1
        while current_index~=1 do
            local prev
            if(current_index%2==1) then
                prev=(current_index-1)/2
            else
                prev=current_index/2
            end
            if self.comp(self.items[prev],item) then
                break
            else
                self.items[current_index]=self.items[prev]
                current_index=prev
            end
        end
        self.items[current_index]=item
        self.count=self.count+1
    end

    ---@generic T
    ---@param self priority_queue<T>
    function priority_queue.metatable:pop()
        
        if self.count==0 then
            return nil
        end

        local comp=self.comp
        local items=self.items
        local res=items[1]
        local current_index=1
        local moved=items[self.count]
        items[self.count]=nil
        self.count=self.count-1

        while true do
            local son1=current_index*2
            local son2=son1+1
            if(son2>self.count) then
                if(son1>self.count) then
                else
                    if(comp(items[son1],moved))then
                        items[current_index]=items[son1]
                    end
                end
                break
            end
            local goto_index=son2
            if(comp(moved,items[son1])) then
                if(comp(moved,items[son2]))then
                    break
                else
                    --goto_index=son2
                end
            else
                if(comp(moved,items[son2]))then
                    goto_index=son1
                else
                    if comp(items[son1],items[son2]) then
                        goto_index=son1
                    else
                        --goto_index=son2
                    end
                end
            end
            items[current_index]=items[goto_index]
            current_index=goto_index
        end
        items[current_index]=moved
        return res
    end

    ---@generic T
    ---@param self priority_queue<T>
    function priority_queue.metatable:enum()
        local comp=self.comp
        local items=self.items
        
        local order_queue=priority_queue.new(function (index1,index2)
            return comp(items[index1],items[index2])
        end)

        if (self.count==0) then

            return
            function ()

            end

        end

        order_queue:push(1)
        
        return function()
            local current=order_queue:pop()
            if(current==nil) then
                return nil
            end
            local son1=current*2
            if son1<=self.count then
                order_queue:push(son1)
                if son1+1<=self.count then
                    order_queue:push(son1+1)
                end
            end
            return items[current]
        end
    end
end