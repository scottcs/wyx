local Map = require 'pud.level.Map'
local MapBuilder = require 'pud.level.MapBuilder'

-- MapBuilder
local SimpleGridMapBuilder = Class{name='SimpleGridMapBuilder',
	inherits = MapBuilder,
	function(self)
		MapBuilder.construct(self)
	end
}

-- destructor
function SimpleGridMapBuilder:destroy()
	self._map = nil
end

-- initialize the map
function SimpleGridMapBuilder:init()
	self._map = Map()
end

-- generate all the rooms
function SimpleGridMapBuilder:makeRooms()
end

-- connect the rooms together
function SimpleGridMapBuilder:connectRooms()
end

-- perform any cleanup needed on the map
function SimpleGridMapBuilder:cleanup()
end

-- get the created map
function SimpleGridMapBuilder:getMap()
	return self._map
end

-- the class
return SimpleGridMapBuilder
