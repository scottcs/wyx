local Class = require 'lib.hump.class'
local ControllerComponent = getClass 'pud.component.ControllerComponent'


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


-- the class
return InputComponent
