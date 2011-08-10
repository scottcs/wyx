local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local Deque = require 'pud.kit.Deque'
local property = require 'pud.component.property'

-- events this entity listens for
local CommandEvent = require 'pud.event.CommandEvent'


-- ItemEntity
--
local ItemEntity = Class{name='ItemEntity',
	inherits={Entity, TimedObject, Traveler},
	function(self, name, initComponents)
		Entity.construct(self, name, 'hero', initComponents)
		CommandEvents:register(self, CommandEvent)
		self._commandQueue = Deque()
	end
}

-- destructor
function ItemEntity:destroy()
	self._commandQueue:destroy()
	self._commandQueue = nil

	CommandEvents:unregisterAll(self)
	Entity.destroy(self)
end

-- receive commands
function ItemEntity:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self then return end
	self._commandQueue:push_back(command)
end

local _commandPropCache = setmetatable({}, {__mode = 'kv'})
local _commandProp = function(command)
	local prop = _commandPropCache[command.__class]
	if nil == prop then
		local prop = tostring(command.__class)
		prop = string.match(prop, '^(%w+)Command')
		prop = prop .. 'Cost'
		_commandPropCache[command] = property(prop)
	end
	return prop
end

-- perform commands that were received
function ItemEntity:doAction(ap)
	if self._commandQueue:size() == 0 then return self._turnSpeed end
	local command = self._commandQueue:pop_front()
	command:execute()
	local cost = self:query(_commandProp(command), 'sum')

	-- destroy the command, since we executed it
	command:destroy()

	return cost
end

-- return the number of commands waiting to be executed
function ItemEntity:getPendingCommandCount()
	return self._commandQueue:size()
end

-- the class
return ItemEntity
