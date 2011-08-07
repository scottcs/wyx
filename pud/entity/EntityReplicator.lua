local Class = require 'lib.hump.class'
local Entity = require 'pud.entity.Entity'
local HeroEntity = require 'pud.entity.HeroEntity'
local EnemyEntity = require 'pud.entity.EnemyEntity'
local ItemEntity = require 'pud.entity.ItemEntity'
local vector = require 'lib.hump.vector'
local json = require 'lib.dkjson'

-- EntityReplicator
-- creates entities based on data files
-- (I've been watching Star Trek: TNG lately... Replicator seemed to fit).
local EntityReplicator = Class{name='EntityReplicator',
	function(self)
	end
}

-- destructor
function EntityReplicator:destroy()
end

local _getEntityInfo = function(entityType, entityName)
	local filename = 'entity/'..entityType..'/'..entityName..'.json'
	local contents, size = love.filesystem.read(filename)

	-- these files should be at mininmum 3 bytes
	if size < 3 then
		error('File does not appear to be an entity definition: '..filename)
	end

	local obj, pos, err = json.decode(contents)
	if err then error(err) end

	return obj
end

-- create an entity and return it
function replicate(entityType, entityName)
	local info = _getEntityInfo(entityType, entityName)
	local entity = switch(entityType) {
		enemy = EnemyEntity(),
		item = ItemEntity(),
		hero = HeroEntity(),
		default = Entity(),
	}
	-- XXX hmm... name? no... type? hmm...
	-- XXX name is GoblinGrunt, but what if more than one? Unique/Boss monsters?
	-- XXX What about hero names? Item names? THIS IS ALL WRONG!
	entity:setName(info.name)
	
	-- set tile data
	-- XXX should this be in a behavior? RenderBehavior or something?
	entity:setTile(info.tile.set, vector(info.tile.x, info.tile.y))

	-- set attributes
	for i=1,#info.attributes do
		local attr = info.attributes[i]
		-- XXX How to handle this? switch statement with classes like above?
		-- XXX must be something better...
		entity:addAttribute(attr)
	end

	-- set behaviors
	-- XXX see attr questions above
	for behavior, data in pairs(info.behaviors) do
		entity:addBehavior(behavior, data)
	end
end


-- the class
return EntityReplicator
