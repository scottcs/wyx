require 'pud.util'
local Class = require 'lib.hump.class'

local format = string.format

-- Event namespace which contains all events
local Event = {}

-- Base event class that all other events inherit
Event.Event = Class{name='Event.Event',
	function(self, name)
		name = name or 'Generic Event'
		self._name = name
	end
}

-- return the name of the event
function Event.Event:getName() return self._name end

-- private function to construct an informative message
function Event.Event:_msg(msg, ...)
	msg = tostring(self)..': '..msg
	return format(msg, ...)
end

-- make printable
function Event.Event:__tostring()
	return format('%s', self._name or 'unknown')
end

-- destructor
function Event.Event:destroy()
	if self._args then
		for k,v in pairs(self._args) do self._args[k] = nil end
		self._args = nil
	end
	self._name = nil
end

-- return a string of the class name minus the Event namespace
function Event.Event:getKey()
	return string.match(tostring(self.__class), '%a+$')
end

--------------------------
-- GAME EVENTS -----------
--------------------------
-- Game Start - fires when the game starts, before drawing or updating
Event.GameStart = Class{name='Event.GameStart',
	inherits=Event.Event,
	function(self)
		Event.Event.construct(self, 'Game Start Event')
	end
}

-- Game Over - fires when the game is over
-- params:
--   reason - can be 'death', 'quit', 'win'
Event.GameOver = Class{name='Event.GameOver',
	inherits=Event.Event,
	function(self, reason)
		Event.Event.construct(self, 'Game Over Event')

		verify('string', reason)
		assert(reason == 'death'
			or reason == 'quit'
			or reason == 'win',
			self:_msg('invalid reason "%s"', reason))

		self._reason = reason
	end
}

-- Game Exit - fires when the game has nothing more to do
Event.GameExit = Class{name='Event.GameExit',
	inherits=Event.Event,
	function(self)
		Event.Event.construct(self, 'Game Exit Event')
	end
}

--------------------------
-- MAP EVENTS ------------
--------------------------
-- Map Update Request - fires when the map needs to be updated
Event.MapUpdateRequest = Class{name='Event.MapUpdateRequest',
	inherits=Event.Event,
	function(self)
		Event.Event.construct(self, 'Map Update Request')
	end
}

-- Map Update Finished - fires after the map is done being updated
Event.MapUpdateFinished = Class{name='Event.MapUpdateFinished',
	inherits=Event.Event,
	function(self)
		Event.Event.construct(self, 'Map Update Finished')
	end
}

--------------------------
-- INTERACTIVE EVENTS ----
--------------------------
-- Open Door - fires when a door is opened
Event.OpenDoor = Class{name='Event.OpenDoor',
	inherits=Event.Event,
	function(self, actor)
		Event.Event.construct(self, 'Open Door')
		self._actor = actor or 'unknown'
	end
}

-- Event namespace
return Event
