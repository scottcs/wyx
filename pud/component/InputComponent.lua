local Class = require 'lib.hump.class'
local ControllerComponent = getClass 'pud.component.ControllerComponent'
local message = require 'pud.component.message'
local EntityPositionEvent = getClass 'pud.event.EntityPositionEvent'


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
	GameEvents:push(EntityPositionEvent(self._mediator, v))
end


-- the class
return InputComponent
