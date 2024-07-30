function widget:GetInfo()
	return {
		name      = "test",
		desc      = "test sth",
		author    = "XNT",
		date      = "date",
		license   = "",
		layer     = math.huge,
		enabled   = false,
	}
end
local spEcho=Spring.Echo

-- "lupsProjectiles_AddProjectile"


VFS.Include("LuaUI/Libs/WackyBagToWG.lua")
local WackyBag=WG.WackyBag

local MY_G=getfenv(loadstring(""))

function widget:Initialize()
	MY_G.lupsProjectiles_AddProjectile=function ()
		spEcho("game_message: " .. "AHAHAHA")
	end

	

end

local flag=120


function widget:GameFrame()
	--spEcho("game_message: " .. tostring( widgetHandler.globals ))
	if true and false then
		
		spEcho("TEST START")
		--[[
		--WackyBag.utils.PrintTable(MY_G)
		spEcho("TEST _G")
		WackyBag.utils.PrintTable(MY_G)

		for key, value in pairs(MY_G) do
			if tostring(value) == "lupsProjectiles_AddProjectile" then
				spEcho("TEST value Type: " .. type(value))

				spEcho("TEST key table")
				WackyBag.utils.PrintTable(key)--:GetInfo()
				spEcho("TEST key table widget")
				WackyBag.utils.PrintTable(key.widget)
				spEcho("TEST key table widget getinfo")
				WackyBag.utils.PrintTable(key.widget:GetInfo())
			end
		end
		
		spEcho("TEST widgetHandler")
		WackyBag.utils.PrintTable(widgetHandler)
		]]

		local list=Spring.GetVisibleProjectiles()
		--[[
		for i = 1, 10000 do
			if Spring.GetProjectileOwnerID(i)~=nil then
				list[#list+1] = i
			end
		end
		]]

		for key, value in pairs(list) do
			local x,y,z=Spring.GetProjectilePosition(value)
			spEcho("(" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. ")")
			Spring.MarkerAddPoint(x,y,z,"AHAHAHA",false)
		end
		spEcho("TEST END")
		flag=flag+0
	end
	flag=flag-1
end