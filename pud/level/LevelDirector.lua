local Class = require 'lib.hump.class'
local MapBuilder = require 'pud.level.MapBuilder'

-- LevelDirector
local LevelDirector = Class{name='LevelDirector'}

-- generate a standard roguelike map with rooms connected via hallways.
function LevelDirector:generateStandard(builder)
	assert(builder:is_a(MapBuilder))
	
	builder:createMap()
	builder:addFeatures()
	builder:cleanup()

	return builder:getMap()
end

-- the class
return LevelDirector
