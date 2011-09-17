local Class = require 'lib.hump.class'
local Command = getClass 'wyx.command.Command'
local ConsoleEvent = getClass 'wyx.event.ConsoleEvent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

-- DetachCommand
--
local DetachCommand = Class{name='DetachCommand',
	inherits=Command,
	function(self, target, itemID)
		verifyClass('wyx.component.ComponentMediator', target)
		verify('string', itemID)

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
	GameEvents:push(ConsoleEvent('Detach: %s {%08s} -> %s {%08s}',
		self._target:getName(), self._target:getID(),
		item:getName(), self._itemID))
	return Command.execute(self)
end

function DetachCommand:getItemID() return self._itemID end

function DetachCommand:__tostring()
	return self:_msg('{%08s} {%08s}', self:_getTargetString(), self._itemID)
end


-- the class
return DetachCommand
