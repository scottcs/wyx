require 'pud.util'
local Class = require 'lib.hump.class'
local MapBuilder = require 'pud.level.MapBuilder'
local MapType = require 'pud.level.MapType'
local MapNode = require 'pud.level.MapNode'

-- FileMapBuilder
local FileMapBuilder = Class{name='FileMapBuilder',
	inherits=MapBuilder,
	function(self, ...)
		-- construct calls self:init(...)
		MapBuilder.construct(self, ...)
	end
}

-- destructor
function FileMapBuilder:destroy()
	self._filename = nil
	MapBuilder.destroy(self)
end

-- initialize the builder with a filename
function FileMapBuilder:init(filename)
	verify('string', filename)

	MapBuilder.init(self)

	-- check if the filename is actually a map name
	if not string.find(filename, '^map/%a+%.lua') then
		filename = 'map/'..filename..'.lua'
	end

	self._filename = filename
end

-- read the file and create the map
function FileMapBuilder:createMap()
	local map = self:_loadMap()
	self:_newMap(map)
	self:_buildMap(map)
end

-- notify when map includes unknown keys
function FileMapBuilder:_checkMapKeys(map)
	local known = {
		map = 'map',
		glyphs = 'glyphs',
		name = 'name',
		author = 'author',
	}

	for k,v in pairs(map) do
		if not known[k] then
			warning('Unknown map key "%s" in file: %s', k, self._filename)
		end
	end
end


function FileMapBuilder:_loadMap()
	local map = assert(loadfile(self._filename))()
	verify('string', map.map, map.name, map.author)
	verify('table', map.glyphs)
	self:_checkMapKeys(map)
	return map
end

-- build a reverse glyph table to easily lookup MapType
function FileMapBuilder:_reverseGlyphs(map)
	local revGlyphs = {}
	for k,v in pairs(map.glyphs) do revGlyphs[v] = k end
	return revGlyphs
end

-- determine width and height of map
function FileMapBuilder:_getMapSize(map)
	local width = #(string.match(map.map, '%S+'))
	local height = 0
	local i = 0
	while true do
		i = string.find(map.map, '\n', i+1)
		if nil == i then break end
		height = height + 1
	end
	return width, height
end

-- set the map size and empty all nodes
function FileMapBuilder:_newMap(map)
	local width, height = self:_getMapSize(map)
	self._map:setSize(width, height)
	self._map:clear()
end

-- build the map
function FileMapBuilder:_buildMap(map)
	local x, y = 0, 0
	local width, height = self._map:getSize()
	local revGlyphs = self:_reverseGlyphs(map)

	for row in string.gmatch(map.map, '%S+') do
		y = y + 1

		assert(#row == width, 'Map is unaligned. Expected width of %d for row '
			..'%d of the map, but found width %d.', width, y, #row)

		for col in string.gmatch(row, '%C') do
			x = x + 1
			local mapType = MapType(revGlyphs[col])
			if not mapType:isType('empty') then
				local node = self._map:setNodeMapType(MapNode(), mapType)
				self._map:setLocation(x, y, node)
			end
		end

		x = 0
	end
end

-- the class
return FileMapBuilder
