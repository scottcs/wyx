local Class = require 'lib.hump.class'

-- EventManager
-- Provides a class that registers objects with itself, then notifies
-- those object when events occur.

local Event = require 'pud.event.Event'
local mt = {__mode = 'k'}

-- EventManager class
local EventManager = Class{name='EventManager',
	function(self)
		self._events = {}
	end
}

-- validate that the given event is a defined event (in pud.event.Event)
local _validateEvent = function(e)
	assert(e, 'event is nil')
	local condition = false

	if type(e) == 'table' then
		condition = e.is_a and e:is_a(Event.Event)
	else
		condition = type(e) == 'string' and Event[e]
	end

	assert(condition, 'unknown event: %s', tostring(e))
	return e
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

	assert(type(obj) == 'function'
		or (obj.onEvent and type(obj.onEvent) == 'function'),
		'no event handler exists on the specified object: %s', tostring(obj))

	for i=1,select('#',...) do
		local e = _validateEvent(select(i, ...))
		local name
		if type(e) == 'table' then
			name = e:getKey()
		else
			name = e
		end

		self._events[name] = self._events[name] or {}
		self._events[name][obj] = true
	end
end

-- unregister an object from listening for the given events
function EventManager:unregister(obj, ...)
	_validateObj(obj)

	for i=1,select('#',...) do
		local e = _validateEvent(select(i, ...))
		local name
		if type(e) == 'table' then
			name = e:getKey()
		else
			name = e
		end

		if self._events[name] and self._events[name][obj] then
			self._events[name][obj] = nil
		end
	end
end

-- register an object for all events
function EventManager:registerAll(obj)
	local t = {}
	for _,e in pairs(Event) do t[#t+1] = e:getKey() end
	self:register(obj, unpack(t))
end

-- unregister an object from all events
function EventManager:unregisterAll(obj)
	local e = self:getRegisteredEvents(obj)
	if e then self:unregister(obj, unpack(e)) end
end

-- notify a specific event, notifying all listeners of the event.
-- note: it is recommended to use push() and flush() instead.
function EventManager:notify(event, ...)
	local e = _validateEvent(event)
	local name = e:getKey()

	for obj in pairs(self._events[name]) do
		if type(obj) == 'function' then
			obj(e, ...)
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
		-- copy the queue to a local table in case notifying an event pushes
		-- more events on the queue
		local queue = {}
		for i,q in ipairs(self._queue) do
			queue[i] = q
			self._queue[i] = nil
		end
		self._queue = nil

		-- iterate through the copy of the queue and notify events
		for i,q in ipairs(queue) do
			self:notify(q.event, unpack(q.args))
			q.event:destroy()
			q.event = nil
			q.args = nil
		end
	end
end

-- return a list of events for which obj is registered
function EventManager:getRegisteredEvents(obj)
	_validateObj(obj)

	local events = {}

	for name,objs in pairs(self._events) do
		if objs[obj] then
			events[#events+1] = name
		end
	end

	return #events > 0 and events or nil
end

-- the module
return EventManager
