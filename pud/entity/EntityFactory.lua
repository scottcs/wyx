local Class = require 'lib.hump.class'
local Entity = getClass 'pud.entity.Entity'

local ViewComponent = getClass 'pud.component.ViewComponent'
local ControllerComponent = getClass 'pud.component.ControllerComponent'

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

-- create a new component from the given string representation of a component
-- class.
function EntityFactory:_newComponent(componentString, props)
	local new = assert(
		loadstring('return require "pud.component.'
			..componentString..'"'),
		'could not load component: %s', componentString)

	local component = new(props)
	verifyClass('pud.component.Component', component)

	return component
end

-- check for required components, and add any that are missing
function EntityFactory:_addMissingRequiredComponents(unique)
	if self._requiredComponents then
		for _,comp in pairs(self._requiredComponents) do
			local compName = tostring(comp)
			if not unique[compName] then unique[compName] = comp() end
		end
	end
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

	self:_addMissingRequiredComponents(unique)

	local newComponents = {}
	for _,v in pairs(unique) do newComponents[#newComponents+1] = v end

	return #newComponents > 0 and newComponents or nil
end

-- register with the relevant systems any ViewComponents the entity has
function EntityFactory:_registerViews(entity)
	local views = entity:getComponentsByType(ViewComponent)
	if views then
		for _,view in pairs(views) do
			RenderSystem:register(view, self._renderLevel)
		end
	end
end

-- register with the relevant systems any ControllerComponents the entity has
function EntityFactory:_registerControllers(entity)
	local controllers = entity:getComponentsByType(ControllerComponent)
	if controllers then
		for _,controller in pairs(controllers) do
			--[[
			if isClass(InputComponent, controller) then
				InputSystem:register(controller)
			elseif isClass(AIComponent, controller) then
				AISystem:register(controller)
			end
			]]--
		end
	end
end

function EntityFactory:createEntity(entityName)
	local info = self:_getEntityInfo(entityName)
	local entity = Entity(entityName, self:_getComponents(info))
	self:_registerViews(entity)
	self:_registerControllers(entity)
	return entity
end

-- the class
return EntityFactory
