local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- DropCommand
--
local DropCommand = Class{name='DropCommand',
	inherits=Command,
	function(self, target, itemID)
		verifyClass('pud.component.ComponentMediator', target)
		verify('string', itemID)

		Command.construct(self, target)
		self._itemID = itemID
	end
}

-- destructor
function DropCommand:destroy()
	self._itemID = nil
	Command.destroy(self)
end

function DropCommand:execute()
	self._target:send(message('CONTAINER_REMOVE'), self._itemID)
	local item = EntityRegistry:get(self._itemID)
	GameEvents:push(ConsoleEvent('Drop: %s {%08s} -> %s {%08s}',
		self._target:getName(), self._target:getID(),
		item:getName(), self._itemID))
	return Command.execute(self)
end

function DropCommand:getItemID() return self._itemID end


-- the class
return DropCommand
