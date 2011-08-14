local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- EntityPositionEvent
--
local EntityPositionEvent = Class{name='EntityPositionEvent',
	inherits=Event,
	function(self, entity, v)
		verifyClass('pud.entity.Entity', entity)
		verify('vector', v)

		Event.construct(self, 'Entity Position Event')

		self._entity = entity
		self._v = v
	end
}

-- destructor
function EntityPositionEvent:destroy()
	self._entity = nil
	self._v = nil
	Event.destroy(self)
end

function EntityPositionEvent:getEntity() return self._entity end
function EntityPositionEvent:getVector() return self._v:clone() end

-- the class
return EntityPositionEvent
