local Class = require 'lib.hump.class'
local Command = getClass 'wyx.command.Command'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

-- PickupCommand
--
local PickupCommand = Class{name='PickupCommand',
	inherits=Command,
	function(self, target, itemID)
		verifyClass('wyx.component.ComponentMediator', target)
		verify('string', itemID)

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
	GameEvents:push(ConsoleEvent('Pickup: %s {%08s} -> %s {%08s}',
		self._target:getName(), self._target:getID(),
		item:getName(), self._itemID))
	return Command.execute(self)
end

function PickupCommand:getItemID() return self._itemID end

function PickupCommand:__tostring()
	return self:_msg('{%08s} {%08s}', self:_getTargetString(), self._itemID)
end


-- the class
return PickupCommand
