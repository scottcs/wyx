local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local TimedObject = require 'pud.time.TimedObject'
local Deque = require 'pud.kit.Deque'

-- events this entity listens for
local CommandEvent = require 'pud.event.CommandEvent'

-- commands this entity implements
local MoveCommand = require 'pud.command.MoveCommand'

-- default action point costs for commands
local AP_COSTS = {
	MoveCommand = 1,
	AttackCommand = 1.5,
}

-- default turn speed
local AP_PER_TURN = 1.0

-- HeroEntity
--
local HeroEntity = Class{name='HeroEntity',
	inherits={Entity, TimedObject},
	function(self)
		Entity.construct(self)
		TimedObject.construct(self)
		CommandEvents:register(self, CommandEvent)

		self._commandQueue = Deque()
		self._turnSpeed = AP_PER_TURN
	end
}

-- destructor
function HeroEntity:destroy()
	self._turnSpeed = nil
	self._commandQueue:destroy()
	self._commandQueue = nil

	CommandEvents:unregisterAll(self)
	Movable.destroy(self)
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
	return AP_COSTS[tostring(command.__class)]
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
