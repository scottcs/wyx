local Class = require 'lib.hump.class'
local MapBuilder = getClass 'pud.map.MapBuilder'
local MapNode = getClass 'pud.map.MapNode'
local MapType = getClass 'pud.map.MapType'
local FloorMapType = getClass 'pud.map.FloorMapType'
local WallMapType = getClass 'pud.map.WallMapType'
local DoorMapType = getClass 'pud.map.DoorMapType'
local StairMapType = getClass 'pud.map.StairMapType'
local TrapMapType = getClass 'pud.map.TrapMapType'
local Rect = getClass 'pud.kit.Rect'

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
	function(self, ...)
		self._seed = Random()
		self._random = Random.new(self._seed)
		self._grid = {}
		self._rooms = {}
		-- construct calls self:init(...)
		MapBuilder.construct(self, ...)
	end
}

-- private function to clear all rooms and the grid
function SimpleGridMapBuilder:_clear()
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
	self:_clear()
	self._rooms = nil
	self._grid = nil
	self._numRooms = nil
	self._map = nil
	self._cellW = nil
	self._cellH = nil

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
		warning('maxRooms (%d) is too big, setting to %d', t.maxRooms, gridSize)
		t.maxRooms = gridSize
		t.minRooms = math.min(t.minRooms, gridSize)
	end

	self._numRooms = self._random(t.minRooms, t.maxRooms)
	self._cellW = t.cellW
	self._cellH = t.cellH
end

-- generate all the rooms with random sizes between min and max
function SimpleGridMapBuilder:createMap()
	self._map:setName('Random_'..tostring(self._seed))
	self._map:setAuthor('Pud')
	self:_clear()
	self:_generateRooms()
	self:_buildGrid()
	self:_populateGrid()
	self:_populateMap()
end

-- generate the rooms
function SimpleGridMapBuilder:_generateRooms()
	for i=1,self._numRooms do
		self._rooms[i] = Rect(0, 0,
			self._random(MINROOMSIZE, self._cellW),
			self._random(MINROOMSIZE, self._cellH))
	end
end

-- get width and height of grid in cells
function SimpleGridMapBuilder:_getGridSize()
	local w, h = self._map:getSize()
	return math_floor(w/self._cellW), math_floor(h/self._cellH)
end

-- build a new grid
function SimpleGridMapBuilder:_buildGrid()
	local w, h = self:_getGridSize()
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
end

-- add rooms to the grid
function SimpleGridMapBuilder:_populateGrid()
	local w, h = self:_getGridSize()

	for i = 1,self._numRooms do
		-- find an empty spot in the grid
		-- this assumes that numRooms is fairly small compared to grid size
		-- (and will become much slower as numRooms is increased)
		local x, y
		repeat
			x = self._random(2, w-1)
			y = self._random(2, h-1)
		until nil == self._grid[x][y].room

		-- get the center of the grid cell
		local cx, cy = self._grid[x][y]:getCenter('floor')

		-- add the room in the center of the grid cell
		self._rooms[i]:setCenter(cx, cy, 'floor')
		self._grid[x][y].room = self._rooms[i]
	end
end

local _setWallIfEmpty = function(node)
	if node:getMapType():isType(MapType('empty')) then
		node:setMapType(WallMapType())
	end
end

-- populate the map with the rooms
function SimpleGridMapBuilder:_populateMap()
	for i=1,self._numRooms do
		local room = self._rooms[i]
		local x1, y1, x2, y2 = room:getBBox()
		
		-- iterate over the bounding box of the room and add nodes
		for x=x1,x2 do
			for y=y1,y2 do
				if x == x1 or x == x2 or y == y1 or y == y2 then
					_setWallIfEmpty(self._map:getLocation(x, y))
				else
					self._map:setLocation(x, y, MapNode(FloorMapType()))
				end
			end
		end
	end

	for i=1,self._numRooms do
		if i > 1 then
			-- connect this room to the previous room
			self:_connectRooms(self._rooms[i-1], self._rooms[i])
		end
	end

	-- connect the last room to the first room
	self:_connectRooms(self._rooms[1], self._rooms[self._numRooms])
end

-- connect the rooms together
function SimpleGridMapBuilder:_connectRooms(room1, room2)
	local x1, y1 = room1:getCenter('floor')
	local x2, y2 = room2:getCenter('floor')
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
			local node = self._map:getLocation(x, y1)

			-- check if we've hit a wall
			if room2:containsPoint(x, y2)
				and node:getMapType():is_a(WallMapType)
			then
				wallFlag = true
			end

			-- once we've tunneled through the wall and hit floor, break
			if node:getMapType():is_a(FloorMapType) and wallFlag then break end

			-- make the current location a floor
			node:setMapType(FloorMapType())

			-- if the location below this one is empty, make it a wall
			_setWallIfEmpty(self._map:getLocation(x, y1-1))

			-- if the location above this one is empty, make it a wall
			_setWallIfEmpty(self._map:getLocation(x, y1+1))
		until x == x2

		-- check those corners
		if yDir then
			_setWallIfEmpty(self._map:getLocation(x+xDir, y1-yDir))
			_setWallIfEmpty(self._map:getLocation(x, y1-yDir))
			_setWallIfEmpty(self._map:getLocation(x+xDir, y1))
		end
	end

	if yDir then
		local wallFlag = false
		repeat
			y = y + yDir
			local node = self._map:getLocation(x, y)

			-- check if we've hit a wall
			if room2:containsPoint(x2, y)
				and node:getMapType():is_a(WallMapType)
			then
				wallFlag = true
			end

			-- once we've tunneled through a wall and hit floor, break
			if node:getMapType():is_a(FloorMapType) and wallFlag then break end

			-- make the current location a floor
			node:setMapType(FloorMapType())

			-- if the tile left of the current one is empty, make it a wall
			_setWallIfEmpty(self._map:getLocation(x-1, y))

			-- if the tile right of the current one is empty, make it a wall
			_setWallIfEmpty(self._map:getLocation(x+1, y))
		until y == y2
	end
end


-- determine if a door should be placed in this node, then place it
function SimpleGridMapBuilder:_placeDoor(x, y)
	local node = self._map:getLocation(x, y)
	local ok = true

	if node:getMapType():is_a(FloorMapType) then
		local top = self._map:getLocation(x, y-1)
		local bottom = self._map:getLocation(x, y+1)
		local left = self._map:getLocation(x-1, y)
		local right = self._map:getLocation(x+1, y)

		local topMT = top:getMapType()
		local bottomMT = bottom:getMapType()
		local leftMT = left:getMapType()
		local rightMT = right:getMapType()

		local shut = DoorMapType('shut')

		-- make sure no adjacent node is a door
		if not (topMT:isType(shut) or bottomMT:isType(shut)
			or leftMT:isType(shut) or rightMT:isType(shut))
		then
			local placeDoor = false

			-- check top and bottom neighbors for floor
			if isClass(WallMapType, topMT) and isClass(WallMapType, bottomMT) then
				placeDoor = true
			else
				-- top or bottom was floor, so now check sides
				if isClass(WallMapType, leftMT) and isClass(WallMapType, rightMT) then
					placeDoor = true
				else
					ok = false
				end
			end

			if placeDoor then
				node:setMapType(shut)
			end
		else
			ok = false
		end
	end
	return ok
end

-- add doors to some rooms
function SimpleGridMapBuilder:addFeatures()
	for i=1,self._numRooms do
		-- randomly add doors to every 3rd room
		if self._random(3) == 1 then
			local x1, y1, x2, y2 = self._rooms[i]:getBBox()
			local enclosed = true

			-- walk along the room edges and plug holes with doors
			for x=x1,x2 do
				if x == x1 or x == x2 then
					-- walk along the sides of the room
					for y=y1,y2 do
						if not self:_placeDoor(x, y) then
							enclosed = false
						end
					end
				else
					-- walk along the top and bottom of the room
					for _,y in ipairs{y1, y2} do
						if not self:_placeDoor(x, y) then
							enclosed = false
						end
					end
				end
			end

			-- now change floor if the room is completely enclosed by doors
			if enclosed then
				x1, y1 = x1+1, y1+1
				x2, y2 = x2-1, y2-1

				self._map:setZone('room'..tostring(i), Rect(x1, y1, x2-x1, y2-y1))

				for x=x1,x2 do
					for y=y1,y2 do
						local node = self._map:getLocation(x, y)
						local mapType = node:getMapType()
						if isClass(FloorMapType, mapType) then
							node:setMapType(FloorMapType('interior'))
						end
					end
				end
			end
		end
	end
end

-- add portals to the map -- up and down stairs in this case
function SimpleGridMapBuilder:addPortals()
	local rooms = {}
	for i=1,self._numRooms do rooms[i] = i end
	local stairs = 6
	while stairs > 0 do
		local direction = stairs > 3 and 'up' or 'down'
		local num = stairs > 3 and stairs-3 or stairs
		local room = table.remove(rooms, self._random(#rooms))
		local x1,y1, x2,y2 = self._rooms[room]:getBBox()
		local x, y = self._random(x1+1, x2-1), self._random(y1+1, y2-1)
		local node = self._map:getLocation(x, y)
		if node:getMapType():is_a(FloorMapType) then
			node:setMapType(StairMapType(direction))
			self._map:setPortal(direction..tostring(num), x, y)
			stairs = stairs - 1
		end
	end
end

-- post process step
-- a single step in the post process loop
function SimpleGridMapBuilder:postProcessStep(node, x, y)
	local mapType = node:getMapType()
	local variant = mapType:getVariant()

	if isClass(FloorMapType, mapType) and self._random(1,12) == 1 then
		if variant == 'interior' then
			node:setMapType(FloorMapType('rug'))
		else
			if self._random(1,20) > 1 then
				node:setMapType(FloorMapType('worn'))
			else
				node:setMapType(TrapMapType())
			end
		end
	elseif isClass(WallMapType, mapType) and variant ~= 'vertical' then
		if self._random(1,12) == 1 then
			node:setMapType(WallMapType('worn'))
		elseif self._random(1,12) == 1 then
			node:setMapType(WallMapType('torch'))
		else
			node:setMapType(WallMapType('normal'))
		end
	end
end


-- the class
return SimpleGridMapBuilder
