local Class = require 'lib.hump.class'
local Map = require 'pud.map.Map'
local MapNode = require 'pud.map.MapNode'

-- MapBuilder
local MapBuilder = Class{name='MapBuilder',
	function(self, ...)
		self:init(...)
	end
}

-- destructor
function MapBuilder:destroy() self._map = nil end

-- initialize the builder
function MapBuilder:init(w, h)
	self._map = Map(0, 0, w, h)
end

-- generate map
function MapBuilder:createMap() end

-- add features to the map
function MapBuilder:addFeatures() end

-- perform any cleanup needed on the map
function MapBuilder:cleanup() end

-- get the created map
function MapBuilder:getMap() return self._map end

-- the class
return MapBuilder
