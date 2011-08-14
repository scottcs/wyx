local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- TimeComponent
--
local TimeComponent = Class{name='TimeComponent',
	inherits=ModelComponent,
	function(self, properties)
		self:_addRequiredProperties{
			'AttackCost',
			'MoveCost',
			'DefaultCost',
			'Speed',
			'SpeedBonus',
		}
		ModelComponent.construct(self, properties)
	end
}

-- destructor
function TimeComponent:destroy()
	ModelComponent.destroy(self)
end


-- the class
return TimeComponent
