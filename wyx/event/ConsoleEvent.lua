local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'
local format = string.format
local select, verify = select, verify

-- ConsoleEvent
--
local ConsoleEvent = Class{name='ConsoleEvent',
	inherits=Event,
	function(self, message, ...)
		verify('string', message)

		Event.construct(self, 'Console Event')

		message = select('#', ...) > 0 and format(message, ...) or message

		self._message = message
	end
}

-- destructor
function ConsoleEvent:destroy()
	self._message = nil
	Event.destroy(self)
end

function ConsoleEvent:getMessage() return self._message end


-- the class
return ConsoleEvent
