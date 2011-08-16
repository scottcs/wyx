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
		if type(data) == 'string' then
			verify('number', self:_evaluate(data))
		else
			verify('number', data)
		end
	else
		error('HealthComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function HealthComponent:_evaluate(prop)
	return 1
end

function HealthComponent:getProperty(p, intermediate, ...)
	if   prop == property('Health')
		or prop == property('MaxHealth')
		or prop == property('HealthBonus')
		or prop == property('MaxHealthBonus')
	then
		local prop = self._properties[p]
		local doEval = type(prop) == 'string'

		if doEval then prop = self:_evaluate(prop) end

		if not intermediate then return prop end
		return prop + intermediate
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end

-- the class
return HealthComponent
