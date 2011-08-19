local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'

-- AttackCommand
--
local AttackCommand = Class{name='AttackCommand',
	inherits=Command,
	function(self, source, target)
		verifyClass('pud.component.ComponentMediator', source, target)

		Command.construct(self, target)
		self._source = source
	end
}

-- destructor
function AttackCommand:destroy()
	self._x = nil
	self._y = nil
	Command.destroy(self)
end

function AttackCommand:execute(currAP)
	return Command.execute(self)
end

function AttackCommand:getSource() return self._source end

-- the class
return AttackCommand
