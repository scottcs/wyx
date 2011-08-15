local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- TimeComponent
--
local TimeComponent = Class{name='TimeComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent._addRequiredProperties(self, {
			'AttackCost',
			'MoveCost',
			'DefaultCost',
			'Speed',
			'SpeedBonus',
			'IsExhausted',
			'DoTick',
		})
		ModelComponent.construct(self, properties)
		self._attachMessages = {'TIME_TICK'}
	end
}

-- destructor
function TimeComponent:destroy()
	ModelComponent.destroy(self)
end

function TimeComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if   prop == property('AttackCost')
		or prop == property('MoveCost')
		or prop == property('DefaultCost')
		or prop == property('Speed')
		or prop == property('SpeedBonus')
	then
		verify('number', data)
	elseif prop == property('IsExhausted')
		or   prop == property('DoTick')
	then
		verify('boolean', data)
	else
		error('TimeComponent does not support property: '..tostring(prop))
	end

	ModelComponent._setProperty(self, prop, data)
end


-- the class
return TimeComponent
