local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- PrimeEntityChangedEvent
--
local PrimeEntityChangedEvent = Class{name='PrimeEntityChangedEvent',
	inherits=Event,
	function(self, entityID)
		if type(entityID) ~= 'string' then entityID = entityID:getID() end
		verify('string', entityID)
		assert(EntityRegistry:exists(entityID),
			'PrimeEntityChangedEvent: entityID %q does not exist', entityID)

		Event.construct(self, 'Prime Entity Changed Event')

		self._entityID = entityID
	end
}

-- destructor
function PrimeEntityChangedEvent:destroy()
	self._entityID = nil
	Event.destroy(self)
end

function PrimeEntityChangedEvent:getEntity() return self._entityID end

-- the class
return PrimeEntityChangedEvent
