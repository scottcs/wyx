require 'pud.util'
local Class = require 'lib.hump.class'
local Event = require 'pud.event.Event'
local Map = require 'pud.level.Map'

-- Map Update RequestEvent - fires when the map needs to be updated
local MapUpdateRequestEvent = Class{name='MapUpdateRequestEvent',
	inherits=Event,
	function(self, map)
		assert(map and map.is_a and map:is_a(Map),
			self:_msg('map must be a Map (not %s (%s))', type(map), tostring(map)))
		Event.construct(self, 'Map Update RequestEvent')

		self._map = map
	end
}

function MapUpdateRequestEvent:getMap() return self._map end

-- the class
return MapUpdateRequestEvent
