local Class = require 'lib.hump.class'
local Command = getClass 'wyx.command.Command'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

-- PickupCommand
--
local PickupCommand = Class{name='PickupCommand',
	inherits=Command,
	function(self, target, itemID, slot)
		verifyClass('wyx.component.ComponentMediator', target)
		verify('string', itemID)

		Command.construct(self, target)
		self._itemID = itemID
		self._slot = slot
	end
}

-- destructor
function PickupCommand:destroy()
	self._itemID = nil
	Command.destroy(self)
end

function PickupCommand:execute()
	self._target:send(message('CONTAINER_INSERT'), self._itemID, self._slot)
	local item = EntityRegistry:get(self._itemID)
	local slot = ''
	if self._slot then slot = ' slot: '..tostring(self._slot) end

	GameEvents:push(ConsoleEvent('Pickup: %s {%08s} -> %s {%08s}%s',
		self._target:getName(), self._target:getID(),
		item:getName(), self._itemID, slot))

	return Command.execute(self)
end

function PickupCommand:getItemID() return self._itemID end
function PickupCommand:getSlot() return self._slot end

function PickupCommand:__tostring()
	local slot = ''
	if self._slot then slot = ' slot: '..tostring(self._slot) end
	return self:_msg('{%08s} {%08s}%s', self:_getTargetString(), self._itemID,
		slot)
end


-- the class
return PickupCommand
