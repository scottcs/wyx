local Class = require 'lib.hump.class'
local MouseEvent = getClass 'wyx.event.MouseEvent'

-- MousePressedEvent
-- sent when the mouse is pressed
local MousePressedEvent = Class{name='MousePressedEvent',
	inherits=MouseEvent,
	function(self, ...)
		MouseEvent.construct(self, ...)
	end
}

-- destructor
function MousePressedEvent:destroy()
	MouseEvent.destroy(self)
end


-- the class
return MousePressedEvent
