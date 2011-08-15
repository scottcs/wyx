local message = {}

-- check if a given message is valid
local ismessage = function(msg) return message[msg] ~= nil end

-- get a message from the message table
local get = function(msg)
	assert(ismessage(msg), 'invalid component message: %s', msg)
	return message[msg]
end

-- Component messages
message.ENTITY_CREATED        = 'ENTITY_CREATED'

-- MotionComponent messages
message.HAS_MOVED             = 'HAS_MOVED'
message.SET_POSITION          = 'SET_POSITION'

-- CollisionComponent messages
message.COLLIDE_NONE          = 'COLLIDE_NONE'
message.COLLIDE_HERO          = 'COLLIDE_HERO'
message.COLLIDE_ENEMY         = 'COLLIDE_ENEMY'
message.COLLIDE_BLOCKED       = 'COLLIDE_BLOCKED'

-- TimeComponent messages
message.TIME_TICK             = 'TIME_TICK'

-- the structure of valid message
return setmetatable({ismessage = ismessage},
	{__call = function(_, msg) return get(msg) end})
