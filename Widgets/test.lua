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

function widget:Initialize()
    if(package ~=nil) then
        spEcho(package.path)
    end
    spEcho(require)
end