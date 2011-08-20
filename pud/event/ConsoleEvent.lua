local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- ConsoleEvent
--
local ConsoleEvent = Class{name='ConsoleEvent',
	inherits=Event,
	function(self, message)
		verify('string', message)

		Event.construct(self, 'Console Event')

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
