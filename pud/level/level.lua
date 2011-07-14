local MapBuilder = require 'pud.level.MapBuilder'

-- Level
local Level = Class{name='Level'}

-- generate a standard roguelike map with rooms connected via hallways.
function Level:generateStandard(builder)
	assert(builder:is_a(MapBuilder))
	
	builder:init()
	builder:makeRooms()
	builder:connectRooms()
	builder:cleanup()

	return builder:getMap()
end

-- generate a cavernous map with large open spaces and rough walls.
function Level:generateCavernous(builder)
	assert(builder:is_a(MapBuilder))
	
	builder:init()
	builder:makeCaverns()
	builder:cleanup()

	return builder:getMap()
end

-- the class
return Level



