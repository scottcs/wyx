local Class = require 'lib.hump.class'
local EntityDB = getClass 'wyx.entity.EntityDB'
local EnemyEntityFactory = getClass 'wyx.entity.EnemyEntityFactory'
local property = require 'wyx.component.property'

local math_floor = math.floor
local _round = function(x) return math_floor(x+0.5) end

-- EnemyEntityDB
--
local EnemyEntityDB = Class{name='EnemyEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'enemy')
		self._factory = EnemyEntityFactory()
	end
}

-- destructor
function EnemyEntityDB:destroy()
	self._factory:destroy()
	self._factory = nil
	EntityDB.destroy(self)
end

function EnemyEntityDB:_getPropertyWeights()
	local props = {
		maxHealth  = {name = 'MaxHealth',      weight = 0.2},
		maxHealthB = {name = 'MaxHealthBonus', weight = 0.2},
		visibility = {name = 'Visibility',     weight = 1.3},
		visibility = {name = 'VisibilityBonus',weight = 1.3},
		damage     = {name = 'Damage',         weight = 0.6},
		damageB    = {name = 'DamageBonus',    weight = 0.6},
		defense    = {name = 'Defense',        weight = 0.6},
		defenseB   = {name = 'DefenseBonus',   weight = 0.6},
		attack     = {name = 'Attack',         weight = 0.6},
		attackB    = {name = 'AttackBonus',    weight = 0.6},
		speed      = {name = 'Speed',          weight = 1.4},
		speedB     = {name = 'SpeedBonus',     weight = 1.4},
		openDoors  = {name = 'CanOpenDoors',   weight = 10},
		canMove    = {name = 'CanMove',        weight = 10},
	}

	return props
end


-- the class
return EnemyEntityDB
