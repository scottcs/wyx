local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

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
	local item = EntityRegistry:get(self._itemID)
	GameEvents:push(ConsoleEvent('Pickup: %s {%08d} -> %s {%08d}',
		self._target:getName(), self._target:getID(),
		item:getName(), self._itemID))
	return Command.execute(self)
end

function PickupCommand:getItemID() return self._itemID end


-- the class
return PickupCommand
