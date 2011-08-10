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
		}
		]]--
	end
}

-- destructor
function HeroFactory:destroy()
	EntityFactory.destroy(self)
end

-- check for required components, and add any that are missing
function HeroFactory:_addMissingRequiredComponents(unique)
	EntityFactory._addMissingRequiredComponents(self, unique)

	--[[
	-- make sure Hero has either an InputComponent or an AIComponent
	if not unique['InputComponent'] and not unique['AIComponent'] then
		local AIComponent = getClass 'pud.component.AIComponent'
		unique['AIComponent'] = AIComponent()
	end
	]]--
end

-- the class
return HeroFactory
