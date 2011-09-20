local Class = require 'lib.hump.class'
local Entity = getClass 'wyx.entity.Entity'
local message = require 'wyx.component.message'
local property = require 'wyx.component.property'
local depths = require 'wyx.system.renderDepths'

local format = string.format


-- EntityFactory
-- creates entities based on data files
local EntityFactory = Class{name='EntityFactory',
	function(self, etype)
		self._etype = etype or 'UNKNOWN'
		self._renderDepth = depths.gameobject - 1
	end
}

-- destructor
function EntityFactory:destroy()
	self._etype = nil
end

-- check for required components, and add any that are missing
function EntityFactory:_addMissingRequiredComponents(entity)
	if self._requiredComponents then
		for _,class in pairs(self._requiredComponents) do
			local found = entity:getComponentsByClass(class)
			if not found then
				self:_addDefaultComponent(entity, class)
			end
		end
	end
end

-- add a component with default values to the entity
function EntityFactory:_addDefaultComponent(entity, componentClass)
	entity:addComponent(componentClass())
end

-- create a new component from the given string representation of a component
-- class.
function EntityFactory:_newComponent(componentString, props)
	local new = getClass('wyx.component.'..componentString)
	local component = new(props)
	verifyClass('wyx.component.Component', component)
	assert(component.__class, 'invalid component')

	return component
end

-- return the component objects described by the info table
function EntityFactory:_getComponents(info)
	local unique = {}

	for component, props in pairs(info.components) do
		if type(component) == 'number' then
			component = props
			props = nil
		end
		if not unique[component] then
			unique[component] = self:_newComponent(component, props)
		else
			warning('Component "%s" was defined more than once.',
				tostring(component))
		end
	end

	local newComponents = {}
	for _,v in pairs(unique) do newComponents[#newComponents+1] = v end

	return #newComponents > 0 and newComponents or nil
end

-- register with the relevant systems any ViewComponents the entity has
function EntityFactory:_registerWithRenderSystem(entity)
	local ViewComponent = getClass 'wyx.component.ViewComponent'
	local comps = entity:getComponentsByClass(ViewComponent)

	if comps then
		for _,comp in pairs(comps) do
			comp:_setProperty(property('RenderDepth'), self._renderDepth)
			RenderSystem:register(comp)
		end
	end
end

-- register with the relevant systems any CollisionComponents the entity has
function EntityFactory:_registerWithCollisionSystem(entity)
	local CollisionComponent = getClass 'wyx.component.CollisionComponent'
	local comps = entity:getComponentsByClass(CollisionComponent)
	if comps then
		for _,comp in pairs(comps) do
			CollisionSystem:register(comp)
		end
	end
end

-- register with the relevant systems any TimeComponents the entity has
function EntityFactory:_registerWithTimeSystem(entity)
	local TimeComponent = getClass 'wyx.component.TimeComponent'
	local comps = entity:getComponentsByClass(TimeComponent)
	if comps then
		for _,comp in pairs(comps) do
			TimeSystem:register(comp)
		end
	end
end

function EntityFactory:createEntity(info)
	local entity = Entity(self._etype, info, self:_getComponents(info))
	EntityRegistry:register(entity)
	self:_addMissingRequiredComponents(entity)
	entity:send(message('ENTITY_CREATED'))
	return entity:getID()
end

function EntityFactory:registerEntity(id)
	local entity = EntityRegistry:get(id)
	self:_registerWithRenderSystem(entity)
	self:_registerWithCollisionSystem(entity)
	self:_registerWithTimeSystem(entity)
end

-- the class
return EntityFactory
