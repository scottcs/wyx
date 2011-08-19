local Class = require 'lib.hump.class'
local EntityDB = getClass 'pud.entity.EntityDB'
local property = require 'pud.component.property'

-- EnemyEntityDB
--
local EnemyEntityDB = Class{name='EnemyEntityDB',
	inherits=EntityDB,
	function(self)
		EntityDB.construct(self, 'enemy')
	end
}

-- destructor
function EnemyEntityDB:destroy()
	EntityDB.destroy(self)
end

-- calculate the elevel of this entity based on relevant properties.
function EnemyEntityDB:_calculateELevel(info)
	local maxHealth = property.default('MaxHealth')
	local attack = property.default('Defense')
	local defense = property.default('Attack')

	if info.components
		and info.components.HealthComponent
		and info.components.HealthComponent.MaxHealth
	then
		maxHealth = info.components.HealthComponent.MaxHealth
	end

	if info.components
		and info.components.CombatComponent
		and info.components.CombatComponent.Attack
	then
		attack = info.components.CombatComponent.Attack
	end

	if info.components
		and info.components.CombatComponent
		and info.components.CombatComponent.Defense
	then
		defense = info.components.CombatComponent.Defense
	end

	return (maxHealth*0.5) + (attack*0.25) + (defense*0.25)
end

-- the class
return EnemyEntityDB
