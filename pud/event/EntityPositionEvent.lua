local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- EntityPositionEvent
--
local EntityPositionEvent = Class{name='EntityPositionEvent',
	inherits=Event,
	function(self, entity, to, from)
		verifyClass('pud.entity.Entity', entity)
		verify('vector', to, from)

		Event.construct(self, 'Entity Position Event')

		self._entity = entity
		self._to = to
		self._from = from
	end
}

-- destructor
function EntityPositionEvent:destroy()
	self._entity = nil
	self._to = nil
	self._from = nil
	Event.destroy(self)
end

function EntityPositionEvent:getEntity() return self._entity end
function EntityPositionEvent:getDestination() return self._to:clone() end
function EntityPositionEvent:getOrigin() return self._from:clone() end

-- the class
return EntityPositionEvent
