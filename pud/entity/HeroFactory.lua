local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- HeroFactory
-- creates entities based on data files
local HeroFactory = Class{name='HeroFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'hero')
		self._renderLevel = 5
		--[[
		-- required components (can be parent classes)
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

--[[
-- add a required component with default values
function HeroFactory:_addDefaultComponent(entity, componentClass)
	-- check if the componentClass is InputComponent (or a subclass)
	if isClass('pud.component.InputComponent', componentClass) then
		-- add an AI component
		entity:addComponent(AIInputComponent())
	else
		EntityFactory._addDefaultComponent(self, entity, componentClass)
	end
end
]]--


-- the class
return HeroFactory
