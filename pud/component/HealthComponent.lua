local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- HealthComponent
--
local HealthComponent = Class{name='HealthComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'Health',
			'MaxHealth',
			'HealthBonus',
			'MaxHealthBonus',
		})
		ModelComponent.construct(self, properties)
	end
}

-- destructor
function HealthComponent:destroy()
	ModelComponent.destroy(self)
end

function HealthComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if   prop == property('Health')
		or prop == property('MaxHealth')
		or prop == property('HealthBonus')
		or prop == property('MaxHealthBonus')
	then
		-- TODO: commented out because I'm giving strings right now, thinking I
		-- can support lua code in the property
		--verify('number', data)
	else
		error('HealthComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end


-- the class
return HealthComponent
