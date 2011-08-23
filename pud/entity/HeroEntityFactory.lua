local Class = require 'lib.hump.class'
local EntityFactory = getClass 'pud.entity.EntityFactory'

-- HeroEntityFactory
-- creates entities based on data files
local HeroEntityFactory = Class{name='HeroEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'hero')
		self._renderLevel = 5
		-- required components (can be parent classes)
		self._requiredComponents = {
			getClass 'pud.component.HealthComponent',
			getClass 'pud.component.TimeComponent',
			getClass 'pud.component.GraphicsComponent',
			--getClass 'pud.component.InfoPanelComponent',
			getClass 'pud.component.CombatComponent',
			getClass 'pud.component.CollisionComponent',
			getClass 'pud.component.MotionComponent',
			getClass 'pud.component.InputComponent',
			getClass 'pud.component.ContainerComponent',
		}
	end
}

-- destructor
function HeroEntityFactory:destroy()
	EntityFactory.destroy(self)
end

--[[
-- add a required component with default values
function HeroEntityFactory:_addDefaultComponent(entity, componentClass)
	-- check if the componentClass is InputComponent (or a subclass)
	if isClass('pud.component.InputComponent', componentClass) then
		-- add an AI component
		entity:addComponent(AIInputComponent())
	else
		EntityFactory._addDefaultComponent(self, entity, componentClass)
	end
end
]]--

-- set input component explicitly
function HeroEntityFactory:setInputComponent(id, component)
	local entity = EntityRegistry:get(id)
	local InputComponent = getClass 'pud.component.InputComponent'
	verifyClass(InputComponent, component)
	entity:removeComponent(InputComponent)
	entity:addComponent(component)
end

-- set time component explicitly
function HeroEntityFactory:setTimeComponent(id, component)
	local entity = EntityRegistry:get(id)
	local TimeComponent = getClass 'pud.component.TimeComponent'
	verifyClass(TimeComponent, component)
	local currentComps = entity:getComponentsByClass(TimeComponent)
	for _,comp in pairs(currentComps) do
		comp:exhaust()
		entity:removeComponent(comp)
	end
	entity:addComponent(component)
	TimeSystem:register(component)
end


-- the class
return HeroEntityFactory
