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
		})
		ModelComponent.construct(self, properties)
	end
}

-- destructor
function TimeComponent:destroy()
	ModelComponent.destroy(self)
end

function TimeComponent:isExhausted()
	return self._mediator:query(property('IsExhausted'), 'boolor')
end

function TimeComponent:getTotalSpeed()
	local speed = self._mediator:query(property('Speed'))
	speed = speed + self._mediator:query(property('SpeedBonus'))
	return speed
end

-- the class
return TimeComponent
