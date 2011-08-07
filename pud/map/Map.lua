require 'pud.util'
local Class = require 'lib.hump.class'
local MapNode = require 'pud.map.MapNode'
local Rect = require 'pud.kit.Rect'

local table_concat = table.concat
local math_floor = math.floor

-- Map
local Map = Class{name='Map', inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)
		self._layout = {}
		self._zones = {}
		self._portals = {}

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

	for k in pairs(self._portals) do self._portals[k] = nil end
	self._portals = nil

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

-- return the name of this map
function Map:getName() return self._name end
function Map:setName(name) self._name = name end

-- return the author of this map
function Map:getAuthor() return self._author end
function Map:setAuthor(author) self._author = author end

-- set the given map location to the given map node
function Map:setLocation(x, y, node)
	verify('number', x, y)
	assert(x >= 1 and x <= self:getWidth(), 'setLocation x is out of range')
	assert(y >= 1 and y <= self:getHeight(), 'setLocation y is out of range')
	verifyClass(MapNode, node)

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

-- add the given point, and the map and point it links to,
-- to the list of portals
function Map:setPortal(name, point, map, mappoint)
	verify('string', name)
	verify('vector', point)
	assert(self:containsPoint(point),
		'portal point is not within map borders: %s', tostring(point))

	local link
	if nil ~= map and nil ~= mappoint then
		verify('vector', mappoint)
		verifyClass(Map, map)
		assert(map:containsPoint(mappoint),
			'portal mappoint is not within its map borders: %s', tostring(mappoint))

		link = {
			map = map,
			point = mappoint,
		}
	end

	self._portals[name] = {
		point = point,
		link = link,
	}
end

-- get a named portal point and link
function Map:getPortal(name)
	local portal = self._portals[name]
	if portal then
		return portal.point, portal.link
	else
		return nil
	end
end

-- return the names of all portals
function Map:getPortalNames()
	local names = {}
	for k in pairs(self._portals) do names[#names+1] = k end
	table.sort(names)
	return #names > 0 and names or nil
end

-- create a zone
function Map:setZone(name, rect)
	verifyClass(Rect, rect)
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
