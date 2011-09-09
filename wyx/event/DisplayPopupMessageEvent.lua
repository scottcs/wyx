local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- DisplayPopupMessageEvent
--
local DisplayPopupMessageEvent = Class{name='DisplayPopupMessageEvent',
	inherits=Event,
	function(self, message)
		verify('string', message)

		Event.construct(self, 'Display Popup Message Event')

		self._message = message
	end
}

-- destructor
function DisplayPopupMessageEvent:destroy()
	self._message = nil
	Event.destroy(self)
end

function DisplayPopupMessageEvent:getMessage() return self._message end

-- the class
return DisplayPopupMessageEvent
