local Class = require 'lib.hump.class'
local ControllerComponent = getClass 'pud.component.ControllerComponent'
local message = require 'pud.component.message'
local CommandEvent = getClass 'pud.event.CommandEvent'
local MoveCommand = getClass 'pud.command.MoveCommand'


-- InputComponent
--
local InputComponent = Class{name='InputComponent',
	inherits=ControllerComponent,
	function(self, properties)
		ControllerComponent.construct(self, properties)
	end
}

-- destructor
function InputComponent:destroy()
	ControllerComponent.destroy(self)
end

-- tell the mediator to move along vector v
function InputComponent:move(v)
	local command = MoveCommand(self._mediator, v)
	CommandEvents:push(CommandEvent(command))
end


-- the class
return InputComponent
