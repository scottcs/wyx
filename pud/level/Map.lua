require 'pud.util'
local Class = require 'lib.hump.class'
local MapNode = require 'pud.level.MapNode'
local MapType = require 'pud.level.MapType'
local Rect = require 'pud.kit.Rect'

-- Map
local Map = Class{name='Map', inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)
		self._layout = {}

		self:clear()
	end
}

-- destructor
function Map:destroy()
	for x=1,self:getWidth() do
		for y=1,self:getHeight() do
			if self._layout[y][x] then self._layout[y][x]:destroy() end
			self._layout[y][x] = nil
		end
		self._layout[y] = nil
	end
	self._layout = nil

	Rect.destroy(self)
end

-- clear the entire map, setting all nodes to MapType.empty
function Map:clear()
	for x=1,self:getWidth() do
		for y=1,self:getHeight() do
			local node = MapNode(MapType.empty)
			self:setLocation(x, y, node)
		end
	end
end

-- set the given map location to the given map node
function Map:setLocation(x, y, node)
	verify('number', x, y)
	assert(x >= 1 and x <= self:getWidth(), 'getLocation x is out of range')
	assert(y >= 1 and y <= self:getHeight(), 'getLocation y is out of range')
	assert(node and node.is_a and node:is_a(MapNode),
		'attempt to call setLocation without a MapNode (was %s)',
		node and node.is_a and tostring(node) or type(node))

	-- assign the node
	self._layout[y] = self._layout[y] or {}
	self._layout[y][x] = node
end

-- retrieve the map node of a given location
function Map:getLocation(x, y)
	verify('number', x, y)
	assert(x >= 1 and x <= self:getWidth(), 'getLocation x is out of range')
	assert(y >= 1 and y <= self:getHeight(), 'getLocation y is out of range')

	if not (self._layout[y] and self._layout[y][x]) then return nil end
	return self._layout[y][x]
end

-- functions for setting specific MapTypes and their associated attributes
-- in the given node or coordinates
function Map:setNodeMapType(node, maptype)
	node:setMapType(maptype)

	-- set attributes for specific types
	if maptype == MapType.floor
		or maptype == MapType.doorO
	then
		node:setLit(true)
		node:setAccessible(true)
		node:setTransparent(true)
	elseif maptype == MapType.wall then
		node:setLit(true)
		node:setAccessible(false)
		node:setTransparent(false)
	elseif maptype == MapType.doorC
		or maptype == MapType.stairU
		or maptype == MapType.stairD
	then
		node:setLit(true)
		node:setAccessible(true)
		node:setTransparent(false)
	elseif maptype == MapType.empty then
		node:setLit(false)
		node:setAccessible(false)
		node:setTransparent(false)
	else
		error('incorrect MapType specified for setNodeMapType: '..maptype)
	end

	return node
end

-- easy print
function Map:__tostring()
	local str = ''
	for y=1,self:getHeight() do
		for x=1,self:getWidth() do
			local node = self:getLocation(x, y)
			local t = node:getMapType()
			str = str .. t
		end
		str = str .. '\n'
	end
	return str
end

-- the class
return Map
