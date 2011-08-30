local message = {}

-- check if a given message is valid
local ismessage = function(msg) return message[msg] ~= nil end

-- get a message from the message table
local cache = {}
local get = function(msg)
	local ret = cache[msg]

	if ret == nil then
		assert(ismessage(msg), 'invalid component message: %s', msg)
		ret = message[msg]
		cache[msg] = ret
	end

	return ret
end

-- Component messages
message.ALL                   = 'ALL'
message.ENTITY_CREATED        = 'ENTITY_CREATED'

-- MotionComponent messages
message.HAS_MOVED             = 'HAS_MOVED'
message.SET_POSITION          = 'SET_POSITION'

-- CollisionComponent messages
message.COLLIDE_NONE          = 'COLLIDE_NONE'
message.COLLIDE_HERO          = 'COLLIDE_HERO'
message.COLLIDE_ENEMY         = 'COLLIDE_ENEMY'
message.COLLIDE_ITEM          = 'COLLIDE_ITEM'
message.COLLIDE_PORTAL        = 'COLLIDE_PORTAL'
message.COLLIDE_BLOCKED       = 'COLLIDE_BLOCKED'

-- GraphicsComponent messages
message.SCREEN_STATUS         = 'SCREEN_STATUS'

-- TimeComponent messages
message.TIME_AUTO             = 'TIME_AUTO'
message.TIME_PRETICK          = 'TIME_PRETICK'
message.TIME_POSTTICK         = 'TIME_POSTTICK'
message.TIME_PREEXECUTE       = 'TIME_PREEXECUTE'
message.TIME_POSTEXECUTE      = 'TIME_POSTEXECUTE'

-- CombatComponent messages
message.COMBAT_DAMAGE         = 'COMBAT_DAMAGE'

-- HealthComponent messages
message.ENTITY_DEATH          = 'ENTITY_DEATH'
message.HEALTH_UPDATE         = 'HEALTH_UPDATE'

-- ContainerComponent messages
message.CONTAINER_RESIZE      = 'CONTAINER_RESIZE'
message.CONTAINER_INSERT      = 'CONTAINER_INSERT'
message.CONTAINER_REMOVE      = 'CONTAINER_REMOVE'
message.CONTAINER_INSERTED    = 'CONTAINER_INSERTED'
message.CONTAINER_REMOVED     = 'CONTAINER_REMOVED'

-- AttachmentComponent messages
message.ATTACHMENT_ATTACH      = 'ATTACHMENT_ATTACH'
message.ATTACHMENT_DETACH      = 'ATTACHMENT_DETACH'
message.ATTACHMENT_ATTACHED    = 'ATTACHMENT_ATTACHED'
message.ATTACHMENT_DETACHED    = 'ATTACHMENT_DETACHED'

-- the structure of valid message
return setmetatable({ismessage = ismessage},
	{__call = function(_, msg) return get(msg) end})
