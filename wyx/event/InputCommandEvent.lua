local Class = require 'lib.hump.class'
local Event = getClass 'wyx.event.Event'
local command = require 'wyx.ui.command'

-- InputCommand Event - fires when a command needs to be executed
local InputCommandEvent = Class{name='InputCommandEvent',
	inherits=Event,
	function(self, cmd, ...)
		cmd = command(cmd)
		Event.construct(self, 'Input Command Event')

		self._command = cmd
		if select('#', ...) > 0 then self._commandArgs = {...} end
	end
}

-- destructor
function InputCommandEvent:destroy()
	self._command = nil
	if self._commandArgs then
		for k in pairs(self._commandArgs) do self._commandArgs[k] = nil end
		self._commandArgs = nil
	end

	Event.destroy(self)
end

-- return the command
function InputCommandEvent:getCommand() return self._command end
function InputCommandEvent:getCommandArgs() return self._commandArgs end

-- the class
return InputCommandEvent
