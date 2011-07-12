
local _E = require 'pud.events'
local mt = {__mode = 'k'}

local EventManager = Class{name='EventManager',
	function(self)
		self._events = {}
	end
}

local _validateEvent = function(e)
	return assert(_E[e], 'unknown event: %s', e)
end

local _validateObj = function(obj)
	return assert(obj and (type(obj) == 'table' or type(obj) == 'function'),
		'expected an object or function (was %s)', type(obj))
end

function EventManager:destroy()
	for k,v in pairs(self._events) do
		for l,w in pairs(self._events[k]) do
			self._events[k][l] = nil
		end
		self._events[k] = nil
	end
	self._events = nil
end

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

function EventManager:unregister(obj, ...)
	_validateObj(obj)

	for i=1,select('#',...) do
		local e = _validateEvent(select(i, ...))

		if self._events[e] and self._events[e][obj] then
			self._events[e][obj] = nil
		end
	end
end

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

function EventManager:queue(event, ...)
	local e = _validateEvent(event)

	self._queue = self._queue or {}
	self._queue[#self._queue + 1] = {event=e, args={...}}
end

function EventManager:flush()
	if self._queue then
		for i,q in ipairs(self._queue) do
			self:trigger(q.event, unpack(q.args))
		end
	end

	self._queue = nil
end

function EventManager:getRegisteredEvents(obj)
	_validateObj(obj)

	local events = {}

	for e,objs in pairs(self._events) do
		if objs[obj] then events[#events+1] = e end
	end

	return #events > 0 and events or nil
end

return EventManager
