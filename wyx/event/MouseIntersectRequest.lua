local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- MouseIntersectRequest
--
local MouseIntersectRequest = Class{name='MouseIntersectRequest',
	inherits=Event,
	function(self, x, y)
		verify('number', x, y)

		Event.construct(self, 'Mouse Intersect Request')

		self._x, self._y = x, y
	end
}

-- destructor
function MouseIntersectRequest:destroy()
	self._x, self._y = nil, nil
	Event.destroy(self)
end

function MouseIntersectRequest:getX() return self._x end
function MouseIntersectRequest:getY() return self._y end
function MouseIntersectRequest:getPosition() return self._x, self._y end


-- the class
return MouseIntersectRequest
