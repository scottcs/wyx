local Class = require 'lib.hump.class'
local MapType = getClass('pud.map.MapType')

-- MapNode
-- represents a single map position
local MapNode = Class{name='MapNode',
	function(self, mapType)
		self._isAccessible = false
		self._isLit = false
		self._isTransparent = false
		self._wasSeen = false

		mapType = mapType or MapType()
		self:setMapType(mapType)
	end
}

-- destructor
function MapNode:destroy()
	self._isAccessible = nil
	self._isLit = nil
	self._isTransparent = nil
	self._wasSeen = nil

	self._mapType:destroy()
	self._mapType = nil
end

-- getters and setters
function MapNode:setAccessible(b)
	verify('boolean', b)
	self._isAccessible = b
end
function MapNode:isAccessible() return self._isAccessible end

function MapNode:setLit(b)
	verify('boolean', b)
	self._isLit = b
end
function MapNode:isLit() return self._isLit end

function MapNode:setTransparent(b)
	verify('boolean', b)
	self._isTransparent = b
end
function MapNode:isTransparent() return self._isTransparent end

function MapNode:setSeen(b)
	verify('boolean', b)
	self._wasSeen = b
end
function MapNode:wasSeen() return self._wasSeen end

function MapNode:setMapType(mapType)
	if self._mapType then self._mapType:destroy() end

	verifyClass(MapType, mapType)

	self._mapType = mapType
	local attrs = mapType:getDefaultAttributes()
	self._isTransparent = attrs.transparent
	self._isAccessible = attrs.accessible
	self._isLit = attrs.lit
end
function MapNode:getMapType() return self._mapType end

-- the class
return MapNode
