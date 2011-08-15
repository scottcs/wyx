local Class = require 'lib.hump.class'
local TimeComponent = getClass 'pud.component.TimeComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- PlayerTimeComponent
--
local PlayerTimeComponent = Class{name='PlayerTimeComponent',
	inherits=TimeComponent,
	function(self, properties)
		TimeComponent.construct(self, properties)
	end
}

-- destructor
function PlayerTimeComponent:destroy()
	TimeComponent.destroy(self)
end

function PlayerTimeComponent:_setProperty(prop, data)
	if prop == property('DoTick') then data = false end
	TimeComponent._setProperty(self, prop, data)
end

function PlayerTimeComponent:receive(msg, ...)
	if msg == message('TIME_TICK') then
		self:_setProperty(property('DoTick'), false)
	else
		TimeComponent.receive(self, msg, ...)
	end
end


-- the class
return PlayerTimeComponent
