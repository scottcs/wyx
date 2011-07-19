local Class = require 'lib.hump.class'
local MapBuilder = require 'pud.level.MapBuilder'

-- LevelDirector
local LevelDirector = Class{name='LevelDirector'}

-- generate a standard roguelike map with rooms connected via hallways.
function LevelDirector:generateStandard(builder, ...)
	assert(builder:is_a(MapBuilder))
	
	builder:init(...)
	builder:createRooms()
	builder:connectRooms()
	builder:cleanup()

	return builder:getMap()
end

-- generate a cavernous map with large open spaces and rough walls.
function LevelDirector:generateCavernous(builder, ...)
	assert(builder:is_a(MapBuilder))
	
	builder:init(...)
	builder:createCaverns()
	builder:cleanup()

	return builder:getMap()
end

-- the class
return LevelDirector



