local Class = require 'lib.hump.class'
local MouseEvent = getClass 'wyx.event.MouseEvent'

-- MouseReleasedEvent
-- sent when the mouse is released
local MouseReleasedEvent = Class{name='MouseReleasedEvent',
	inherits=MouseEvent,
	function(self, ...)
		MouseEvent.construct(self, ...)
	end
}

-- destructor
function MouseReleasedEvent:destroy()
	MouseEvent.destroy(self)
end


-- the class
return MouseReleasedEvent
