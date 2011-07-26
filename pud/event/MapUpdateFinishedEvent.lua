require 'pud.util'
local Class = require 'lib.hump.class'
local Event = require 'pud.event.Event'
local Map = require 'pud.map.Map'

-- Map Update Finished - fires after the map is done being updated
local MapUpdateFinishedEvent = Class{name='MapUpdateFinishedEvent',
	inherits=Event,
	function(self, map)
		assert(map and map.is_a and map:is_a(Map),
			self:_msg('map must be a Map (not %s (%s))', type(map), tostring(map)))
		Event.construct(self, 'Map Update Finished')

		self._map = map
	end
}

function MapUpdateFinishedEvent:getMap() return self._map end

-- the class
return MapUpdateFinishedEvent
