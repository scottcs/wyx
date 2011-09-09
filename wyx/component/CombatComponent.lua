local Class = require 'lib.hump.class'
local ModelComponent = getClass 'wyx.component.ModelComponent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'


-- CombatComponent
--
local CombatComponent = Class{name='CombatComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'Attack',
			'Defense',
			'Damage',
			'AttackBonus',
			'DefenseBonus',
			'DamageBonus',
		})
		ModelComponent.construct(self, properties)
	end
}

-- destructor
function CombatComponent:destroy()
	ModelComponent.destroy(self)
end

function CombatComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if   prop == property('Attack')
		or prop == property('Defense')
		or prop == property('Damage')
		or prop == property('AttackBonus')
		or prop == property('DefenseBonus')
		or prop == property('DamageBonus')
	then
		verifyAny(data, 'number', 'expression')
	else
		error('CombatComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function CombatComponent:getProperty(p, intermediate, ...)
	if   prop == property('Attack')
		or prop == property('Defense')
		or prop == property('Damage')
		or prop == property('AttackBonus')
		or prop == property('DefenseBonus')
		or prop == property('DamageBonus')
	then
		local prop = self:_evaluate(p)
		if not intermediate then return prop end
		return prop + intermediate
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return CombatComponent
