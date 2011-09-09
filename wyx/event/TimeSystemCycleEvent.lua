local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- TimeSystemCycleEvent
--
local TimeSystemCycleEvent = Class{name='TimeSystemCycleEvent',
	inherits=Event,
	function(self)
		Event.construct(self, 'TimeSystem Cycle Event')
	end
}

-- destructor
function TimeSystemCycleEvent:destroy()
	Event.destroy(self)
end


-- the class
return TimeSystemCycleEvent
