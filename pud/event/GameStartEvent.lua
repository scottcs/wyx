local Class = require 'lib.hump.class'
local Event = require 'pud.event.Event'

-- Game Start - fires when the game starts, before drawing or updating
local GameStartEvent = Class{name='GameStartEvent',
	inherits=Event,
	function(self)
		Event.construct(self, 'Game Start Event')
	end
}

-- Event namespace
return GameStartEvent