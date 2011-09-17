local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'

-- Command Event - fires when a command needs to be executed
local CommandEvent = Class{name='CommandEvent',
	inherits=Event,
	function(self, command, immediate)
		verifyClass('wyx.command.Command', command)
		Event.construct(self, 'Command Event')

		self._command = command
		self._immediate = immediate
	end
}

-- destructor
function CommandEvent:destroy()
	self._command = nil
	self._immediate = nil
	Event.destroy(self)
end

-- return the command
function CommandEvent:getCommand() return self._command end
function CommandEvent:isImmediate() return self._immediate == true end

function CommandEvent:__tostring()
	return self:_msg('%s (%s)', tostring(self._command),
		(self._immediate and 'immediate' or 'queued'))
end


-- the class
return CommandEvent
