local Class = require 'lib.hump.class'
local EntityFactory = getClass 'wyx.entity.EntityFactory'
local depths = require 'wyx.system.renderDepths'

-- EnemyEntityFactory
-- creates entities based on data files
local EnemyEntityFactory = Class{name='EnemyEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'enemy')
		self._renderDepth = depths.gameenemy
		self._requiredComponents = {
			getClass 'wyx.component.HealthComponent',
			getClass 'wyx.component.TimeComponent',
			getClass 'wyx.component.GraphicsComponent',
			getClass 'wyx.component.CombatComponent',
			getClass 'wyx.component.CollisionComponent',
			getClass 'wyx.component.MotionComponent',
			getClass 'wyx.component.AIInputComponent',
		}
	end
}

-- destructor
function EnemyEntityFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return EnemyEntityFactory
