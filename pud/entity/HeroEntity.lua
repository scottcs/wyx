local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local Traveler = require 'pud.entity.Traveler'
local TimedObject = require 'pud.time.TimedObject'
local Deque = require 'pud.kit.Deque'

-- events this entity listens for
local CommandEvent = require 'pud.event.CommandEvent'

-- default action point costs for commands
local AP_COSTS = {
	MoveCommand = 1,
	AttackCommand = 1.5,
	OpenDoorCommand = 1,
}

-- default turn speed
local AP_PER_TURN = 1.0

-- HeroEntity
--
local HeroEntity = Class{name='HeroEntity',
	inherits={Entity, TimedObject, Traveler},
	function(self)
		Entity.construct(self)
		TimedObject.construct(self)
		Traveler.construct(self)
		CommandEvents:register(self, CommandEvent)

		self._commandQueue = Deque()
		self._turnSpeed = AP_PER_TURN
	end
}

-- destructor
function HeroEntity:destroy()
	self._stepSize = nil
	self._turnSpeed = nil
	self._commandQueue:destroy()
	self._commandQueue = nil

	CommandEvents:unregisterAll(self)
	Traveler.destroy(self)
	TimedObject.destroy(self)
	Entity.destroy(self)
end

-- receive commands
function HeroEntity:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self then return end
	self._commandQueue:push_back(command)
end

-- perform commands that were received
function HeroEntity:doAction(ap)
	if self._commandQueue:size() == 0 then return self._turnSpeed end
	local command = self._commandQueue:pop_front()
	command:execute()
	local cost = AP_COSTS[tostring(command.__class)]

	-- destroy the command, since we executed it
	command:destroy()

	return cost
end

-- return the number of commands waiting to be executed
function HeroEntity:getPendingCommandCount()
	return self._commandQueue:size()
end

-- get the number of action points per tick of this entity
--   ap is the current number of action points
function HeroEntity:getSpeed(ap) return self._turnSpeed end

-- get and set the size of steps when moving
function HeroEntity:getStepSize() return self._stepSize end
function HeroEntity:setStepSize(v)
	self._stepSize = v
end

-- the class
return HeroEntity
