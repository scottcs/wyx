local MapBuilder = require 'pud.level.MapBuilder'
local MapType = require 'pud.level.MapType'
local MapNode = require 'pud.level.MapNode'
local Rect = require 'pud.kit.Rect'

local random = math.random
local math_floor = math.floor

--------------
-- DEFAULTS --
--------------
local CELLW, CELLH = 10, 10
local MAPW, MAPH = 100, 100
local MINROOMS, MAXROOMS = 25, 45

--------------------------
-- SimpleGridMapBuilder --
--------------------------
local SimpleGridMapBuilder = Class{name='SimpleGridMapBuilder',
	inherits = MapBuilder,
	function(self)
		MapBuilder.construct(self)
		self._grid = {}
		self._rooms = {}
	end
}

-- set the correct flags and map type on a map node to make it a floor
local _setFloor = function(node)
	node:setMapType(MapType.floor)
	node:setLit(true)
	node:setAccessible(true)
	node:setTransparent(true)
end

-- set the correct flags and map type on a map node to make it a wall
local _setWall = function(node)
	node:setMapType(MapType.wall)
	node:setLit(true)
	node:setAccessible(false)
	node:setTransparent(false)
end

-- initialize the builder
function MapBuilder:init(w, h, minRooms, maxRooms, cellW, cellH)
	w, h = w or MAPW, h or MAPH
	MapBuilder.init(self, w, h)

	cellW = cellW or CELLW
	cellH = cellH or CELLH
	minRooms = minRooms or MINROOMS
	maxRooms = maxRooms or MAXROOMS
	verify('number', minRooms, maxRooms, cellW, cellH)

	self._numRooms = random(minRooms, maxRooms)
	self._cellW = cellW
	self._cellH = cellH
end

-- generate all the rooms with random sizes between min and max
function SimpleGridMapBuilder:createRooms(min, max)
	verify('number', min, max)

	-- clear any existing rooms and grid
	for i=1,#self._rooms do self._rooms[i] = nil end
	for i=1,#self._grid do self._grid[i] = nil end

	-- generate the rooms
	for i=1,self._numRooms do
		self._rooms[i] = Rect(0, 0, random(min, max), random(min, max))
	end

	-- build a new grid
	local w, h = self._map:getSize()
	w, h = math_floor(w/self._cellW), math_floor(h/self._cellH)
	local gx, gy = 1, 1
	for i=1,w do
		self._grid[i] = {}
		for j = 1,h do
			self._grid[i][j] = Rect(gx, gy, self._cellW, self._cellH)
			gy = gy + self._cellH
		end
		gy = 1
		gx = gx + self._cellW
	end

	-- add rooms to the grid
	for i = 1,self._numRooms do
		-- find an empty spot in the grid
		local x, y
		repeat
			x = random(2, w-1)
			y = random(2, h-1)
		until nil == self._grid[x][y].room

		-- get the center of the grid cell
		local cx = x + math_floor(self._cellW/2)
		local cy = y + math_floor(self._cellH/2)

		-- add the room in the center of the grid cell
		self._rooms[i]:setCenter(cx, cy)
	end

	-- populate the map with the rooms
	for i=1,self._numRooms do
		local room = self._rooms[i]
		local x1, y1, x2, y2 = room:getBBox()
		for x=x1,x2 do
			for y=y1,y2 do
				if x == x1 or x == x2 or y == y1 or y == y2 then
					self._map:setLocation(x, y, _setWall(MapNode()))
				else
					self._map:setLocation(x, y, _setFloor(MapNode()))
				end
			end
		end
	end
end

-- connect the rooms together
function SimpleGridMapBuilder:connectRooms()
	for i=2,self._numRooms do
		local room1 = self._rooms[i-1]
		local room2 = self._rooms[i]
		local x1, y1, x2, y2 = room1:getCenter(), room2:getCenter()
		local x, y = x1, y1
		local xDir, yDir

		if x < x2 then xDir =  1 end
		if x > x2 then xDir = -1 end
		if y < y2 then yDir =  1 end
		if y > y2 then yDir = -1 end

		if xDir then
			local wallFlag = false
			repeat
				x = x + xDir

				-- check if we've hit a wall
				local node = self._map:getLocation(x, y1)
				if node:getMapType() == MapType.wall then wallFlag = true end

				-- once we've tunneled through the wall and hit floor, break
				if node:getMapType() == MapType.floor and wallFlag then break end

				-- make the current location a floor
				_setFloor(node)

				-- if the location below this one is empty, make it a wall
				node = self._map:getLocation(x, y1-1)
				if node:getMapType() == MapType.empty then _setWall(node) end

				-- if the location above this one is empty, make it a wall
				node = self._map:getLocation(x, y1+1)
				if node:getMapType() == MapType.empty then _setWall(node) end
			until x == x2

			-- check those corners
			if yDir then
				local node = self._map:getLocation(x+xDir, y1-yDir)
				if node:getMapType() == MapType.empty then _setWall(node) end

				local node = self._map:getLocation(x, y1-yDir)
				if node:getMapType() == MapType.empty then _setWall(node) end

				local node = self._map:getLocation(x+xDir, y1)
				if node:getMapType() == MapType.empty then _setWall(node) end
			end
		end

		if yDir then
			local wallFlag = false
			repeat
				y = y + yDir

				-- check if we've hit a wall
				local node = self._map:getLocation(x, y)
				if node:getMapType() == MapType.wall then wallFlag = true end

				-- once we've tunneled through a wall and hit floor, break
				if node:getMapType() == MapType.floor and wallFlag then break end

				-- make the current tile a floor
				_setFloor(node)

				-- if the tile left of the current one is empty, make it a wall
				node = self._map:getLocation(x-1, y)
				if node:getMapType() == MapType.empty then _setWall(node) end

				-- if the tile right of the current one is empty, make it a wall
				node = self._map:getLocation(x+1, y)
				if node:getMapType() == MapType.empty then _setWall(node) end
			until y == y2
		end
	end
end

-- add doors to some rooms
function SimpleGridMapBuilder:addDoors()
end

-- perform any cleanup needed on the map
function SimpleGridMapBuilder:cleanup()
end

-- the class
return SimpleGridMapBuilder
