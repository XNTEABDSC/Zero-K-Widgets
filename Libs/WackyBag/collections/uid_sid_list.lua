if WG.WackyBag.collections.uid_sid_list==nil then
    local uid_sid_list={}
    local unordered_list=WG.WackyBag.collections.unordered_list
    WG.WackyBag.collections.uid_sid_list=uid_sid_list


    uid_sid_list.metatable={}
    uid_sid_list.metatable.__index=function (tb,index)
        if(index=="count")then
            return tb.SIdToUIdList.count
        else
            return uid_sid_list.metatable[index]
        end
    end
    ---@class uid_sid_list
    ---@field UIdToSIdList list<integer|nil>
    ---@field SIdToUIdList unordered_list<integer>
    ---@field count integer
    ---@field add fun(uid_sid_list,integer):integer
    ---@field remove fun(uid_sid_list,integer,integer)
    ---@field removeByUId fun(uid_sid_list,integer):integer
    ---@field removeBySId fun(uid_sid_list,integer):integer
    ---@field enum (fun(uid_sid_list):(fun():(integer,integer)))

    ---@param o any
    ---@return uid_sid_list
    function uid_sid_list.new(o)
        o=o or {}
        setmetatable(o,uid_sid_list.metatable)
        o.UIdToSIdList={}
        o.SIdToUIdList=unordered_list.new()
        return o
    end

    ---@param self uid_sid_list
    ---@param uid integer
    ---@return integer sid
    function uid_sid_list.metatable:add(uid)
        self.count=self.count+1
        self.UIdToSIdList[uid]=self.count
        self.SIdToUIdList:add(uid)
        return self.count
    end

    ---@param self uid_sid_list
    ---@param uid integer
    ---@param sid integer
    function uid_sid_list.metatable:remove(uid,sid)
        self.UIdToSIdList[uid]=nil
        self.SIdToUIdList:remove(sid)
    end

    ---@param self uid_sid_list
    ---@param uid integer
    ---@return integer sid
    function uid_sid_list.metatable:removeByUId(uid)
        local sid=self.UIdToSIdList[uid]
        ---@cast sid integer
        self:remove(uid,sid)
        return sid
    end

    ---@param self uid_sid_list
    ---@param sid integer
    ---@return integer uid
    function uid_sid_list.metatable:removeBySId(sid)
        local uid=self.SIdToUIdList[sid]
        self:remove(uid,sid)
        return uid
    end

    ---@param self uid_sid_list
    ---@return fun():(integer,integer)
    function uid_sid_list.metatable:enum()
        return self.SIdToUIdList:enum()
    end

end