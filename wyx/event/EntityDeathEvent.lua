local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- EntityDeathEvent
--
local EntityDeathEvent = Class{name='EntityDeathEvent',
	inherits=Event,
	function(self, entityID, reason)
		if type(entityID) ~= 'string' then entityID = entityID:getID() end
		verify('string', entityID, reason)
		assert(EntityRegistry:exists(entityID),
			'EntityDeathEvent: entityID %q does not exist', entityID)

		Event.construct(self, 'Entity Death Event')

		self._entityID = entityID
		self._reason = reason
	end
}

-- destructor
function EntityDeathEvent:destroy()
	self._entityID = nil
	self._reason = nil
	Event.destroy(self)
end

function EntityDeathEvent:getEntity() return self._entityID end
function EntityDeathEvent:getReason() return self._reason end

function EntityDeathEvent:__tostring()
	return self:_msg('{%08s} %s', self._entityID, self._reason)
end

-- the class
return EntityDeathEvent
