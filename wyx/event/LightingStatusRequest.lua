local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- LightingStatusRequest
--
local LightingStatusRequest = Class{name='LightingStatusRequest',
	inherits=Event,
	function(self, entityID, x, y)
		if type(entityID) ~= 'string' then entityID = entityID:getID() end
		verify('string', entityID)
		verify('number', x, y)
		assert(EntityRegistry:exists(entityID),
			'LightingStatusRequest: entityID %q does not exist', entityID)

		Event.construct(self, 'Lighting Status Request')

		self._entityID = entityID
		self._x = x
		self._y = y
	end
}

-- destructor
function LightingStatusRequest:destroy()
	self._entityID = nil
	Event.destroy(self)
end

function LightingStatusRequest:getEntity() return self._entityID end
function LightingStatusRequest:getPosition() return self._x, self._y end

-- the class
return LightingStatusRequest
