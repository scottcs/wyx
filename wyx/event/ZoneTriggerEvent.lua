local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- ZoneTriggerEvent
-- fires when something crosses a map zone boundary
local ZoneTriggerEvent = Class{name='ZoneTriggerEvent',
	inherits=Event,
	function(self, entityID, zone, isLeaving)
		verify('string', entityID, zone)
		assert(EntityRegistry:exists(entityID),
			'ZoneTriggerEvent: entityID %q does not exist', entityID)

		Event.construct(self, 'Zone Trigger Event')

		self._entityID = entityID
		self._zone = zone
		self._isLeaving = isLeaving
	end
}

-- destructor
function ZoneTriggerEvent:destroy()
	self._entityID = nil
	self._zone = nil
	self._isLeaving = nil
	Event.destroy(self)
end

function ZoneTriggerEvent:getEntity() return self._entityID end
function ZoneTriggerEvent:getZone() return self._zone end
function ZoneTriggerEvent:isLeaving() return self._isLeaving end

function ZoneTriggerEvent:__tostring()
	return self:_msg('{%08s} zone: %s, leaving: %s',
		self._entityID, self._zone, tostring(self._isLeaving))
end


-- the class
return ZoneTriggerEvent
