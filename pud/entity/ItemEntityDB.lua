local Class = require 'lib.hump.class'
local EntityDB = getClass 'pud.entity.EntityDB'
local ItemEntityFactory = getClass 'pud.entity.ItemEntityFactory'

-- ItemEntityDB
--
local ItemEntityDB = Class{name='ItemEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'item')
		self._factory = ItemEntityFactory()
	end
}

-- destructor
function ItemEntityDB:destroy()
	self._factory:destroy()
	self._factory = nil
	EntityDB.destroy(self)
end

function ItemEntityDB:_getPropertyWeights()
	local props = {
		health     = {name = 'Health',         weight = 1.1},
		healthB    = {name = 'HealthBonus',    weight = 1.1},
		maxHealth  = {name = 'MaxHealth',      weight = 1.2},
		maxHealthB = {name = 'MaxHealthBonus', weight = 1.2},
		visibility = {name = 'Visibility',     weight = 1.3},
		visibility = {name = 'VisibilityBonus',weight = 1.3},
		defense    = {name = 'Defense',        weight = 0.9},
		defenseB   = {name = 'DefenseBonus',   weight = 0.9},
		attack     = {name = 'Attack',         weight = 0.9},
		attackB    = {name = 'AttackBonus',    weight = 0.9},
		speed      = {name = 'Speed',          weight = 1.4},
		speedB     = {name = 'SpeedBonus',     weight = 1.4},
	}

	return props
end


-- the class
return ItemEntityDB
