local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- ItemEntityFactory
-- creates entities based on data files
local ItemEntityFactory = Class{name='ItemEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'item')
		self._renderLevel = 10
		self._requiredComponents = {
			getClass 'pud.component.MotionComponent',
			getClass 'pud.component.GraphicsComponent',
			--getClass 'pud.component.InfoPanelComponent',
		}
	end
}

-- destructor
function ItemEntityFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return ItemEntityFactory
