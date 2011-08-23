local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local property = require 'pud.component.property'

-- PickupCommand
--
local PickupCommand = Class{name='PickupCommand',
	inherits=Command,
	function(self, target, itemID)
		verifyClass('pud.component.ComponentMediator', target)
		verify('number', itemID)

		Command.construct(self, target)
		self._itemID = itemID
	end
}

-- destructor
function PickupCommand:destroy()
	self._itemID = nil
	Command.destroy(self)
end

function PickupCommand:execute()
	self._target:send(message('CONTAINER_INSERT'), self._itemID)
	return Command.execute(self)
end

function PickupCommand:getItemID() return self._itemID end


-- the class
return PickupCommand
