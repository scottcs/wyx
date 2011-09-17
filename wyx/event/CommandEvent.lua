local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- Command Event - fires when a command needs to be executed
local CommandEvent = Class{name='CommandEvent',
	inherits=Event,
	function(self, command)
		verifyClass('wyx.command.Command', command)
		Event.construct(self, 'Command Event')

		self._command = command
	end
}

-- destructor
function CommandEvent:destroy()
	self._command = nil
	Event.destroy(self)
end

-- return the command
function CommandEvent:getCommand() return self._command end

function CommandEvent:__tostring()
	return self:_msg('%s', tostring(self._command))
end


-- the class
return CommandEvent
