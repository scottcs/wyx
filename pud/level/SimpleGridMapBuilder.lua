require 'pud.util'
local Class = require 'lib.hump.class'
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
local MINROOMSIZE = 4

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

-- private function to clear all rooms and the grid
local _clear = function(self)
	for i=1,#self._rooms do
		if self._rooms[i].destroy then
			self._rooms[i]:destroy()
		end
		self._rooms[i] = nil
	end
	for i=1,#self._grid do
		for j=1,#(self._grid[i]) do
			if self._grid[i][j].destroy then
				self._grid[i][j]:destroy()
			end
			self._grid[i][j] = nil
		end
		self._grid[i] = nil
	end
end

-- destructor
function SimpleGridMapBuilder:destroy()
	_clear(self)
	self._rooms = nil
	self._grid = nil

	MapBuilder.destroy(self)
end

-- initialize the builder
function SimpleGridMapBuilder:init(w, h, cellW, cellH, minRooms, maxRooms)
	local t = type(w) == 'table' and w or {
		w = w,
		h = h,
		cellW = cellW,
		cellH = cellH,
		minRooms = minRooms,
		maxRooms = maxRooms,
	}

	t.w, t.h = t.w or MAPW, t.h or MAPH
	MapBuilder.init(self, t.w, t.h)

	t.minRooms = t.minRooms or MINROOMS
	t.maxRooms = t.maxRooms or MAXROOMS

	t.cellW = t.cellW or CELLW
	t.cellH = t.cellH or CELLH
	verify('number', t.minRooms, t.maxRooms, t.cellW, t.cellH)

	-- make sure minRooms is <= maxRooms
	t.minRooms, t.maxRooms
		= math.min(t.minRooms, t.maxRooms), math.max(t.minRooms, t.maxRooms)

	-- check that the number of rooms will fit within the grid
	local gridW, gridH = math_floor(t.w/t.cellW), math_floor(t.h/t.cellH)
	local gridSize = (gridW-2) * (gridH-2)
	if t.maxRooms >= gridSize then
		io.stderr:write(string.format('maxRooms (%d) is too big, setting to %d\n',
			t.maxRooms, gridSize))
		t.maxRooms = gridSize
		t.minRooms = math.min(t.minRooms, gridSize)
	end

	self._numRooms = random(t.minRooms, t.maxRooms)
	self._cellW = t.cellW
	self._cellH = t.cellH
end

-- generate all the rooms with random sizes between min and max
function SimpleGridMapBuilder:createMap()
	local min = MINROOMSIZE
	local maxW, maxH = self._cellW-2, self._cellH-2

	-- clear any existing rooms and grid
	_clear(self)

	-- generate the rooms
	for i=1,self._numRooms do
		self._rooms[i] = Rect(0, 0, random(min, maxW), random(min, maxH))
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
		-- this assumes that numRooms is fairly small compared to grid size
		-- (and will become much slower as numRooms is increased)
		local x, y
		repeat
			x = random(2, w-1)
			y = random(2, h-1)
		until nil == self._grid[x][y].room

		-- get the center of the grid cell
		local cx, cy = self._grid[x][y]:getCenter(true)

		-- add the room in the center of the grid cell
		self._rooms[i]:setCenter(cx, cy, true)
		self._grid[x][y].room = self._rooms[i]
	end

	-- populate the map with the rooms
	for i=1,self._numRooms do
		local room = self._rooms[i]
		local x1, y1, x2, y2 = room:getBBox()
		
		-- reduce the max coords by one for easy iteration
		x2, y2 = x2 - 1, y2 - 1

		-- iterate over the bounding box of the room and add nodes
		for x=x1,x2 do
			for y=y1,y2 do
				if x == x1 or x == x2 or y == y1 or y == y2 then
					local node = self._map:setNodeMapType(MapNode(), MapType.wall)
					self._map:setLocation(x, y, node)
				else
					local node = self._map:setNodeMapType(MapNode(), MapType.floor)
					self._map:setLocation(x, y, node)
				end
			end
		end
		if i > 1 then
			self:_connectRooms(self._rooms[i-1], self._rooms[i])
		end
	end
end

-- connect the rooms together
function SimpleGridMapBuilder:_connectRooms(room1, room2)
	local x1, y1 = room1:getCenter(true)
	local x2, y2 = room2:getCenter(true)
	local xDir, yDir

	local x, y = x1, y1

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
			self._map:setNodeMapType(node, MapType.floor)

			-- if the location below this one is empty, make it a wall
			node = self._map:getLocation(x, y1-1)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end

			-- if the location above this one is empty, make it a wall
			node = self._map:getLocation(x, y1+1)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end
		until x == x2

		-- check those corners
		if yDir then
			local node = self._map:getLocation(x+xDir, y1-yDir)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end

			local node = self._map:getLocation(x, y1-yDir)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end

			local node = self._map:getLocation(x+xDir, y1)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end
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
			self._map:setNodeMapType(node, MapType.floor)

			-- if the tile left of the current one is empty, make it a wall
			node = self._map:getLocation(x-1, y)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end

			-- if the tile right of the current one is empty, make it a wall
			node = self._map:getLocation(x+1, y)
			if node:getMapType() == MapType.empty then
				self._map:setNodeMapType(node, MapType.wall)
			end
		until y == y2
	end
end

-- add doors to some rooms
function SimpleGridMapBuilder:addFeatures()
	for i=1,self._numRooms do
		-- randomly add doors to every 3rd room
		if random(3) == 1 then
			local x1, y1, x2, y2 = self._rooms[i]:getBBox()

			-- walk along the room edges and plug holes with doors
			for x=x1,x2 do
				if x == x1 or x == x2 then
					-- walk along the sides of the room
					for y=y1,y2 do
						local node = self._map:getLocation(x, y)
						if node:getMapType() == MapType.floor then
							self._map:setNodeMapType(node, MapType.doorC)
						end
					end
				else
					-- walk along the top and bottom of the room
					for _,y in ipairs{y1, y2} do
						local node = self._map:getLocation(x, y)
						if node:getMapType() == MapType.floor then
							self._map:setNodeMapType(node, MapType.doorC)
						end
					end
				end
			end
		end
	end
end

-- perform any cleanup needed on the map
function SimpleGridMapBuilder:cleanup()
end

-- the class
return SimpleGridMapBuilder
