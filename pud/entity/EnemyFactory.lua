local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- EnemyFactory
-- creates entities based on data files
local EnemyFactory = Class{name='EnemyFactory',
	inherits=EntityFactory,
	function(self, 'enemy')
		EntityFactory.construct(self)
		self._renderLevel = 5
		--[[
		self._requiredComponents = {
			getClass 'pud.component.HealthComponent',
			getClass 'pud.component.PositionComponent',
			getClass 'pud.component.TimeComponent',
			getClass 'pud.component.GraphicsComponent',
			getClass 'pud.component.InfoPanelComponent',
			getClass 'pud.component.CombatComponent',
			getClass 'pud.component.CollisionComponent',
			getClass 'pud.component.MotionComponent',
			getClass 'pud.component.AIComponent',
		}
		]]--
	end
}

-- destructor
function EnemyFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return EnemyFactory
