local Class = require 'lib.hump.class'
local Command = getClass 'pud.command.Command'
local ConsoleEvent = getClass 'pud.event.ConsoleEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

-- AttachCommand
--
local AttachCommand = Class{name='AttachCommand',
	inherits=Command,
	function(self, target, itemID)
		verifyClass('pud.component.ComponentMediator', target)
		verify('string', itemID)

		Command.construct(self, target)
		self._itemID = itemID
	end
}

-- destructor
function AttachCommand:destroy()
	self._itemID = nil
	Command.destroy(self)
end

function AttachCommand:execute()
	self._target:send(message('ATTACHMENT_ATTACH'), self._itemID)
	local item = EntityRegistry:get(self._itemID)
	GameEvents:push(ConsoleEvent('Attach: %s {%08s} -> %s {%08s}',
		self._target:getName(), self._target:getID(),
		item:getName(), self._itemID))
	return Command.execute(self)
end

function AttachCommand:getItemID() return self._itemID end


-- the class
return AttachCommand
