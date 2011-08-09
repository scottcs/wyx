local Class = require 'lib.hump.class'

-- EventManager
-- Provides a class that registers objects with itself, then notifies
-- those object when events occur.

local Event = require 'pud.event.Event'
local eventsMT = {__mode = 'k'}

-- EventManager class
local EventManager = Class{name='EventManager',
	function(self)
		self._events = {}
	end
}

-- validate that the given object is an object or a function
local _validateObj = function(obj)
	assert(obj and (type(obj) == 'table' or type(obj) == 'function'),
		'expected an object or function (was %s)', type(obj))
end

-- destructor
function EventManager:destroy()
	for k,v in pairs(self._events) do
		for l,w in pairs(self._events[k]) do
			self._events[k][l] = nil
		end
		self._events[k] = nil
	end
	self._events = nil
end

-- register an object to listen for the given events
-- obj can be:
--   a function
--   an object with a method that has the same name as the event
--   an object with an onEvent method
function EventManager:register(obj, events)
	_validateObj(obj)

	local hasOnEvent = type(obj) == 'function'
		or obj.onEvent and type(obj.onEvent) == 'function'

	if events.is_a then
		events = {events}
	end
	for _,event in ipairs(events) do
		verifyClass(Event, event)
		local keyStr = tostring(event:getEventKey())
		assert(hasOnEvent or (obj[keyStr] and type(obj[keyStr]) == 'function'),
			'object "%s" is missing event callback method for event "%s"',
			tostring(obj), keyStr)

		local key = event:getEventKey()
		-- event table has weak keys
		self._events[key] = self._events[key] or setmetatable({}, eventsMT)
		self._events[key][obj] = true
	end
end

-- unregister an object from listening for the given events
function EventManager:unregister(obj, events)
	_validateObj(obj)

	if type(events) ~= 'table' then
		events = {events}
	end
	for _,event in ipairs(events) do
		verifyClass(Event, event)
		local key = event:getEventKey()

		if self._events[key] and self._events[key][obj] then
			self._events[key][obj] = nil
		end
	end
end

-- register an object for all events
function EventManager:registerAll(obj)
	self:register(obj, Event:getAllEvents())
end

-- unregister an object from all events
function EventManager:unregisterAll(obj)
	local events = self:getRegisteredEvents(obj)
	if events then self:unregister(obj, events) end
end

-- return a list of events for which obj is registered
function EventManager:getRegisteredEvents(obj)
	_validateObj(obj)
	local events = {}

	for event,objs in pairs(self._events) do
		if objs[obj] then
			events[#events+1] = event
		end
	end

	return #events > 0 and events or nil
end

-- notify a specific event, notifying all listeners of the event.
-- note: it is recommended to use push() and flush() rather than call notify()
-- directly.
function EventManager:notify(event)
	verifyClass(Event, event)
	local key = event:getEventKey()

	if self._events[key] then
		for obj in pairs(self._events[key]) do
			if type(obj) == 'function' then                     -- function()
				obj(event)
			else
				local keyStr = tostring(event:getEventKey())
				if obj[keyStr] then obj[keyStr](obj, event) end   -- obj:NamedEvent()
				if obj.onEvent then obj:onEvent(event) end        -- obj:onEvent()
			end
		end
	end

	event:destroy()
end

-- push an event into the event queue
function EventManager:push(event)
	verifyClass(Event, event)

	self._queue = self._queue or {}
	self._queue[#self._queue + 1] = event
end

-- flush all events in the event queue and notify their listeners
function EventManager:flush()
	if self._queue then
		-- copy the queue to a local table in case notifying an event pushes
		-- more events on the queue
		local queue = {}
		for i,event in ipairs(self._queue) do
			queue[i] = event
			self._queue[i] = nil
		end
		self._queue = nil

		-- iterate through the copy of the queue and notify events
		for _,event in ipairs(queue) do
			self:notify(event)
		end
	end
end

-- the module
return EventManager
