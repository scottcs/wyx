local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- CombatComponent
--
local CombatComponent = Class{name='CombatComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'Attack',
			'Defense',
			'AttackBonus',
			'DefenseBonus',
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
	if nil == data then data = property.default(prop) end

	if   prop == property('Attack')
		or prop == property('Defense')
		or prop == property('AttackBonus')
		or prop == property('DefenseBonus')
	then
		verify('number', data)
	else
		error('CombatComponent does not support property: '..tostring(prop))
	end

	self._properties[prop] = data
end


-- the class
return CombatComponent
