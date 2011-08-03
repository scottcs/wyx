require 'pud.util'
local Class = require 'lib.hump.class'
local MapBuilder = require 'pud.map.MapBuilder'
local MapType = require 'pud.map.MapType'
local MapNode = require 'pud.map.MapNode'
local vector = require 'lib.hump.vector'

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
		handleDetail = 'handleDetail',
	}

	for k,v in pairs(map) do
		if not known[k] then
			warning('Unknown map key "%s" in file: %s', k, self._filename)
		end
	end
end


function FileMapBuilder:_loadMap()
	local map = assert(love.filesystem.load(self._filename))()
	verify('string', map.map, map.name, map.author)
	verify('boolean', map.handleDetail)
	verify('table', map.glyphs)
	self:_checkMapKeys(map)
	return map
end

local _findVariant = function(mtype, n)
	local variants
	if mtype == 'floor' then
		variants = {nil, 'Worn', 'X', 'Rug'}
	elseif mtype == 'wall' then
		variants = {'H', 'HWorn', 'V'}
	end

	return variants and variants[n] or nil
end

-- get MapType from glyph
function FileMapBuilder:_glyphToMapType(allGlyphs, glyph)
	local mtype
	for k,v in pairs(allGlyphs) do
		if type(v) == 'table' then
			for i,g in ipairs(v) do
				if glyph == g then
					mtype = MapType(k, _findVariant(k,i))
				end
			end
		elseif glyph == v then
			mtype = MapType(k)
		end
	end
	return mtype
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

	for row in string.gmatch(map.map, '%S+') do
		y = y + 1

		assert(#row == width, 'Map is unaligned. Expected width of %d for row '
			..'%d of the map, but found width %d.', width, y, #row)

		for col in string.gmatch(row, '%C') do
			x = x + 1
			local mapType = self:_glyphToMapType(map.glyphs, col)
			if not mapType then
				warning('unknown mapType for glyph: %s',col)
			elseif not mapType:isType('empty') then
				local node = self._map:setNodeMapType(MapNode(), mapType)
				self._map:setLocation(x, y, node)
			end
		end

		x = 0
	end
end

-- cleanup - find a suitable start position
function FileMapBuilder:cleanup()
	local w, h = self._map:getSize()
	local startPos
	while nil == startPos do
		local x, y = Random(w), Random(h)
		local node = self._map:getLocation(x, y)
		if node:getMapType():isType('floor') then
			startPos = vector(x, y)
		end
	end

	self._map:setStartVector(startPos)
end

-- the class
return FileMapBuilder
