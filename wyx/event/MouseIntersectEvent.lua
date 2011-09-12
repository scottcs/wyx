local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

local select, assert, unpack = select, assert, unpack

-- MouseIntersectEvent
--
local MouseIntersectEvent = Class{name='MouseIntersectEvent',
	inherits=Event,
	function(self, obj, ...)
		assert(obj, 'MouseIntersectEvent: object not specified.')

		Event.construct(self, 'Mouse Intersect Event')

		self._obj = obj
		self._args = (select('#', ...) > 0) and {...} or nil
	end
}

-- destructor
function MouseIntersectEvent:destroy()
	self._args = nil
	Event.destroy(self)
end

function MouseIntersectEvent:getObject() return self._obj end
function MouseIntersectEvent:getArgsTable() return self._args end
function MouseIntersectEvent:getArgs()
	return self._args and unpack(self._args) or nil
end


-- the class
return MouseIntersectEvent
