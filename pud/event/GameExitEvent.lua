local Class = require 'lib.hump.class'
local Event = getClass 'pud.event.Event'

-- Game Exit - fires when the game has nothing more to do
local GameExitEvent = Class{name='GameExitEvent',
	inherits=Event,
	function(self)
		Event.construct(self, 'Game Exit Event')
	end
}

-- the class
return GameExitEvent
