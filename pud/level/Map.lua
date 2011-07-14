local MapNode = require 'pud.level.MapNode'
local MapType = require 'pud.level.MapType'
local Rect = require 'pud.kit.Rect'

-- Map
local Map = Class{name='Map', inherits=Rect,
	function(self, ...)
		Rect.construct(self, ...)
		self._layout = {}
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
	validate('number', x, y)

	-- remove the old node if it exists
	if self._layout[y] and self._layout[y][x] then
		self._layout[y][x]:destroy()
		self._layout[y][x] = nil
	end

	-- assign the node
	self._layout[y] = self.layout[y] or {}
	self._layout[y][x] = node
end

-- retrieve the map node of a given location
function Map:getLocation(x, y)
	if not (self._layout[y] and self._layout[y][x]) then return nil end
	return self._layout[y][x]
end

-- the class
return Map
