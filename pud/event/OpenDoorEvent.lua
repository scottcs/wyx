local Class = require 'lib.hump.class'
local Event = require 'pud.event.Event'

-- Open Door - fires when a door is opened
local OpenDoorEvent = Class{name='OpenDoorEvent',
	inherits=Event,
	function(self, actor)
		Event.construct(self, 'Open Door')
		self._actor = actor
	end
}

-- the class
return OpenDoorEvent
