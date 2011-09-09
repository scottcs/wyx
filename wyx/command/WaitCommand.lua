local Class = require 'lib.hump.class'
local Command = getClass 'wyx.command.Command'
local property = require 'wyx.component.property'

-- WaitCommand
--
local WaitCommand = Class{name='WaitCommand',
	inherits=Command,
	function(self, target)
		verifyClass('wyx.component.ComponentMediator', target)

		Command.construct(self, target)
		self._costProp = property('WaitCost')
	end
}

-- destructor
function WaitCommand:destroy()
	Command.destroy(self)
end


-- the class
return WaitCommand
