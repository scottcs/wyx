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
		self._attachMessages = {'COLLIDE_ENEMY', 'COLLIDE_HERO'}
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
		if type(data) == 'string' then
			verify('number', self:_evaluate(data))
		else
			verify('number', data)
		end
	else
		error('CombatComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function CombatComponent:receive(msg, ...)
	if msg == message('COLLIDE_ENEMY')
		or msg == message('COLLIDE_HERO')
	then
		local opponent = select(1, ...)
		if opponent then self:_attack(opponent) end
	end
end

function CombatComponent:getProperty(p, intermediate, ...)
	if   prop == property('Attack')
		or prop == property('Defense')
		or prop == property('AttackBonus')
		or prop == property('DefenseBonus')
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

function CombatComponent:_attack(opponent)
	local oDefense = opponent:query(property('Defense'))
	oDefense = oDefense + opponent:query(property('DefenseBonus'))
	local attack = self._mediator:query(property('Attack'))
	attack = attack + self._mediator:query(property('AttackBonus'))
	attack = attack + (Random:number() > 0.5 and 1 or 0)

	if attack > oDefense then
		local name = self._mediator:getName() or tostring(self._mediator)
		opponent:send(message('COMBAT_DAMAGE'), -1, name)
	end
end


-- the class
return CombatComponent
