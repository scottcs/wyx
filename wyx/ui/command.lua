local command = {}

-- check if a given command is valid
local iscommand = function(cmd) return command[cmd] ~= nil end

-- get a valid command name
local getcache = {}
local get = function(cmd)
	local ret = getcache[cmd]

	if ret == nil then
		assert(iscommand(cmd), 'invalid input command: %s', cmd)
		ret = cmd
		getcache[cmd] = ret
	end

	return ret
end

-- return true if a command should not be allowed when the game is paused
local pausecache = setmetatable({}, {__mode = 'v'})
local pause = function(cmd)
	local ret = pausecache[cmd]

	if ret == nil then
		if not iscommand(cmd) then
			warning('invalid input command: %q', cmd)
		else
			ret = command[cmd]
			pausecache[cmd] = ret
		end
	end

	return ret
end


-- Input command table. Value is the return result for pause().
-- Main menu commands:

-- Character select commands:

-- Options menu commands:

-- Load menu commands:

-- Save menu commands:

-- Help menu commands:

-- In-Game menus:
--command.PICKUP_MENU           = true
--command.DROP_MENU             = true
--command.ATTACH_MENU           = true
--command.DETACH_MENU           = true

-- In-Game commands:
command.QUIT_NOSAVE           = false
command.PAUSE                 = false
command.MOVE_N                = true
command.MOVE_E                = true
command.MOVE_S                = true
command.MOVE_W                = true
command.MOVE_NE               = true
command.MOVE_NW               = true
command.MOVE_SE               = true
command.MOVE_SW               = true
command.WAIT                  = true
command.PICKUP_ENTITY         = true
command.DROP_ENTITY           = true
command.ATTACH_ENTITY         = true
command.DETACH_ENTITY         = true
--command.PORTAL_IN             = true
--command.PORTAL_OUT            = true

-- camera commands
command.CAMERA_ZOOMIN         = false
command.CAMERA_ZOOMOUT        = false
command.CAMERA_FOLLOW         = false
command.CAMERA_UNFOLLOW       = false

-- Console output commands:
command.PRINT_INVENTORY       = false
command.PRINT_STATS           = false
command.DUMP_ENTITIES         = false

-- Debug commands:
command.QUICKLOAD             = false
command.QUICKSAVE             = false
command.NEW_LEVEL             = false
command.DEBUG_PANEL_TOGGLE    = false
command.DEBUG_PANEL_RESET     = false
command.COLLECT_GARBAGE       = false
command.DISPLAY_MAPNAME       = false
command.CONSOLE_TOGGLE        = false
command.CONSOLE_SHOW          = false
command.CONSOLE_HIDE          = false
command.CONSOLE_CLEAR         = false
command.CONSOLE_PAGEUP        = false
command.CONSOLE_PAGEDOWN      = false
command.CONSOLE_TOP           = false
command.CONSOLE_BOTTOM        = false

-- the structure of valid command
return setmetatable({iscommand = iscommand, pause = pause},
	{__call = function(_, cmd) return get(cmd) end})
