local Class = require 'lib.hump.class'
local MapBuilder = getClass 'wyx.map.MapBuilder'

-- MapDirector
local MapDirector = Class{name='MapDirector'}

-- generate a standard roguelike map with rooms connected via hallways.
function MapDirector:generateStandard(builder)
	assert(isClass(MapBuilder, builder))
	
	builder:createMap()
	builder:addFeatures()
	builder:addPortals()
	builder:postProcess()
	builder:verifyMap()

	return builder:getMap()
end

-- the class
return MapDirector
