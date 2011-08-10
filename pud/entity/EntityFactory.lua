local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local HeroEntity = require 'pud.entity.HeroEntity'
local EnemyEntity = require 'pud.entity.EnemyEntity'
local ItemEntity = require 'pud.entity.ItemEntity'

local ViewComponent = require 'pud.component.ViewComponent'
local ControllerComponent = require 'pud.component.ControllerComponent'

local vector = require 'lib.hump.vector'
local json = require 'lib.dkjson'

local ENTITY = {
	enemy = {kind = 'enemy', level = 7},
	hero = {kind = 'hero', level = 5},
	item = {kind = 'item', level = 10},
}


-- EntityFactory
-- creates entities based on data files
local EntityFactory = Class{name='EntityFactory',
	function(self) end
}

-- destructor
function EntityFactory:destroy() end

local _getEntityInfo = function(kind, entityName)
	local filename = 'entity/'..kind..'/'..entityName..'.json'
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
local function _newComponent(componentString, props)
	local new = assert(
		loadstring('return require "pud.component.'
			..componentString..'"'),
		'could not load component: %s', componentString)

	local component = new(props)
	verifyClass('pud.component.Component', component)

	return component
end

-- return the component objects described by the info table
local _getComponents = function(info)
	local newComponents = {}

	for component, props in pairs(info.components) do
		if type(component) == 'number' then
			component = props
			props = nil
		end
		newComponents[#newComponents+1] = _newComponent(component, props)
	end

	return #newComponents > 0 and newComponents or nil
end

-- register with the relevant systems any ViewComponents the entity has
local _registerViews = function(entity, level)
	local views = entity:getComponentsByType(ViewComponent)
	if views then
		for _,view in pairs(views) do
			RenderSystem:register(view, level)
		end
	end
end

-- register with the relevant systems any ControllerComponents the entity has
local _registerControllers = function(entity)
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

-- create an enemy entity and return it
function EnemyFactory:createEnemy(entityName)
	local e = ENTITY.enemy
	local info = _getEntityInfo(e.kind, entityName)
	local entity = EnemyEntity(entityName, _getComponents(info))
	_registerViews(entity, e.level)
	return entity
end

-- create a hero entity and return it
function EnemyFactory:createHero(entityName)
	local e = ENTITY.hero
	local info = _getEntityInfo(e.kind, entityName)
	local entity = HeroEntity(entityName, _getComponents(info))
	_registerViews(entity, e.level)
	return entity
end

-- create a hero entity and return it
function EnemyFactory:createItem(entityName)
	local e = ENTITY.item
	local info = _getEntityInfo(e.kind, entityName)
	local entity = ItemEntity(entityName, _getComponents(info))
	_registerViews(entity, e.level)
	return entity
end

-- the class
return EntityFactory
