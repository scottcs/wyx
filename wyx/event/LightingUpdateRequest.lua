local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- LightingUpdateRequest
--
local LightingUpdateRequest = Class{name='LightingUpdateRequest',
	inherits=Event,
	function(self)
		Event.construct(self, 'Lighting Update Request')
	end
}

-- destructor
function LightingUpdateRequest:destroy()
	Event.destroy(self)
end


-- the class
return LightingUpdateRequest
