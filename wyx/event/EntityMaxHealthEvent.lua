local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- EntityMaxHealthEvent
--
local EntityMaxHealthEvent = Class{name='EntityMaxHealthEvent',
	inherits=Event,
	function(self, entityID)
		if type(entityID) ~= 'string' then entityID = entityID:getID() end
		verify('string', entityID)
		assert(EntityRegistry:exists(entityID),
			'EntityMaxHealthEvent: entityID %q does not exist', entityID)

		Event.construct(self, 'Entity MaxHealth Event')

		self._entityID = entityID
	end
}

-- destructor
function EntityMaxHealthEvent:destroy()
	self._entityID = nil
	Event.destroy(self)
end

function EntityMaxHealthEvent:getEntity() return self._entityID end

-- the class
return EntityMaxHealthEvent
