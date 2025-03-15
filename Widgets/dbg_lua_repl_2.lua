
function widget:GetInfo()
	return {
		name      = "lua repl 2",
		desc      = "do lua",
		author    = "XNT",
		date      = "date",
		license   = "MIT",
		layer     = 0,
		enabled   = false,
	}
end


_G=getfenv()

local Chili

local Screen0

local ChWindow

local MainWindow

local fontSize = 12

local ChLabel

local ChEditBox


local EcoRatioCurLabel

local codebox

local resbox

local runbutton

local function pack(...)
	return select("#",...),{...}
end


local function dostring(str)
    local f,err=loadstring(str)
    if not f then
        return -1,err
    else
        setfenv(f,_G)
        local suc,res1,res2=pcall(function ()
            return pack(f())
        end)
        if not suc then
            return -2,res1
        else
            return res1,res2
        end
    end
end


local function RunCode()
    local code=codebox:GetText()
    if code then
        local result_str=""
        local c,res=dostring(code)
        if c==-1 then
            result_str="Failed to loadstring with error" .. res
        elseif c==-2 then
            result_str="Failed to call with error" .. res
        else
            for i = 1, c do
                result_str=result_str .. tostring( res[i] ) .. "; "
            end
        end
        resbox:SetCaption(result_str)
        Spring.Echo(result_str)
    else
        resbox:SetCaption("no code")
    end
end

function widget:Initialize()
    
    Chili=WG.Chili
    Screen0=Chili.Screen0
    ChWindow=Chili.Window
    ChLabel=Chili.Label
    ChEditBox=Chili.EditBox
    MainWindow=ChWindow:New{
        classname = "main_window_small_tall",
		name      = 'Lua Repl',
		x         =  50,
		y         = 150,
		width     = 500,
		height    = 80,
		padding = {16, 8, 16, 8},
		dockable  = true,
		dockableSavePositionOnly = true,
		draggable = true,
		resizable = true,
		tweakResizable = true,
		parent = Screen0,
    }

    codebox=ChEditBox:New{
        parent=MainWindow,
		x         =  8,
		y         = 8,
        right=8,

    }

    resbox=ChLabel:New{
        parent=MainWindow,
        y=60,x=8,
		autosize=true,
        valign="top",
    }

    runbutton=Chili.Button:New{
        parent=MainWindow,
        y=32,x=8,
        OnClick={RunCode}
    }

end