local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

local select, verify, unpack = select, verify, unpack

-- MouseIntersectRequest
--
local MouseIntersectRequest = Class{name='MouseIntersectRequest',
	inherits=Event,
	function(self, x, y, ...)
		verify('number', x, y)

		Event.construct(self, 'Mouse Intersect Request')

		self._x, self._y = x, y
		self._args = (select('#', ...) > 0) and {...} or nil
	end
}

-- destructor
function MouseIntersectRequest:destroy()
	self._x, self._y = nil, nil
	self._args = nil
	Event.destroy(self)
end

function MouseIntersectRequest:getX() return self._x end
function MouseIntersectRequest:getY() return self._y end
function MouseIntersectRequest:getPosition() return self._x, self._y end
function MouseIntersectRequest:getArgsTable() return self._args end
function MouseIntersectEvent:getArgs()
	return self._args and unpack(self._args) or nil
end


-- the class
return MouseIntersectRequest
