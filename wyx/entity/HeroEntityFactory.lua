local Class = require 'lib.hump.class'
local EntityFactory = getClass 'wyx.entity.EntityFactory'
local property = require 'wyx.component.property'

-- HeroEntityFactory
-- creates entities based on data files
local HeroEntityFactory = Class{name='HeroEntityFactory',
	inherits=EntityFactory,
	function(self)
		EntityFactory.construct(self, 'hero')
		self._renderDepth = 5
		-- required components (can be parent classes)
		self._requiredComponents = {
			getClass 'wyx.component.HealthComponent',
			getClass 'wyx.component.TimeComponent',
			getClass 'wyx.component.GraphicsComponent',
			getClass 'wyx.component.CombatComponent',
			getClass 'wyx.component.CollisionComponent',
			getClass 'wyx.component.MotionComponent',
			getClass 'wyx.component.InputComponent',
			getClass 'wyx.component.ContainerComponent',
			getClass 'wyx.component.WeaponAttachmentComponent',
			getClass 'wyx.component.ArmorAttachmentComponent',
			getClass 'wyx.component.RingAttachmentComponent',
		}
	end
}

-- destructor
function HeroEntityFactory:destroy()
	EntityFactory.destroy(self)
end

-- set input component explicitly
function HeroEntityFactory:setInputComponent(id, component)
	local entity = EntityRegistry:get(id)
	local InputComponent = getClass 'wyx.component.InputComponent'
	verifyClass(InputComponent, component)
	entity:removeComponent(InputComponent)
	entity:addComponent(component)
end

-- set time component explicitly
function HeroEntityFactory:setTimeComponent(id, component)
	local entity = EntityRegistry:get(id)
	local TimeComponent = getClass 'wyx.component.TimeComponent'
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
