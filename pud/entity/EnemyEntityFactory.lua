local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- EnemyEntityFactory
-- creates entities based on data files
local EnemyEntityFactory = Class{name='EnemyEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'enemy')
		self._renderLevel = 7
		self._requiredComponents = {
			getClass 'pud.component.HealthComponent',
			getClass 'pud.component.TimeComponent',
			getClass 'pud.component.GraphicsComponent',
			--getClass 'pud.component.InfoPanelComponent',
			getClass 'pud.component.CombatComponent',
			getClass 'pud.component.CollisionComponent',
			getClass 'pud.component.MotionComponent',
			getClass 'pud.component.AIInputComponent',
		}
	end
}

-- destructor
function EnemyEntityFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return EnemyEntityFactory
