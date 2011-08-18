local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- MoveCommand
--
local MoveCommand = Class{name='MoveCommand',
	inherits=Command,
	function(self, target, x, y)
		verifyClass('pud.component.ComponentMediator', target)
		verify('number', x, y)

		Command.construct(self, target)
		self._x = x
		self._y = y
	end
}

-- destructor
function MoveCommand:destroy()
	self._x = nil
	self._y = nil
	Command.destroy(self)
end

function MoveCommand:execute(currAP)
	local pos = self._target:query(property('Position'))
	local newX, newY = pos[1] + self._x, pos[2] + self._y

	CollisionSystem:check(self._target, newX, newY)

	local canMove = self._target:query(property('CanMove'))
	if not canMove then return 0 end

	self._target:send(message('SET_POSITION'), {newX, newY}, pos)

	self._cost = self._target:query(property('MoveCost'))
	self._cost = self._cost or self._target:query(property('DefaultCost'))
	return Command.execute(self)
end

function MoveCommand:getX() return self._x end
function MoveCommand:getY() return self._y end

-- the class
return MoveCommand
