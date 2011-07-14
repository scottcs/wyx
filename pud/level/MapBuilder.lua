local Map = require 'pud.level.Map'

-- MapBuilder
local MapBuilder = Class{name='MapBuilder'}

-- destructor
function MapBuilder:destroy() self._map = nil end

-- initialize the map
function MapBuilder:init() self._map = Map() end

-- generate rooms
function MapBuilder:makeRooms() end

-- generate wide open cavernous areas
function MapBuilder:makeCaverns() end

-- connect rooms together
function MapBuilder:connectRooms() end

-- perform any cleanup needed on the map
function MapBuilder:cleanup() end

-- get the created map
function MapBuilder:getMap() return self._map end

-- the class
return MapBuilder
