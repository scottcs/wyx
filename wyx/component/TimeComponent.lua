local Class = require 'lib.hump.class'
local ModelComponent = getClass 'wyx.component.ModelComponent'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'


-- TimeComponent
--
local TimeComponent = Class{name='TimeComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'AttackCost',
			'AttackCostBonus',
			'MoveCost',
			'MoveCostBonus',
			'WaitCost',
			'WaitCostBonus',
			'DefaultCost',
			'Speed',
			'SpeedBonus',
			'IsExhausted',
			'DoTick',
		})
		ModelComponent.construct(self, properties)
		self:_addMessages('TIME_AUTO')
	end
}

-- destructor
function TimeComponent:destroy()
	ModelComponent.destroy(self)
end

function TimeComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if   prop == property('AttackCost')
		or prop == property('AttackCostBonus')
		or prop == property('MoveCost')
		or prop == property('MoveCostBonus')
		or prop == property('WaitCost')
		or prop == property('WaitCostBonus')
		or prop == property('DefaultCost')
		or prop == property('Speed')
		or prop == property('SpeedBonus')
	then
		verifyAny(data, 'number', 'expression')
	elseif prop == property('IsExhausted')
		or   prop == property('DoTick')
	then
		verifyAny(data, 'boolean', 'expression')
	else
		error('TimeComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end

function TimeComponent:isExhausted()
	return self:getProperty(property('IsExhausted'))
end

function TimeComponent:exhaust()
	self:_setProperty('IsExhausted', true)
end

function TimeComponent:shouldTick()
	return self._mediator:query(property('DoTick'))
end

function TimeComponent:getTotalSpeed()
	local speed = self._mediator:query(property('Speed'))
	speed = speed + self._mediator:query(property('SpeedBonus'))
	return speed
end

function TimeComponent:onPreTick(ap)
	self._mediator:send(message('TIME_PRETICK'), ap)
end

function TimeComponent:onPostTick(ap)
	self._mediator:send(message('TIME_POSTTICK'), ap)
end

function TimeComponent:onPreExecute(ap)
	self._mediator:send(message('TIME_PREEXECUTE'), ap)
end

function TimeComponent:onPostExecute(ap)
	self._mediator:send(message('TIME_POSTEXECUTE'), ap)
end

function TimeComponent:getProperty(p, intermediate, ...)
	if p == property('DoTick') then
		local prop = self:_evaluate(p)
		if nil == intermediate then return prop end
		return (prop or intermediate)
	else
		return ModelComponent.getProperty(self, p, intermediate, ...)
	end
end

function TimeComponent:receive(sender, msg, ...)
	if msg == message('TIME_AUTO') and sender == self._mediator then
		self:_setProperty(property('DoTick'), select(1, ...))
	end
	ModelComponent.receive(self, sender, msg, ...)
end


-- the class
return TimeComponent
