local Class = require 'lib.hump.class'

-- EventManager
-- Provides a class that registers objects with itself, then notifies
-- those object when events occur.

local Event = require 'pud.event.Event'

-- EventManager class
local EventManager = Class{name='EventManager',
	function(self)
		self._events = {}
	end
}

-- validate that the given event is a defined event (in pud.event.Event)
local _validateEvent = function(e)
	assert(e, 'event is nil')
	assert(e.is_a and e:is_a(Event), 'invalid event: %s', tostring(e))
end

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
function EventManager:register(obj, events)
	_validateObj(obj)

	if type(obj) == 'table' then
		assert(obj.onEvent and type(obj.onEvent) == 'function',
			'object "%s" is missing an onEvent method', tostring(obj))
	end

	if type(events) ~= 'table' then
		events = {events}
	end
	for _,event in ipairs(events) do
		_validateEvent(event)
		local key = event:getKey()
		self._events[key] = self._events[key] or {}
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
		_validateEvent(event)
		local key = event:getKey()

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
-- note: it is recommended to use push() and flush() instead.
function EventManager:notify(event)
	_validateEvent(event)
	local key = event:getKey()

	for obj in pairs(self._events[key]) do
		if type(obj) == 'function' then
			obj(event)
		elseif obj.onEvent and type(obj.onEvent) == 'function' then
			obj:onEvent(event)
		end
	end
end

-- push an event into the event queue
function EventManager:push(event)
	_validateEvent(event)

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
			event:destroy()
		end
	end
end

-- the module
return EventManager
