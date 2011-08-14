local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- MoveCommand
--
local MoveCommand = Class{name='MoveCommand',
	inherits=Command,
	function(self, target, vector)
		verifyClass('pud.component.ComponentMediator', target)
		verify('vector', vector)

		Command.construct(self, target)
		self._vector = vector
	end
}

-- destructor
function MoveCommand:destroy()
	self._vector = nil
	Command.destroy(self)
end

function MoveCommand:execute(currAP)
	local pos = self._target:query(property('Position'))
	local newpos = pos + self._vector

	CollisionSystem:check(self._target, newpos)

	local canMove = self._target:query(property('CanMove'), 'booland')
	if not canMove then return 0 end

	self._target:send(message('SET_POSITION'), newpos, pos)

	self._cost = self._target:query(property('MoveCost'))
	self._cost = self._cost or self._target:query(property('DefaultCost'))
	Command.execute(self)
end

function MoveCommand:getVector() return self._vector:clone() end

-- the class
return MoveCommand
