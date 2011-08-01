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

function Map:getStartVector()
	if not self._startVector then
		local w, h = self:getSize()
		return vector(math_floor(w/2+0.5), math_floor(h/2+0.5))
	end
end

-- functions for setting specific MapTypes and their associated attributes
-- in the given node or coordinates
function Map:setNodeMapType(node, mapType, variant)
	node:setMapType(mapType, variant)
	mapType = node:getMapType()

	-- set attributes for specific types
	if mapType:isType('floor', 'trap', 'doorOpen') then
		node:setLit(true)
		node:setAccessible(true)
		node:setTransparent(true)
	elseif mapType:isType('wall', 'torch', 'doorClosed') then
		node:setLit(true)
		node:setAccessible(false)
		node:setTransparent(false)
	elseif mapType:isType('stairUp', 'stairDown') then
		node:setLit(true)
		node:setAccessible(true)
		node:setTransparent(false)
	elseif mapType:isType('empty') then
		node:setLit(false)
		node:setAccessible(false)
		node:setTransparent(false)
	else
		warning('incorrect MapType specified for setNodeMapType: %s',
			tostring(mapType))
	end

	return node
end

-- easy print
function Map:__tostring()
	local s = {}
	local glyph = {
		empty = ' ',
		wall = '#',
		torch = '~',
		floor = '.',
		doorClosed = '+',
		doorOpen = '-',
		stairUp = '<',
		stairDown = '>',
		trap = '^',
	}

	for y=1,self:getHeight() do
		local row = {}
		for x=1,self:getWidth() do
			local node = self:getLocation(x, y)
			local mapType = node:getMapType()
			local t,v = mapType:get()
			if glyph[t] then
				row[#row+1] = glyph[t]
			elseif t == 'point' and v then
				row[#row+1] = tostring(v):sub(1,1)
			else
				row[#row+1] = '`'
			end
		end
		s[#s+1] = table_concat(row)
	end
	return table_concat(s, '\n')
end

-- the class
return Map
