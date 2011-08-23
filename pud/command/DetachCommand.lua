local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- DetachCommand
--
local DetachCommand = Class{name='DetachCommand',
	inherits=Command,
	function(self, target, itemID)
		verifyClass('pud.component.ComponentMediator', target)
		verify('number', itemID)

		Command.construct(self, target)
		self._itemID = itemID
	end
}

-- destructor
function DetachCommand:destroy()
	self._itemID = nil
	Command.destroy(self)
end

function DetachCommand:execute()
	self._target:send(message('ATTACHMENT_DETACH'), self._itemID)
	local item = EntityRegistry:get(self._itemID)
	GameEvents:push(ConsoleEvent('Detach: %s -> %s',
		self._target:getName(), item:getName()))
	return Command.execute(self)
end

function DetachCommand:getItemID() return self._itemID end


-- the class
return DetachCommand
