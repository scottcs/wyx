local Class = require 'lib.hump.class'
local EntityFactory = getClass 'wyx.entity.EntityFactory'
local depths = require 'wyx.system.renderDepths'

-- ItemEntityFactory
-- creates entities based on data files
local ItemEntityFactory = Class{name='ItemEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'item')
		self._renderDepth = depths.gameitem
		self._requiredComponents = {
			getClass 'wyx.component.MotionComponent',
			getClass 'wyx.component.CollisionComponent',
			getClass 'wyx.component.GraphicsComponent',
			getClass 'wyx.component.ControllerComponent',
		}
	end
}

-- destructor
function ItemEntityFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return ItemEntityFactory
