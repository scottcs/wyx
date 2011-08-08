local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local HeroEntity = require 'pud.entity.HeroEntity'
local EnemyEntity = require 'pud.entity.EnemyEntity'
local ItemEntity = require 'pud.entity.ItemEntity'

local vector = require 'lib.hump.vector'
local json = require 'lib.dkjson'

-- ALL the components
local Component = require 'pud.entity.component.Component'

local _ENTITY = {
	enemy = 'enemy',
	hero = 'hero',
	item = 'item',
}

-- EntityFactory
-- creates entities based on data files
local EntityFactory = Class{name='EntityFactory',
	function(self) end
}

-- destructor
function EntityFactory:destroy() end

local _getEntityInfo = function(kind, entityName)
	assert(kind == _ENTITY[kind], 'invalid entity kind: %s', tostring(kind))

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
		loadstring('return require "pud.entity.component.'
			..componentString..'"'),
		'could not load component: %s', componentString)

	local component = new(props)
	verifyClass(Component, component)

	return component
end

-- create an enemy entity and return it
function createEnemy(entityName)
	local info = _getEntityInfo('enemy', entityName)
	local initComponents = {}

	for component, props in pairs(info.components) do
		initComponents[#initComponents+1] = _newComponent(component, props)
	end

	return EnemyEntity(entityName, initComponents)
end

-- create a hero entity and return it
function createHero(entityName)
	local info = _getEntityInfo('hero', entityName)
	local initComponents = {}

	for component, props in pairs(info.components) do
		initComponents[#initComponents+1] = _newComponent(component, props)
	end

	return HeroEntity(entityName, initComponents)
end

-- create a hero entity and return it
function createItem(entityName)
	local info = _getEntityInfo('item', entityName)
	local initComponents = {}

	for component, props in pairs(info.components) do
		initComponents[#initComponents+1] = _newComponent(component, props)
	end

	return ItemEntity(entityName, initComponents)
end

-- the class
return EntityFactory
