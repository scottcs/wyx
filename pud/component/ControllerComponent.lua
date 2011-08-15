local Class = require 'lib.hump.class'
local Component = getClass 'pud.component.Component'
local CommandEvent = getClass 'pud.event.CommandEvent'
local MoveCommand = getClass 'pud.command.MoveCommand'
local OpenDoorCommand = getClass 'pud.command.OpenDoorCommand'
local DoorMapType = getClass 'pud.map.DoorMapType'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

-- ControllerComponent
--
local ControllerComponent = Class{name='ControllerComponent',
	inherits=Component,
	function(self, newProperties)
		Component._addRequiredProperties(self, {'CanOpenDoors'})
		Component.construct(self, newProperties)
		self._attachMessages = {'COLLIDE_BLOCKED'}
	end
}

-- destructor
function ControllerComponent:destroy()
	Component.destroy(self)
end

function ControllerComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if prop == property('CanOpenDoors') then
		verify('boolean', data)
	end

	Component._setProperty(self, prop, data)
end

-- tell the mediator to move along vector v
function ControllerComponent:move(v)
	local command = MoveCommand(self._mediator, v)
	CommandEvents:push(CommandEvent(command))
end

function ControllerComponent:_tryToManipulateMap(node)
	local can = self._mediator:query(property('CanOpenDoors'), 'booland')
	if can and node:getMapType():isType(DoorMapType('shut')) then
		local command = OpenDoorCommand(self._mediator, node)
		CommandEvents:push(CommandEvent(command))
	end
end

function ControllerComponent:receive(msg, ...)
	if msg == message('COLLIDE_BLOCKED') then
		self:_tryToManipulateMap(...)
	else
		Component.receive(self, msg, ...)
	end
end


-- the class
return ControllerComponent
