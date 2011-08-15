local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'
local InputComponent = getClass 'pud.component.InputComponent'
local KeyboardEvent = getClass 'pud.event.KeyboardEvent'
local property = require 'pud.component.property'

-- PlayerInputComponent
--
local PlayerInputComponent = Class{name='PlayerInputComponent',
	inherits=InputComponent,
	function(self, properties)
		InputComponent.construct(self, properties)
		InputEvents:register(self, KeyboardEvent)
	end
}

-- destructor
function PlayerInputComponent:destroy()
	InputEvents:unregisterAll(self)
	InputComponent.destroy(self)
end

function PlayerInputComponent:_setProperty(prop, data)
	if prop == property('CanOpenDoors') then data = true end
	InputComponent._setProperty(self, prop, data)
end

-- on keyboard input, issue the appropriate command
function PlayerInputComponent:KeyboardEvent(e)
	if #(e:getModifiers()) == 0 then
		local key = e:getKey()
		local doTick = false

		if key == 'up' or key == 'k' or key == 'kp8' then
			self:move(vector( 0, -1))
			doTick = true
		elseif key == 'down' or key == 'j' or key == 'kp2' then
			self:move(vector( 0,  1))
			doTick = true
		elseif key == 'left' or key == 'h' or key == 'kp4' then
			self:move(vector(-1,  0))
			doTick = true
		elseif key == 'right' or key == 'l' or key == 'kp6' then
			self:move(vector( 1,  0))
			doTick = true
		elseif key == 'y' or key == 'kp7' then
			self:move(vector(-1,  -1))
			doTick = true
		elseif key == 'u' or key == 'kp9' then
			self:move(vector( 1,  -1))
			doTick = true
		elseif key == 'b' or key == 'kp1' then
			self:move(vector(-1,   1))
			doTick = true
		elseif key == 'n' or key == 'kp3' then
			self:move(vector( 1,   1))
			doTick = true
		end

		if doTick then self:_setProperty(property('DoTick'), true) end
	end
end

-- the class
return PlayerInputComponent
