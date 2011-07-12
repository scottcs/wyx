local MapBuilder = require 'pud.level.MapBuilder'

-- Level
local Level = Class{name='Level'}

function Level:generateStandard(builder)
	assert(builder.is_a(MapBuilder))
	
	builder.init()
	builder.makeRooms()
	builder.connectRooms()
	builder.cleanup()

	return builder.getMap()
end

-- the class
return Level



