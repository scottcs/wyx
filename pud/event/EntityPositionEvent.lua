local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- EntityPositionEvent
--
local EntityPositionEvent = Class{name='EntityPositionEvent',
	inherits=Event,
	function(self, entity, toX, toY, fromX, fromY)
		verifyClass('pud.entity.Entity', entity)
		verify('number', toX, toY, fromX, fromY)

		Event.construct(self, 'Entity Position Event')

		self._entity = entity
		self._toX = toX
		self._toY = toY
		self._fromX = fromX
		self._fromY = fromY
	end
}

-- destructor
function EntityPositionEvent:destroy()
	self._entity = nil
		self._toX = nil
		self._toY = nil
		self._fromX = nil
		self._fromY = nil
	Event.destroy(self)
end

function EntityPositionEvent:getEntity() return self._entity end
function EntityPositionEvent:getDestination() return self._toX, self._toY end
function EntityPositionEvent:getOrigin() return self._fromX, self._fromY end

-- the class
return EntityPositionEvent
