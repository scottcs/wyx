local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- HealthComponent
--
local HealthComponent = Class{name='HealthComponent',
	inherits=ModelComponent,
	function(self, properties)
		self._requiredProperties = {
			'Health',
			'MaxHealth',
			'HealthBonus',
			'MaxHealthBonus',
		}
		Component.construct(self, properties)
	end
}

-- destructor
function HealthComponent:destroy()
	Component.destroy(self)
end


-- the class
return HealthComponent
