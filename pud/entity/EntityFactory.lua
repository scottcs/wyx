local Class = require 'lib.hump.class'
local Entity = getClass 'pud.entity.Entity'
local message = require 'pud.component.message'

local vector = require 'lib.hump.vector'
local json = require 'lib.dkjson'


-- EntityFactory
-- creates entities based on data files
local EntityFactory = Class{name='EntityFactory',
	function(self, kind)
		self._kind = kind or 'UNKNOWN'
		self._renderLevel = 30
	end
}

-- destructor
function EntityFactory:destroy()
	self._kind = nil
end

function EntityFactory:_getEntityInfo(entityName)
	local filename = 'entity/'..self._kind..'/'..entityName..'.json'
	local contents, size = love.filesystem.read(filename)

	-- these files should be at mininmum 27 bytes
	if size < 27 then
		error('File does not appear to be an entity definition: '..filename)
	end

	local obj, pos, err = json.decode(contents)
	if err then error(err) end

	return obj
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
	local new = getClass('pud.component.'..componentString)
	local component = new(props)
	verifyClass('pud.component.Component', component)
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
	local ViewComponent = getClass 'pud.component.ViewComponent'
	local comps = entity:getComponentsByClass(ViewComponent)

	if comps then
		for _,comp in pairs(comps) do
			RenderSystem:register(comp, self._renderLevel)
		end
	end
end

-- register with the relevant systems any CollisionComponents the entity has
function EntityFactory:_registerWithCollisionSystem(entity)
	local CollisionComponent = getClass 'pud.component.CollisionComponent'
	local comps = entity:getComponentsByClass(CollisionComponent)
	if comps then
		for _,comp in pairs(comps) do
			CollisionSystem:register(comp)
		end
	end
end

-- register with the relevant systems any TimeComponents the entity has
function EntityFactory:_registerWithTimeSystem(entity)
	local TimeComponent = getClass 'pud.component.TimeComponent'
	local comps = entity:getComponentsByClass(TimeComponent)
	if comps then
		for _,comp in pairs(comps) do
			TimeSystem:register(comp)
		end
	end
end

function EntityFactory:createEntity(entityName)
	local info = self:_getEntityInfo(entityName)
	local entity = Entity(self._kind, info.name, self:_getComponents(info))
	self:_addMissingRequiredComponents(entity)
	entity:send(message('ENTITY_CREATED'))

	self:_registerWithRenderSystem(entity)
	self:_registerWithCollisionSystem(entity)
	self:_registerWithTimeSystem(entity)

	return entity
end

-- the class
return EntityFactory
