local Class = require 'lib.hump.class'
local EntityFactory = getClass 'wyx.entity.EntityFactory'

-- ItemEntityFactory
-- creates entities based on data files
local ItemEntityFactory = Class{name='ItemEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'item')
		self._renderLevel = 10
		self._requiredComponents = {
			getClass 'wyx.component.MotionComponent',
			getClass 'wyx.component.CollisionComponent',
			getClass 'wyx.component.GraphicsComponent',
			getClass 'wyx.component.ControllerComponent',
			--getClass 'wyx.component.InfoPanelComponent',
		}
	end
}

-- destructor
function ItemEntityFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return ItemEntityFactory
