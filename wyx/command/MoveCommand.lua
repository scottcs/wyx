local Class = require 'lib.hump.class'
local Command = getClass 'wyx.command.Command'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

-- MoveCommand
--
local MoveCommand = Class{name='MoveCommand',
	inherits=Command,
	function(self, target, x, y)
		verifyClass('wyx.component.ComponentMediator', target)
		verify('number', x, y)

		Command.construct(self, target)
		self._costProp = property('MoveCost')
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

	self._target:send(message('SET_POSITION'), self._x, self._y, pos[1], pos[2])

	return Command.execute(self)
end

function MoveCommand:getX() return self._x end
function MoveCommand:getY() return self._y end

-- the class
return MoveCommand
