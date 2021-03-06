local Class = require 'lib.hump.class'

local format = string.format

-- Base event class that all other events inherit
local Event = Class{name='Event',
	function(self, name)
		name = name or 'Generic Event'
		self._name = name
		self._debugLevel = 1
	end
}

-- destructor
function Event:destroy()
	self._name = nil
	self._debugLevel = nil
end

-- return the name of the event
function Event:getName() return self._name end

-- private function to construct an informative message
function Event:_msg(msg, ...)
	return format('%s: %s', (self._name or 'unknown'), format(msg, ...))
end

-- make printable
function Event:__tostring()
	return format('%s', self._name or 'unknown')
end

-- return a unique key for the Event
function Event:getEventKey()
	return self.__class and self.__class or self
end

-- add an event class to the list of all events
local _allEvents = {}
function Event:inherited(class)
	_allEvents[class] = true
end

-- class method to return all existing event classes
function Event:getAllEvents()
	local t = {}
	for k in pairs(_allEvents) do
		t[#t+1] = k
	end
	return t
end

function Event:getDebugLevel() return self._debugLevel end


-- the class
return Event
