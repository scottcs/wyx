require 'pud.util'
local Class = require 'lib.hump.class'
local MapType = require 'pud.level.MapType'

-- MapNode
-- represents a single map position
local MapNode = Class{name='MapNode',
	function(self, mapType)
		self._isAccessible = false
		self._isLit = false
		self._isTransparent = false
		self._wasSeen = false
		self:setMapType(mapType)
	end
}

-- destructor
function MapNode:destroy()
	self._isAccessible = nil
	self._isLit = nil
	self._isTransparent = nil
	self._wasSeen = nil
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
	assert(nil ~= MapType[mapType], 'invalid map type %s', mapType)
	self._mapType = mapType
end
function MapNode:getMapType() return self._mapType end

-- the class
return MapNode
