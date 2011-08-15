local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- MapNode Update - fires after the node is updated
local MapNodeUpdateEvent = Class{name='MapNodeUpdateEvent',
	inherits=Event,
	function(self, node)
		verifyClass('pud.map.MapNode', node)
		Event.construct(self, 'MapNode Update')

		self._node = node
	end
}

-- destructor
function MapNodeUpdateEvent:destroy()
	self._node = nil
	Event.destroy(self)
end

function MapNodeUpdateEvent:getNode() return self._node end

-- the class
return MapNodeUpdateEvent
