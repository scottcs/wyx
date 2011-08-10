local Class = require 'lib.hump.class'
local Event = getClass('pud.event.Event')

-- Map Update RequestEvent - fires when the map needs to be updated
local MapUpdateRequestEvent = Class{name='MapUpdateRequestEvent',
	inherits=Event,
	function(self, map)
		verifyClass('pud.map.Map', map)
		Event.construct(self, 'Map Update RequestEvent')

		self._map = map
	end
}

-- destructor
function MapUpdateRequestEvent:destroy()
	self._map = nil
	Event.destroy(self)
end

function MapUpdateRequestEvent:getMap() return self._map end

-- the class
return MapUpdateRequestEvent
