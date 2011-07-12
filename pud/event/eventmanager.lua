-- EventManager
-- Provides a class that registers objects with itself, then notifies
-- those object when events occur.

local _E = require 'pud.event.events'
local mt = {__mode = 'k'}

-- EventManager class
local EventManager = Class{name='EventManager',
	function(self)
		self._events = {}
	end
}

-- validate that the given event is a defined event (in pud.event.events)
local _validateEvent = function(e)
	return assert(_E[e], 'unknown event: %s', e)
end

-- validate that the given object is an object or a function
local _validateObj = function(obj)
	return assert(obj and (type(obj) == 'table' or type(obj) == 'function'),
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
function EventManager:register(obj, ...)
	_validateObj(obj)

	local hasOnEvent = type(obj) == 'function' or (obj.onEvent
		and type(obj.onEvent) == 'function')

	for i=1,select('#',...) do
		local e = _validateEvent(select(i, ...))
		assert(hasOnEvent or obj[e] and type(obj[e]) == 'function',
			'no event handler exists on the specified object for event: %s', e)

		self._events[e] = self._events[e] or {}
		self._events[e][obj] = true
	end
end

-- unregister an object from listening for the given events
function EventManager:unregister(obj, ...)
	_validateObj(obj)

	for i=1,select('#',...) do
		local e = _validateEvent(select(i, ...))

		if self._events[e] and self._events[e][obj] then
			self._events[e][obj] = nil
		end
	end
end

-- register an object for all events
function EventManager:registerAll(obj)
	local all = {}
	for e in pairs(_E) do all[#all + 1] = e end
	self:register(obj, unpack(all))
end

-- unregister an object from all events
function EventManager:unregisterAll(obj)
	local e = self:getRegisteredEvents(obj)
	if e then self:unregister(obj, unpack(e)) end
end

-- trigger a specific event, notifying all listeners of the event.
-- note: it is recommended to use push() and flush() instead.
function EventManager:trigger(event, ...)
	local e = _validateEvent(event)

	for obj in pairs(self._events[e]) do
		if type(obj) == 'function' then
			obj(e, ...)
		elseif obj[e] and type(obj[e]) == 'function' then
			obj[e](obj, ...)
		elseif obj.onEvent and type(obj.onEvent) == 'function' then
			obj:onEvent(e, ...)
		end
	end
end

-- push an event into the event queue
function EventManager:push(event, ...)
	local e = _validateEvent(event)

	self._queue = self._queue or {}
	self._queue[#self._queue + 1] = {event=e, args={...}}
end

-- flush all events in the event queue and notify their listeners
function EventManager:flush()
	if self._queue then
		for i,q in ipairs(self._queue) do
			self:trigger(q.event, unpack(q.args))
		end
	end

	self._queue = nil
end

-- return a list of events for which obj is registered
function EventManager:getRegisteredEvents(obj)
	_validateObj(obj)

	local events = {}

	for e,objs in pairs(self._events) do
		if objs[obj] then events[#events+1] = e end
	end

	return #events > 0 and events or nil
end

-- the module
return EventManager
