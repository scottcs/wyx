local Class = require 'lib.hump.class'
local Component = getClass 'pud.component.Component'

-- ControllerComponent
--
local ControllerComponent = Class{name='ControllerComponent',
	inherits=Component,
	function(self, newProperties)
		self:_addRequiredProperties{
			'CanOpenDoors',
		}
		Component.construct(self, newProperties)
	end
}

-- destructor
function ControllerComponent:destroy()
	Component.destroy(self)
end

-- update
function Component:update() end


-- the class
return ControllerComponent
