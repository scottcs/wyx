local Class = require 'lib.hump.class'
local ModelComponent = getClass 'wyx.component.ModelComponent'
local EntityDeathEvent = getClass 'wyx.event.EntityDeathEvent'
local EntityMaxHealthEvent = getClass 'wyx.event.EntityMaxHealthEvent'
local TimeSystemCycleEvent = getClass 'wyx.event.TimeSystemCycleEvent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

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
			'HealthRegen',
			'HealthRegenBonus',
		})
		ModelComponent.construct(self, properties)
		self:_addMessages('COMBAT_DAMAGE', 'ENTITY_DEATH')

		GameEvents:register(self, TimeSystemCycleEvent)
	end
}

-- destructor
function HealthComponent:destroy()
	GameEvents:unregisterAll(self)
	ModelComponent.destroy(self)
end

-- regen health on timesystem tick
function HealthComponent:TimeSystemCycleEvent(e)
	if self._mediator then
		local regen = self._mediator:query('HealthRegen')
		regen = regen + self._mediator:query('HealthRegenBonus')
		self:_modifyHealth(regen, 'Regeneration')
	end
end

function HealthComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if   prop == property('Health')
		or prop == property('MaxHealth')
		or prop == property('HealthBonus')
		or prop == property('MaxHealthBonus')
		or prop == property('HealthRegen')
		or prop == property('HealthRegenBonus')
	then
		verifyAny(data, 'number', 'expression')
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

	if health > 0 then
		health = health + amount
		self:_setProperty(pHealth, health)

		self._mediator:send(message('HEALTH_UPDATE'))
		self:_checkHealth(actor)
	end
end

function HealthComponent:_modifyMaxHealth(amount, actor)
	local pMaxHealth = property('MaxHealth')
	local maxHealth = self:getProperty(pMaxHealth)

	maxHealth = maxHealth + amount
	self:_setProperty(pMaxHealth, maxHealth)

	self:_checkHealth(actor)
	self._mediator:send(message('HEALTH_UPDATE'))

	GameEvents:push(EntityMaxHealthEvent(self._mediator:getID()))
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

function HealthComponent:receive(sender, msg, ...)
	if     msg == message('COMBAT_DAMAGE') and sender == self._mediator then
		if select('#', ...) > 0 then self:_modifyHealth(...) end
	elseif msg == message('ENTITY_DEATH') and sender == self._mediator then
		GameEvents:push(EntityDeathEvent(self._mediator, ...))
	end
	ModelComponent.receive(self, sender, msg, ...)
end

function HealthComponent:getProperty(p, intermediate, ...)
	if   p == property('Health')
		or p == property('MaxHealth')
		or p == property('HealthBonus')
		or p == property('MaxHealthBonus')
		or p == property('HealthRegen')
		or p == property('HealthRegenBonus')
	then
		local prop = self:_evaluate(p)
		if not intermediate then return prop end
		return prop + intermediate
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end


-- the class
return HealthComponent
