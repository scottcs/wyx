require 'pud.util'
local Class = require 'lib.hump.class'
local MapNode = require 'pud.map.MapNode'
local Rect = require 'pud.kit.Rect'
local vector = require 'lib.hump.vector'

local table_concat = table.concat
local math_floor = math.floor

-- Map
local Map = Class{name='Map', inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)
		self._layout = {}
		self._zones = {}

		self:clear()
	end
}

-- destructor
function Map:destroy()
	for y=1,self:getHeight() do
		for x=1,self:getWidth() do
			if self._layout[y][x] then self._layout[y][x]:destroy() end
			self._layout[y][x] = nil
		end
		self._layout[y] = nil
	end
	self._layout = nil

	for k in pairs(self._zones) do
		self._zones[k]:destroy()
		self._zones[k] = nil
	end
	self._zones = nil

	Rect.destroy(self)
end

-- clear the entire map, setting all nodes to empty
function Map:clear()
	for x=1,self:getWidth() do
		for y=1,self:getHeight() do
			local node = MapNode()
			self:setLocation(x, y, node)
		end
	end
end

-- set the given map location to the given map node
function Map:setLocation(x, y, node)
	verify('number', x, y)
	assert(x >= 1 and x <= self:getWidth(), 'setLocation x is out of range')
	assert(y >= 1 and y <= self:getHeight(), 'setLocation y is out of range')
	assert(node and node.is_a and node:is_a(MapNode),
		'attempt to call setLocation without a MapNode (was %s)',
		node and node.is_a and tostring(node) or type(node))

	-- destroy the old node
	if self._layout[y] and self._layout[y][x] then
		self._layout[y][x]:destroy()
	end

	-- assign the new node
	self._layout[y] = self._layout[y] or {}
	self._layout[y][x] = node
end

-- retrieve the map node of a given location
function Map:getLocation(x, y)
	if x >= 1 and x <= self:getWidth()
		and y >= 1 and y <= self:getHeight()
		and self._layout[y] and self._layout[y][x]
	then
		return self._layout[y][x]
	end
	return nil
end

-- set and get the starting vector for the map
function Map:setStartVector(v)
	assert(vector.isvector(v),
		'vector expected (was %s)', type(v))

	self._startVector = v
end

function Map:getStartVector()
	if self._startVector then return self._startVector end

	local w, h = self:getSize()
	return vector(math_floor(w/2+0.5), math_floor(h/2+0.5))
end

-- create a zone
function Map:setZone(name, rect)
	assert(rect and type(rect) == 'table' and rect.is_a and rect:is_a(Rect),
		'setZone expects a rect (was %s, %s)', tostring(rect), type(rect))

	if self._zones[name] then self._zones[name]:destroy() end
	self._zones[name] = rect:clone()
end

-- check if a point is within a zone
function Map:isInZone(point, zone)
	if not self._zones[name] then
		warning('Zone not found: %s', tostring(zone))
		return false
	end

	return self._zones[name]:containsPoint(point)
end

-- get the zone name that the point is in (if any)
function Map:getZonesFromPoint(point)
	local zones = {}
	local num = 0
	for name,rect in pairs(self._zones) do
		if rect:containsPoint(point) then
			zones[name] = true
			num = num + 1
		end
	end
	return num > 0 and zones or nil
end

-- the class
return Map