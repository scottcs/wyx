local Map = require 'pud.level.Map'
local MapNode = require 'pud.level.MapNode'

-- MapBuilder
local MapBuilder = Class{name='MapBuilder'}

-- destructor
function MapBuilder:destroy() self._map = nil end

-- initialize the builder
function MapBuilder:init(w, h)
	self._map = Map(0, 0, w, h)
	self._map:clear()
end

-- generate rooms
function MapBuilder:createRooms() end

-- generate wide open cavernous areas
function MapBuilder:createCaverns() end

-- connect rooms together
function MapBuilder:connectRooms() end

-- perform any cleanup needed on the map
function MapBuilder:cleanup() end

-- get the created map
function MapBuilder:getMap() return self._map end

-- the class
return MapBuilder
