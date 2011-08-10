local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- HeroFactory
-- creates entities based on data files
local HeroFactory = Class{name='HeroFactory',
	inherits=EntityFactory,
	function(self, 'hero')
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
			getClass 'pud.component.InputComponent',
		}
		]]--
	end
}

-- destructor
function HeroFactory:destroy()
	EntityFactory.destroy(self)
end

-- the class
return HeroFactory
