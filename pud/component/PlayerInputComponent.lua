local Class = require 'lib.hump.class'
local InputComponent = getClass 'pud.component.InputComponent'
local KeyboardEvent = getClass 'pud.event.KeyboardEvent'
local message = require 'pud.component.message'
local property = require 'pud.component.property'

local InputEvents = InputEvents

-- PlayerInputComponent
--
local PlayerInputComponent = Class{name='PlayerInputComponent',
	inherits=InputComponent,
	function(self, properties)
		InputComponent.construct(self, properties)
		self:_addMessages('TIME_PRETICK')
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

		if key == '.' or key == 'kp5' then
			self:_wait()
			doTick = true
		elseif key == 'up' or key == 'k' or key == 'kp8' then
			self:_attemptMove( 0, -1)
			doTick = true
		elseif key == 'down' or key == 'j' or key == 'kp2' then
			self:_attemptMove( 0,  1)
			doTick = true
		elseif key == 'left' or key == 'h' or key == 'kp4' then
			self:_attemptMove(-1,  0)
			doTick = true
		elseif key == 'right' or key == 'l' or key == 'kp6' then
			self:_attemptMove( 1,  0)
			doTick = true
		elseif key == 'y' or key == 'kp7' then
			self:_attemptMove(-1,  -1)
			doTick = true
		elseif key == 'u' or key == 'kp9' then
			self:_attemptMove( 1,  -1)
			doTick = true
		elseif key == 'b' or key == 'kp1' then
			self:_attemptMove(-1,   1)
			doTick = true
		elseif key == 'n' or key == 'kp3' then
			self:_attemptMove( 1,   1)
			doTick = true
		elseif key == ';' or key == 'kp.' then
			self:_tryToPickup()
			doTick = true
		end

		if doTick then self:_setProperty(property('DoTick'), true) end
	end
end

function PlayerInputComponent:receive(msg, ...)
	if msg == message('TIME_PRETICK') then
		self:_setProperty(property('DoTick'), false)
	else
		InputComponent.receive(self, msg, ...)
	end
end


-- the class
return PlayerInputComponent
