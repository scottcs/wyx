require 'pud.util'
local Class = require 'lib.hump.class'
local Event = require 'pud.event.Event'
local Command = require 'pud.command.Command'

-- Command Event - fires when a command needs to be executed
local CommandEvent = Class{name='CommandEvent',
	inherits=Event,
	function(self, command)
		assert(command and command.is_a and command:is_a(Command),
			self:_msg('command must be a Command (not %s (%s))',
				type(command), tostring(command)))
		Event.construct(self, 'Command Event')

		self._command = command
	end
}

function CommandEvent:getCommand() return self._command end

-- the class
return CommandEvent
