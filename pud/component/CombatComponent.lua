local Class = require 'lib.hump.class'
local ModelComponent = getClass 'pud.component.ModelComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'


-- CombatComponent
--
local CombatComponent = Class{name='CombatComponent',
	inherits=ModelComponent,
	function(self, properties)
		ModelComponent.construct(self, properties)
		self:_addRequiredProperties({
			'Attack',
			'Defense',
			'AttackBonus',
			'DefenseBonus',
		})
	end
}

-- destructor
function CombatComponent:destroy()
	ModelComponent.destroy(self)
end


-- the class
return CombatComponent
