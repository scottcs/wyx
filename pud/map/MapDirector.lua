local Class = require 'lib.hump.class'
local MapBuilder = require 'pud.map.MapBuilder'

-- MapDirector
local MapDirector = Class{name='MapDirector'}

-- generate a standard roguelike map with rooms connected via hallways.
function MapDirector:generateStandard(builder)
	assert(builder:is_a(MapBuilder))
	
	builder:createMap()
	builder:addFeatures()
	builder:addPortals()
	builder:postProcess()

	return builder:getMap()
end

-- the class
return MapDirector
