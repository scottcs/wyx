local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- EntityPositionEvent
--
local EntityPositionEvent = Class{name='EntityPositionEvent',
	inherits=Event,
	function(self, entity, from, to)
		verifyClass('pud.entity.Entity', entity)
		verify('vector', from, to)

		Event.construct(self, 'Entity Position Event')

		self._entity = entity
		self._from = from
		self._to = to
	end
}

-- destructor
function EntityPositionEvent:destroy()
	self._entity = nil
	self._from = nil
	self._to = nil
	Event.destroy(self)
end

function EntityPositionEvent:getEntity() return self._entity end
function EntityPositionEvent:getOrigin() return self._from:clone() end
function EntityPositionEvent:getDestination() return self._to:clone() end

-- the class
return EntityPositionEvent
