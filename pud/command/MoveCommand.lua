local Class = require 'lib.hump.class'
local Command = getClass('pud.command.Command')

-- MoveCommand
--
local MoveCommand = Class{name='MoveCommand',
	inherits=Command,
	function(self, target, vector, node)
		verifyClass('pud.entity.Traveler', target)
		verify('vector', vector)

		Command.construct(self, target)

		if target.getStepSize then
			local step = target:getStepSize()
			if step then
				self._vector = vector
				self._vector.x = self._vector.x * step.x
				self._vector.y = self._vector.y * step.y
			end
		end

		self._vector = self._vector or vector
		self._node = node
	end
}

-- destructor
function MoveCommand:destroy()
	self._vector = nil
	Command.destroy(self)
end

function MoveCommand:execute()
	local pos = self._target:getPositionVector()
	self._target:setMovePosition(pos + self._vector)
end

function MoveCommand:getVector() return self._vector:clone() end

-- the class
return MoveCommand
