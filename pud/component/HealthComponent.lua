local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- HealthComponent
--
local HealthComponent = Class{name='HealthComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent.construct(self, properties)
		self:_addRequiredProperties({
			'Health',
			'MaxHealth',
			'HealthBonus',
			'MaxHealthBonus',
		})
	end
}

-- destructor
function HealthComponent:destroy()
	ModelComponent.destroy(self)
end


-- the class
return HealthComponent
