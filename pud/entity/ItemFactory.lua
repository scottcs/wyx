local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- ItemFactory
-- creates entities based on data files
local ItemFactory = Class{name='ItemFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'item')
		self._renderLevel = 5
		--[[
		self._requiredComponents = {
			getClass 'pud.component.PositionComponent',
			getClass 'pud.component.GraphicsComponent',
			getClass 'pud.component.InfoPanelComponent',
		}
		]]--
	end
}

-- destructor
function ItemFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return ItemFactory
