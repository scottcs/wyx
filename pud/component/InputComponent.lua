local Class = require 'lib.hump.class'
local ControllerComponent = getClass 'pud.component.ControllerComponent'
local message = require 'pud.component.message'
local property = require 'pud.component.property'
local CommandEvent = getClass 'pud.event.CommandEvent'
local MoveCommand = getClass 'pud.command.MoveCommand'
local OpenDoorCommand = getClass 'pud.command.OpenDoorCommand'
local DoorMapType = getClass 'pud.map.DoorMapType'


-- InputComponent
--
local InputComponent = Class{name='InputComponent',
	inherits=ControllerComponent,
	function(self, properties)
		ControllerComponent.construct(self, properties)
		self._attachMessages = {'COLLIDE_BLOCKED'}
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

function InputComponent:_tryToManipulateMap(node)
	local can = self._mediator:query(property('CanOpenDoors'), 'booland')
	if can and node:getMapType():isType(DoorMapType('shut')) then
		local command = OpenDoorCommand(self._mediator, node)
		CommandEvents:push(CommandEvent(command))
	end
end

function InputComponent:receive(msg, ...)
	if msg == message('COLLIDE_BLOCKED') then
		self:_tryToManipulateMap(...)
	else
		ControllerComponent.receive(self, msg, ...)
	end
end


-- the class
return InputComponent
