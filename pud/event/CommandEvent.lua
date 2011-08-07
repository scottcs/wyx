require 'pud.util'
local Class = require 'lib.hump.class'
local Event = require 'pud.event.Event'
local Command = require 'pud.command.Command'

-- Command Event - fires when a command needs to be executed
local CommandEvent = Class{name='CommandEvent',
	inherits=Event,
	function(self, command)
		verifyClass(Command, command)
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

-- the class
return CommandEvent
