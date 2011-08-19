local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- ZoneTriggerEvent
-- fires when something crosses a map zone boundary
local ZoneTriggerEvent = Class{name='ZoneTriggerEvent',
	inherits=Event,
	function(self, entity, zone, isLeaving)
		verify('number', entity)
		verify('string', zone)
		assert(EntityRegistry:exists(entity),
			'ZoneTriggerEvent: entity %d does not exist', entity)

		Event.construct(self, 'Zone Trigger Event')

		self._entity = entity
		self._zone = zone
		self._isLeaving = isLeaving
	end
}

-- destructor
function ZoneTriggerEvent:destroy()
	self._entity = nil
	self._zone = nil
	self._isLeaving = nil
	Event.destroy(self)
end

function ZoneTriggerEvent:getEntity() return self._entity end
function ZoneTriggerEvent:getZone() return self._zone end
function ZoneTriggerEvent:isLeaving() return self._isLeaving end

-- the class
return ZoneTriggerEvent
