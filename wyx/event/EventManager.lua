local Class = require 'lib.hump.class'

-- EventManager
-- Provides a class that registers objects with itself, then notifies
-- those object when events occur.

local Event = getClass 'wyx.event.Event'
local eventsMT = {__mode = 'k'}
local format = string.format

-- EventManager class
local EventManager = Class{name='EventManager',
	function(self, name)
		name = name or 'EventManager'
		verify('string', name)
		self._name = name

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
	if self._registerQueue then self:_registerPending() end
	if self._unregisterQueue then self:_unregisterPending() end

	self:clear()
	for k,v in pairs(self._events) do
		for l,w in pairs(self._events[k]) do
			self._events[k][l] = nil
		end
		self._events[k] = nil
	end
	self._events = nil

	self._name = nil
	self._lastDebugMsg = nil
	self._lastDebugRepeat = nil
	self._debug = nil
end

-- register an object to listen for the given events
-- obj can be:
--   a function
--   an object with a method that has the same name as the event
--   an object with an onEvent method
function EventManager:register(obj, events)
	_validateObj(obj)
	verify('table', events)
	if events.is_a then events = {events} end

	self._registerQueue = self._registerQueue or {}
	self._registerQueue[obj] = events

	if not self._notifying then self:_registerPending() end
end

-- unregister an object from listening for the given events
function EventManager:unregister(obj, events)
	_validateObj(obj)
	verify('table', events)
	if events.is_a then events = {events} end

	self._unregisterQueue = self._unregisterQueue or {}
	self._unregisterQueue[obj] = events

	if not self._notifying then self:_unregisterPending() end
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

function EventManager:_registerPending()
	if self._registerQueue then
		for obj,events in pairs(self._registerQueue) do
			local hasOnEvent = type(obj) == 'function'
				or (type(obj) == 'table'
					and obj.onEvent
					and type(obj.onEvent) == 'function')

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
			self._registerQueue[obj] = nil
		end
		self._registerQueue = nil
	end
end

function EventManager:_unregisterPending()
	if self._unregisterQueue then
		for obj,events in pairs(self._unregisterQueue) do
			for _,event in ipairs(events) do
				verifyClass(Event, event)
				local key = event:getEventKey()

				if self._events[key] and self._events[key][obj] then
					self._events[key][obj] = nil
				end
			end
			self._unregisterQueue[obj] = nil
		end
		self._unregisterQueue = nil
	end
end

-- notify a specific event, notifying all listeners of the event.
function EventManager:notify(event)
	verifyClass(Event, event)
	self._notifying = true
	local key = event:getEventKey()

	if self._events[key] then
		for obj in pairs(self._events[key]) do

			if self._debug then
				local eventLevel = event:getDebugLevel()
				if eventLevel <= self._debug then
					local mgr = tostring(self)
					local eventstr = tostring(event)
					local objstr = tostring(obj.__class or obj)
					local msg = format('[%s->%s] %s', mgr, objstr, eventstr)
					if self._lastDebugMsg ~= msg then
						if self._lastDebugRepeat and self._lastDebugRepeat > 0 then
							local m = format('(Last message repeated %d times.)',
								self._lastDebugRepeat)
							if Console then Console:print(m) end
							print(m)
						end
						self._lastDebugMsg = msg
						self._lastDebugRepeat = 0
						if Console then Console:print(msg) end
						print(msg)
					else
						self._lastDebugRepeat = self._lastDebugRepeat + 1
					end
				end
			end

			if type(obj) == 'function' then                     -- function()
				obj(event)
			else
				local keyStr = tostring(event:getEventKey())
				if obj[keyStr] then obj[keyStr](obj, event) end   -- obj:NamedEvent()
				if obj.onEvent then obj:onEvent(event) end        -- obj:onEvent()
			end

			if not self._notifying then break end
		end -- for obj in pairs(self._events[key])
	end -- if self._events[key]

	self:_registerPending()
	self:_unregisterPending()
	self._notifying = false

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

-- remove all events in the queue without notifying listeners
function EventManager:clear()
	if self._queue then
		local num = #self._queue
		for i=1,num do
			self._queue[i] = nil
		end
		self._queue = nil
	end
	self._notifying = false
end

function EventManager:debug(level)
	verify('number', level)
	self._debug = level
end

function EventManager:__tostring() return self._name end


-- the module
return EventManager
