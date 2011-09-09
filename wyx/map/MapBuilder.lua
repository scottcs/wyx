local Class = require 'lib.hump.class'
local Map = getClass 'wyx.map.Map'
local MapNode = getClass 'wyx.map.MapNode'
local WallMapType = getClass 'wyx.map.WallMapType'
local DoorMapType = getClass 'wyx.map.DoorMapType'

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

-- add portals (entrances and exits) to the map
function MapBuilder:addPortals() end

-- post process step
-- a single step in the post process loop
function MapBuilder:postProcessStep(node, x, y) end

-- perform any post processing necessary
function MapBuilder:postProcess()
	-- go through the whole map
	local w, h = self._map:getSize()
	for y=1,h do
		for x=1,w do
			local node = self._map:getLocation(x, y)
			local mapType = node:getMapType()
			local variant = mapType:getVariant()

			local horizontal = true
			if isClass(WallMapType, mapType) then
				local below = self._map:getLocation(x, y+1)
				if below then
					local bMapType = below:getMapType()
					horizontal = not (isClass(WallMapType, bMapType)
						or isClass(DoorMapType, bMapType))
				end

				if not horizontal then
					node:setMapType(WallMapType('vertical'))
				end
			end

			self:postProcessStep(node, x, y)
		end
	end
end

-- verify map is correct
function MapBuilder:verifyMap()
	assert(self._map:getPortalNames() ~= nil,
		'Invalid map: no portals! name: %s  author: %s',
		self._map:getName(), self._map:getAuthor())
end

-- get the created map
function MapBuilder:getMap() return self._map end

-- the class
return MapBuilder
