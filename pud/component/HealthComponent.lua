local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local EntityDeathEvent = getClass 'pud.event.EntityDeathEvent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'

local GameEvents = GameEvents

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
		self:_addMessages('COMBAT_DAMAGE', 'ENTITY_DEATH')
	end
}

-- destructor
function HealthComponent:destroy()
	ModelComponent.destroy(self)
end

function HealthComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
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

function HealthComponent:_sendDeathMessage(actor)
	local msg
	if actor then msg = tostring(actor)
	else msg = 'ceased to exist' end
	self._mediator:send(message('ENTITY_DEATH'), msg)
end

function HealthComponent:_modifyHealth(amount, actor)
	local pHealth = property('Health')
	local health = self:getProperty(pHealth)

	health = health + amount
	self:_setProperty(pHealth, health)

	self._mediator:send(message('HEALTH_UPDATE'))
	self:_checkHealth(actor)
end

function HealthComponent:_modifyMaxHealth(amount, actor)
	local pMaxHealth = property('MaxHealth')
	local maxHealth = self:getProperty(pMaxHealth)

	maxHealth = maxHealth + amount
	self:_setProperty(pMaxHealth, maxHealth)

	self:_checkHealth(actor)
	self._mediator:send(message('HEALTH_UPDATE'))
end

function HealthComponent:_checkHealth(...)
	local pHealth = property('Health')
	local max = self._mediator:query(property('MaxHealth'))
	local maxBonus = self._mediator:query(property('MaxHealthBonus'))
	local health = self._mediator:query(pHealth)
	local healthBonus = self._mediator:query(property('HealthBonus'))

	health = health or 0
	healthBonus = healthBonus or 0
	max = max or 0
	maxBonus = maxBonus or 0

	local totalHealth = health + healthBonus
	local totalMax = max + maxBonus

	if totalHealth > totalMax then
		health = health - (totalHealth - totalMax)
		self:_setProperty(pHealth, health)
		totalHealth = health + healthBonus
	end

	if totalHealth <= 0 then self:_sendDeathMessage(...) end
end

function HealthComponent:receive(msg, ...)
	if     msg == message('COMBAT_DAMAGE') then
		if select('#', ...) > 0 then self:_modifyHealth(...) end
	elseif msg == message('ENTITY_DEATH') then
		GameEvents:push(EntityDeathEvent(self._mediator, ...))
	end
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
