local Class = require 'lib.hump.class'

-- TimedObject
-- Provides an interface for objects to be used with the TimeManager.
local TimedObject = Class{name='TimedObject',
	function(self)
		self._isExhausted = false
	end
}

-- getSpeed
-- params:
--   ap - current number of action points for this object
-- returns the number of action points this object gains per tick.
function TimedObject:getSpeed(ap)
	return 1
end

-- doAction
-- params:
--   ap - current number of action points for this object
-- performs the object's action
-- returns the number of action points spent (may be greater than ap)
function TimedObject:doAction(ap)
	return 1
end

-- isExhausted
-- returns true if the object should be removed from the TimeManager
function TimedObject:isExhausted() return self._isExhausted end
function TimedObject:setExhausted(b) self._isExhausted = b == true end

-- destructor
function TimedObject:destroy()
	self._isExhausted = nil
end

return TimedObject
