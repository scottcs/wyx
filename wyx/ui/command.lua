local command = {}

-- check if a given command is valid
local iscommand = function(cmd) return command[cmd] ~= nil end

-- get a command from the command table
local cache = {}
local get = function(cmd)
	local ret = cache[cmd]

	if ret == nil then
		assert(iscommand(cmd), 'invalid input command: %s', cmd)
		ret = command[cmd]
		cache[cmd] = ret
	end

	return ret
end

-- Input command table
command.PICKUP_ENTITY         = 'PICKUP_ENTITY'
command.DROP_ENTITY           = 'DROP_ENTITY'
command.ATTACH_ENTITY         = 'ATTACH_ENTITY'
command.DETACH_ENTITY         = 'DETACH_ENTITY'

-- the structure of valid command
return setmetatable({iscommand = iscommand},
	{__call = function(_, cmd) return get(cmd) end})
