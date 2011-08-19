local Class = require 'lib.hump.class'
local InputComponent = getClass 'pud.component.InputComponent'
local message = require 'pud.component.message'

-- AIInputComponent
--
local AIInputComponent = Class{name='AIInputComponent',
	inherits=InputComponent,
	function(self, properties)
		InputComponent.construct(self, properties)
		self:_addMessages('TIME_TICK')
	end
}

-- destructor
function AIInputComponent:destroy()
	InputComponent.destroy(self)
end

-- figure out what to do on next tick
function AIInputComponent:_determineNextAction()
	if Random(100) > -1 then
		local x = Random(3) - 2
		local y = Random(3) - 2
		self:move(x, y)
		self:move(x, y)
		self:move(x, y)
		self:move(x, y)
	end
end

function AIInputComponent:receive(msg, ...)
	if msg == message('TIME_TICK') then
		self:_determineNextAction()
	else
		InputComponent.receive(self, msg, ...)
	end
end


-- the class
return AIInputComponent
