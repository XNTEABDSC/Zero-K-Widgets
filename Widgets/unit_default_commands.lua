function widget:GetInfo() return {
	name = "Misc default command replacements",
	desc = "Implements some right-click behaviour options",
	license = "Public Domain",
	layer = 0,
	enabled = Script.IsEngineMinVersion(104, 0, 53), -- 53 on maintenance branch, 211 on develob
} end

VFS.Include("LuaRules/Configs/customcmds.h.lua") -- for CMD_RAW_MOVE

options_path = 'Settings/Unit Behaviour'
options = {
	guard_facs = {
		name = "Right click guards factories",
		type = "bool",
		value = true,
		desc = "If enabled, rightclicking a factory will always Guard it.\nIf disabled, the command can be Repair.",
		noHotkey = true,
	},
	guard_cons = {
		name = "Right click guards constructors",
		type = "bool",
		value = true,
		desc = "If enabled, rightclicking a constructor will always Guard it.\nIf disabled, the command can be Repair.",
		noHotkey = true,
	},
	set_target_instead_of_attack = {
		name = "Right click sets target instead of attacking",
		type = "bool",
		value = false,
		desc = "If enabled, rightclicking an enemy will give the Set Target command.\nIf disabled, the command is Attack.",
		noHotkey = true,
	},
	default_amove={
		name = "Right click A MOVE instead of move",
		type = "bool",
		value = false,
		desc = "If enabled, rightclicking will be AMOVE instead of brainless move",
		noHotkey = true,
	}
}

local cons, facs = {}, {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isMobileBuilder then
		cons[unitDefID] = true
	end
	if unitDef.isFactory then
		facs[unitDefID] = true
	end
end

local spGetModKeyState = Spring.GetModKeyState
local spGetInvertQueueKey = Spring.GetInvertQueueKey
local spGetMouseState=Spring.GetMouseState
local function GetModKeys()

	local alt, ctrl, meta, shift = spGetModKeyState()

	if spGetInvertQueueKey() then -- Shift inversion
		shift = not shift
	end

	return alt, ctrl, meta, shift
end

local function ChooseAMove(unitID)
	if not options.default_amove.value then
		return
	end
	local alt, ctrl, meta, shift = GetModKeys()
	if alt or meta then
		--Spring.Echo("alt or meta")
		return
	end

	local _,_,leftPressed,middlePressed,rightPressed=spGetMouseState()
	if leftPressed or middlePressed or not rightPressed then
		--Spring.Echo("mouse")
		return
	end
	return CMD.FIGHT
end

local handlersForUnitTarget = {
	[CMD.RECLAIM] = function (unitID)
		if (select(5, Spring.GetUnitHealth(unitID)) or 1) < 1 then
			return
		end

		return CMD_RAW_MOVE
	end,

	[CMD.REPAIR] = function (unitID)
		if select(5, Spring.GetUnitHealth(unitID)) < 1 then
			return
		end

		local unitDefID = Spring.GetUnitDefID(unitID)
		if cons[unitDefID] and options.guard_cons.value
		or facs[unitDefID] and options.guard_facs.value
		then
			return CMD.GUARD
		end
	end,

	[CMD.ATTACK] = function (unitID)
		if options.set_target_instead_of_attack.value then
			return CMD_UNIT_SET_TARGET
		end
	end,
}
local handlersForEmptyTarget={
	[CMD.MOVE] = ChooseAMove,
	[CMD_RAW_MOVE]=ChooseAMove
}
function widget:DefaultCommand(targetType, targetID, engineCmd)
	if targetType == "unit" then
		if handlersForUnitTarget[engineCmd] then
			return handlersForUnitTarget[engineCmd](targetID)
		end
	elseif targetType==nil then
		if handlersForEmptyTarget then
			return handlersForEmptyTarget[engineCmd]()
		end
	end

end
