local Class = require 'lib.hump.class'
local ModelComponent = getClass 'wyx.component.ModelComponent'
local Expression = getClass 'wyx.component.Expression'
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
			'_DamageMin',
			'_DamageMax',
		})
		ModelComponent.construct(self, properties)
		self:_addMessages('ENTITY_CREATED')
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
	elseif prop == property('_DamageMin')
		or prop == property('_DamageMax')
	then
		verify('number', data)
	else
		error('CombatComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function CombatComponent:getProperty(p, intermediate, ...)
	if   p == property('Attack')
		or p == property('Defense')
		or p == property('Damage')
		or p == property('AttackBonus')
		or p == property('DefenseBonus')
		or p == property('DamageBonus')
		or p == property('_DamageMin')
		or p == property('_DamageMax')
	then
		local prop = self:_evaluate(p)
		if not intermediate then return prop end
		return prop + intermediate
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end

function CombatComponent:receive(sender, msg, ...)
	if msg == message('ENTITY_CREATED') and sender == self._mediator then
		self:_determineDamageMinMax()
	end
	ModelComponent.receive(self, sender, msg, ...)
end

function CombatComponent:_determineDamageMinMax()
	local pDamage = property('Damage')
	local pDamageB = property('DamageBonus')

	local min, max

	for i=1,100 do
		local d = self:_evaluate(pDamage)
		local b = self:_evaluate(pDamageB)
		local t = d + b

		min = min and (min > t and t or min) or t
		max = max and (max < t and t or max) or t
	end

	min = min or 0
	max = max or 0

	self:_setProperty(property('_DamageMin'), min)
	self:_setProperty(property('_DamageMax'), max)
end


-- the class
return CombatComponent
