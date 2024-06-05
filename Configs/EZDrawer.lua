if(WG.EZDrawer==nil) then
    VFS.Include("LuaUI/Configs/WackyBagToWG.lua")
    local EZDrawer={}
    WG.EZDrawer=EZDrawer
    local unordered_list=WG.WackyBag.collections.unordered_list
    ---@type unordered_list<Drawer>
    local datas=unordered_list.new()
    EZDrawer.datas=datas


    local GL_QUADS = GL.QUADS
    local GL_LINES=GL.LINES
    local glLineWidth = gl.LineWidth
    local glColor = gl.Color
    local glBeginEnd = gl.BeginEnd
    local glVertex = gl.Vertex
    local spGetGameFrame=Spring.GetGameFrame

    ---@alias Drawer fun():boolean

    ---@class TimedDrawer
    ---@field fn fun(timeLeft:integer,timeMax:integer):(boolean|nil)
    ---@field timeMark integer
    ---@field timeMax integer

    ---@type unordered_list<Drawer>
    datas.Drawers=unordered_list.new()

    function EZDrawer.Add(Drawer)
        datas.Drawers:add(Drawer)
    end

    local DrawerTemplates={}
    EZDrawer.DrawerTemplates=DrawerTemplates

    ---@return Drawer
    function DrawerTemplates.DrawOnce(fn)
        return function ()
            fn()
            return false
        end
    end

    ---@param fn fun(scale:number):(boolean|nil)
    ---@return fun(timeLeft:integer,timeMax:integer):(boolean|nil)
    function DrawerTemplates.TimedScale(fn)
        return function (tl,tm)
            return fn(tl/tm)
        end
    end

    ---@param fn fun(timeLeft:integer,timeMax:integer):(boolean|nil)
    function DrawerTemplates.DrawTimed(fn,timeMax)
        return DrawerTemplates.TimedDrawerToDrawer({
            fn=fn,
            timeMax=timeMax,
            timeMark=timeMax+spGetGameFrame()
        })
    end

    ---@param TimedDrawer TimedDrawer
    ---@return Drawer
    function DrawerTemplates.TimedDrawerToDrawer(TimedDrawer)
        return function ()
            local timeLeft=TimedDrawer.timeMark-spGetGameFrame()
            if(timeLeft<0) then
                return false
            else
                local res= TimedDrawer.fn(timeLeft,TimedDrawer.timeMax)
                if(res==nil)then res=true end
                return res
            end
        end
    end


    function DrawerTemplates.DrawLine (x1,y1,z1,x2,y2,z2,color,linewidth)
        glLineWidth(linewidth)
        glColor(color[1],color[2],color[3],color[4])
        glBeginEnd(GL_LINES,function ()
            glVertex(x1,y1,z1)
            glVertex(x2,y2,z2)
        end)
    end
    ---draw a vector
    ---@param x1 number
    ---@param y1 number
    ---@param z1 number
    ---@param x2 number
    ---@param y2 number
    ---@param z2 number
    ---@param color color
    ---@param linewidth number
    ---@param arrLenRatio number
    function DrawerTemplates.DrawVecVer (x1,y1,z1,x2,y2,z2,color,linewidth,arrLenRatio)
        
        local arrLenRatiorev=1-arrLenRatio
        local arry=(y2-y1)*arrLenRatiorev+y1
        local arrx=(x2-x1)*arrLenRatiorev+x1
        local arrz=(z2-z1)*arrLenRatiorev+z1
        local arrdltx,arrdltz=(z2-z1)*arrLenRatio,-(x2-x1)*arrLenRatio

        glLineWidth(linewidth)
        glColor(color[1],color[2],color[3],color[4])
        glBeginEnd(GL_LINES,function ()
            glVertex(x1,y1,z1)
            glVertex(x2,y2,z2)

            glVertex(x2,y2,z2)
            glVertex(arrx+arrdltx,arry,arrz+arrdltz)

            glVertex(x2,y2,z2)
            glVertex(arrx-arrdltx,arry,arrz-arrdltz)
        end)
    end
end