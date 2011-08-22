local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- LightingStatusRequest
--
local LightingStatusRequest = Class{name='LightingStatusRequest',
	inherits=Event,
	function(self, entity, x, y)
		if type(entity) ~= number then entity = entity:getID() end
		verify('number', entity, x, y)
		assert(EntityRegistry:exists(entity),
			'LightingStatusRequest: entity %d does not exist', entity)

		Event.construct(self, 'Lighting Status Request')

		self._entity = entity
		self._x = x
		self._y = y
	end
}

-- destructor
function LightingStatusRequest:destroy()
	self._entity = nil
	Event.destroy(self)
end

function LightingStatusRequest:getEntity() return self._entity end
function LightingStatusRequest:getPosition() return self._x, self._y end

-- the class
return LightingStatusRequest
