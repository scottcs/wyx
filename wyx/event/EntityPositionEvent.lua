local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- EntityPositionEvent
--
local EntityPositionEvent = Class{name='EntityPositionEvent',
	inherits=Event,
	function(self, entityID, toX, toY, fromX, fromY)
		if type(entityID) ~= 'string' then entityID = entityID:getID() end
		verify('string', entityID)
		verify('number', toX, toY, fromX, fromY)
		assert(EntityRegistry:exists(entityID),
			'EntityPositionEvent: entityID %q does not exist', entityID)

		Event.construct(self, 'Entity Position Event')

		self._debugLevel = 2
		self._entityID = entityID
		self._toX = toX
		self._toY = toY
		self._fromX = fromX
		self._fromY = fromY
	end
}

-- destructor
function EntityPositionEvent:destroy()
	self._entityID = nil
	self._toX = nil
	self._toY = nil
	self._fromX = nil
	self._fromY = nil
	Event.destroy(self)
end

function EntityPositionEvent:getEntity() return self._entityID end
function EntityPositionEvent:getDestination() return self._toX, self._toY end
function EntityPositionEvent:getOrigin() return self._fromX, self._fromY end

function EntityPositionEvent:__tostring()
	return self:_msg('{%08s} from: (%d,%d) to: (%d,%d)',
		self._entityID, self._fromX, self._fromY, self._toX, self._toY)
end

-- the class
return EntityPositionEvent
