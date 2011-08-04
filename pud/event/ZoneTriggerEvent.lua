local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local Event = require 'pud.event.Event'
local Entity = require 'pud.entity.Entity'

-- ZoneTriggerEvent
-- fires when something crosses a map zone boundary
local ZoneTriggerEvent = Class{name='ZoneTriggerEvent',
	inherits=Event,
	function(self, entity, zone, isLeaving)
		assert(entity and type(entity) == 'table'
			and entity.is_a and entity:is_a(Entity),
			'entity expected (was %s)', type(entity))
		verify('string', zone)

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
