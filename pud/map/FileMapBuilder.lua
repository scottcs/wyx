local Class = require 'lib.hump.class'
local Rect = getClass 'pud.kit.Rect'
local MapBuilder = getClass 'pud.map.MapBuilder'
local MapType = getClass 'pud.map.MapType'
local FloorMapType = getClass 'pud.map.FloorMapType'
local WallMapType = getClass 'pud.map.WallMapType'
local DoorMapType = getClass 'pud.map.DoorMapType'
local StairMapType = getClass 'pud.map.StairMapType'
local TrapMapType = getClass 'pud.map.TrapMapType'
local MapNode = getClass 'pud.map.MapNode'
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
	for k in pairs(self._mapdata) do self._mapdata[k] = nil end
	self._mapdata = nil
	for k in pairs(self._stairs) do self._stairs[k] = nil end
	self._stairs = nil
	MapBuilder.destroy(self)
end

-- initialize the builder with a filename
function FileMapBuilder:init(filename)
	verify('string', filename)

	MapBuilder.init(self)

	-- check if the filename is actually a map name
	if not string.find(filename, '^map/%S-%.lua') then
		filename = 'map/'..filename..'.lua'
	end

	self._filename = filename
end

-- read the file and create the map
function FileMapBuilder:createMap()
	self:_loadMap()
	self:_newMap()
	self:_buildMap()
end

-- notify when map includes unknown keys
function FileMapBuilder:_checkMapKeys(map)
	local known = {
		map = 'map',
		glyphs = 'glyphs',
		name = 'name',
		author = 'author',
		handleDetail = 'handleDetail',
		zones = 'zones',
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
	verify('table', map.glyphs, map.zones)
	self:_checkMapKeys(map)
	self._mapdata = map
end

local _findVariant = function(mtype, n)
	local variants
	if isClass(FloorMapType, mtype) then
		variants = {'normal', 'worn', 'interior', 'rug'}
	elseif isClass(WallMapType, mtype) then
		variants = {'normal', 'worn', 'torch'}
	elseif isClass(DoorMapType, mtype) then
		variants = {'shut', 'open'}
	elseif isClass(StairMapType, mtype) then
		variants = {'up', 'down'}
	elseif isClass(TrapMapType, mtype) then
		variants = {'normal'}
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
					if     k == 'floor' then mtype = FloorMapType()
					elseif k == 'wall'  then mtype = WallMapType()
					elseif k == 'door'  then mtype = DoorMapType()
					elseif k == 'stair' then mtype = StairMapType()
					elseif k == 'trap'  then mtype = TrapMapType()
					end

					local variant = _findVariant(mtype,i)
					assert(variant ~= nil, 'Could not find variant %d for %s', i, k)
					mtype:setVariant(variant)
				end
			end
		elseif glyph == v then
			mtype = MapType(k)
		end
	end
	return mtype
end

-- determine width and height of map
function FileMapBuilder:_getMapSize()
	local width = #(string.match(self._mapdata.map, '%S+'))
	local height = 0
	local i = 0
	while true do
		i = string.find(self._mapdata.map, '\n', i+1)
		if nil == i then break end
		height = height + 1
	end
	return width, height
end

-- set the map size and empty all nodes
function FileMapBuilder:_newMap()
	local width, height = self:_getMapSize()
	self._map:setSize(width, height)
	self._map:clear()
	self._map:setName(self._mapdata.name)
	self._map:setAuthor(self._mapdata.author)
end

-- build the map
function FileMapBuilder:_buildMap()
	local x, y = 0, 0
	local width, height = self._map:getSize()

	for row in string.gmatch(self._mapdata.map, '%S+') do
		y = y + 1

		assert(#row == width, 'Map is unaligned. Expected width of %d for row '
			..'%d of the map, but found width %d.', width, y, #row)

		for col in string.gmatch(row, '%C') do
			x = x + 1
			local mapType = self:_glyphToMapType(self._mapdata.glyphs, col)
			if not mapType then
				warning('unknown mapType for glyph: %s',col)
			elseif not mapType:isType(MapType('empty')) then
				self._map:setLocation(x, y, MapNode(mapType))
			end
		end

		x = 0
	end
end

-- add dungeon features
function FileMapBuilder:addFeatures()
	for name,points in pairs(self._mapdata.zones) do
		if type(points) ~= 'table' and #points ~= 4 then
			warning('Invalid zone data for %s', name)
		else
			local tl,br = vector(points[1], points[2]),vector(points[3], points[4])
			if not (self._map:containsPoint(tl) and self._map:containsPoint(br))
			then
				warning('Zone boundaries for %s extend beyond map boundaries.', name)
			else
				self._map:setZone(name, Rect(tl, br - tl))
			end
		end
	end
end

-- post process step
-- a single step in the post process loop
function FileMapBuilder:postProcessStep(node, point)
	local mapType = node:getMapType()

	if isClass(StairMapType, mapType) then
		local variant = mapType:getVariant()
		self._stairs = self._stairs or {}
		self._stairs[variant] =
		self._stairs[variant] and self._stairs[variant]+1 or 1
		self._map:setPortal(variant..tostring(self._stairs[variant]), point)
	end

	if self._mapdata.handleDetail then
		if mapType:isType(FloorMapType('normal')) then
			if Random(12) == 1 then node:setMapType(FloorMapType('worn')) end
		elseif mapType:isType(WallMapType('normal')) then
			if Random(12) == 1 then
				node:setMapType(WallMapType('worn'))
			elseif Random(12) == 1 then
				node:setMapType(WallMapType('torch'))
			else
				node:setMapType(WallMapType('normal'))
			end
		end
	end
end


-- the class
return FileMapBuilder
