local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- Map Update Finished - fires after the map is done being updated
local MapUpdateFinishedEvent = Class{name='MapUpdateFinishedEvent',
	inherits=Event,
	function(self, map)
		verifyClass('wyx.map.Map', map)
		Event.construct(self, 'Map Update Finished')

		self._map = map
	end
}

-- destructor
function MapUpdateFinishedEvent:destroy()
	self._map = nil
	Event.destroy(self)
end

function MapUpdateFinishedEvent:getMap() return self._map end

function MapUpdateFinishedEvent:__tostring()
	return self:_msg('%s', tostring(self._map))
end


-- the class
return MapUpdateFinishedEvent
