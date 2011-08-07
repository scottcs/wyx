local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local HeroEntity = require 'pud.entity.HeroEntity'
local EnemyEntity = require 'pud.entity.EnemyEntity'
local ItemEntity = require 'pud.entity.ItemEntity'
local vector = require 'lib.hump.vector'
local json = require 'lib.dkjson'
local kind = require 'pud.entity.kind'

-- ALL the components
local Component = require 'pud.entity.component.Component'

-- EntityReplicator
-- creates entities based on data files
-- (I've been watching Star Trek: TNG lately... Replicator seemed to fit).
local EntityReplicator = Class{name='EntityReplicator',
	function(self) end
}

-- destructor
function EntityReplicator:destroy() end

local _getEntityInfo = function(entityKind, entityName)
	entityKind = kind(entityKind)
	local fileentityName = 'entity/'..entityKind..'/'..entityName..'.json'
	local contents, size = love.filesystem.read(fileentityName)

	-- these files should be at mininmum 3 bytes
	if size < 3 then
		error('File does not appear to be an entity definition: '..fileentityName)
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

-- create an entity and return it
function replicate(entityKind, entityName)
	local info = _getEntityInfo(entityKind, entityName)
	local initComponents = {}

	for component, props in pairs(info.components) do
		initComponents[#initComponents+1] = _newComponent(component, props)
	end

	local entity = switch(entityKind) {
		enemy = EnemyEntity(entityName, initComponents),
		hero = HeroEntity(entityName, initComponents),
		item = ItemEntity(entityName, initComponents),
		default = error('entityKind not yet implemented: '..entityKind),
	}
end


-- the class
return EntityReplicator
