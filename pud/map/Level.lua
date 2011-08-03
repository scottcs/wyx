local Class = require 'lib.hump.class'

-- map classes
local Map = require 'pud.map.Map'
local MapDirector = require 'pud.map.MapDirector'
local FileMapBuilder = require 'pud.map.FileMapBuilder'
local SimpleGridMapBuilder = require 'pud.map.SimpleGridMapBuilder'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'
local MapNode = require 'pud.map.MapNode'

-- events
local CommandEvent = require 'pud.event.CommandEvent'
local OpenDoorCommand = require 'pud.command.OpenDoorCommand'

-- entities
local HeroEntity = require 'pud.entity.HeroEntity'

-- time manager
local TimeManager = require 'pud.time.TimeManager'
local TICK = 0.01

-- line algorithm
local Line = require 'pud.kit.Line'

local math_floor = math.floor
local math_round = function(x) return math_floor(x+0.5) end

local _testFiles = {
	'test',
}

-- Level
--
local Level = Class{name='Level',
	function(self)
		self._timeManager = TimeManager()
		self._doTick = false
		self._accum = 0

		-- lighting color value table
		self._lightColor = {
			black = {0,0,0},
			dim = {0.4, 0.4, 0.4},
			lit = {1,1,1},
		}
		self._lightmap = {}

		CommandEvents:register(self, CommandEvent)
	end
}

-- destructor
function Level:destroy()
	CommandEvents:unregisterAll(self)
	self._map:destroy()
	self._map = nil
	self._hero:destroy()
	self._hero = nil
	self._doTick = nil
	self._timeManager:destroy()
	self._timeManager = nil
	for k in pairs(self._lightColor) do self._lightColor[k] = nil end
	self._lightColor = nil
	for k in pairs(self._lightmap) do self._lightmap[k] = nil end
	self._lightmap = nil
end

function Level:update(dt)
	if self._doTick then
		self._accum = self._accum + dt
		if self._accum > TICK then
			self._accum = self._accum - TICK
			local nextActor = self._timeManager:tick()
			local numHeroCommands = self._hero:getPendingCommandCount()
			self._doTick = nextActor ~= self._hero or numHeroCommands > 0
		end
	end

	self:_moveEntities()
end

function Level:_moveEntities()
	if self._hero:wantsToMove() then
		local to = self._hero:getMovePosition()
		local node = self._map:getLocation(to.x, to.y)
		self._hero:move(to, node)
		local heroPos = self._hero:getPositionVector()
		if heroPos == to then
			self._needViewUpdate = true
			self:_bakeLights()
		end

		if node:getMapType():isType('doorClosed') then
			local command = OpenDoorCommand(self._hero, to, self._map)
			CommandEvents:push(CommandEvent(command))
		end
	end
end

function Level:needViewUpdate() return self._needViewUpdate == true end
function Level:postViewUpdate() self._needViewUpdate = false end

function Level:generateFileMap(file)
	file = file or _testFiles[Random(#_testFiles)]
	local builder = FileMapBuilder(file)
	self:_generateMap(builder)
end

function Level:generateSimpleGridMap()
	local builder = SimpleGridMapBuilder(80,80, 10,10, 8,16)
	self:_generateMap(builder)
end

function Level:_generateMap(builder)
	if self._map then self._map:destroy() end
	self._map = MapDirector:generateStandard(builder)
	if self._hero then
		self._hero:setPosition(self._map:getStartVector())
		self:_bakeLights()
	end
	builder:destroy()
	GameEvents:push(MapUpdateFinishedEvent(self._map))
end

-- get the start vector from the map
function Level:getStartVector() return self._map:getStartVector() end

-- get the size of the map
function Level:getMapSize() return self._map:getSize() end

-- get the MapNode at the given location on the map
function Level:getMapNode(...) return self._map:getLocation(...) end

-- return true if the given map is our map
function Level:isMap(map) return map == self._map end

-- return true if the given point exists on the map
function Level:isPointInMap(...) return self._map:containsPoint(...) end

-- return the hero entity
function Level:getHero() return self._hero end

function Level:createEntities()
	self._hero = HeroEntity()
	self._hero:setSize(1, 1)
	self._timeManager:register(self._hero, 0)
end

function Level:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self._hero then return end
	self._doTick = true
	self._needViewUpdate = true
end

-- bake the lighting for the current hero position
local _mult = {
	{ 1,  0,  0, -1, -1,  0,  0,  1},
	{ 0,  1, -1,  0,  0, -1,  1,  0},
	{ 0,  1,  1,  0,  0, -1, -1,  0},
	{ 1,  0,  0,  1, -1,  0,  0, -1},
}

-- recursive light casting function
function Level:_castLight(c, row, first, last, radius, x, y)
	if first < last then return end
	local radiusSq = radius*radius
	local new_first = first

	for j=row,radius do
		local dx, dy = -j-1, -j
		local blocked = false

		while dx <= 0 do
			dx = dx + 1

			-- translate the dx, dy coordinates into map coordinates
			local mp = vector(c.x + dx * x.x + dy * x.y, c.y + dx * y.x + dy * y.y)
			print(mp)
			-- lSlope and rSlope store the slopes of the left and right
			-- extremeties of the square we're considering
			local lSlope, rSlope = (dx-0.5)/(dy+0.5), (dx+0.5)/(dy-0.5)

			if last > lSlope then break end
			if not first < rSlope then
				-- our light beam is touching this square; light it
				if dx*dx + dy*dy < radiusSq then
					self._lightmap[mp.x][mp.y] = 'lit'
				end

				local node = self._map:getLocation(mp.x, mp.y)
				if blocked then
					-- we're scanning a row of blocked squares
					if not (self:isPointInMap(mp) and node:isTransparent()) then
						new_first = rSlope
						-- Note: this would be a continue statement... make sure nothing
						-- else is calculated after this
					else
						blocked = false
						first = new_first
					end
				else
					if not (self:isPointInMap(mp) and node:isTransparent())
						and j < radius
					then
						-- this is a blocking square, start a child scan
						blocked = true
						self:_castLight(c, j+1, first, lSlope, radius, x, y)
						new_first = rSlope
					end
				end
			end
		end

		if blocked then break end
	end
end

function Level:_bakeLights()
	local radius = self._hero:getVisibilityRadius()
	local heroPos = self._hero:getPositionVector()

	-- make old lit positions dim
	for x=1,self._map:getWidth() do
		self._lightmap[x] = self._lightmap[x] or {}
		for y=1,self._map:getHeight() do
			self._lightmap[x][y] = self._lightmap[x][y] or 'black'
			if self._lightmap[x][y] == 'lit' then self._lightmap[x][y] = 'dim' end
		end
	end

	for oct=1,8 do
		self:_castLight(heroPos, 1, 1, 0, radius,
			vector(_mult[0][oct], _mult[1][oct]),
			vector(_mult[2][oct], _mult[3][oct]))
	end
end

-- get a color table of the lighting for the specified point
function Level:getLightingColor(p)
	local node = self._map:getLocation(p.x, p.y)
	local radius = self._hero:getVisibilityRadius()
	local heroPos = self._hero:getPositionVector()

	if p == heroPos then return self._lightColor.lit end

	local dist = math_round(heroPos:dist(p))

	if dist > radius then
		if node:wasSeen() then
			return self._lightColor.dim
		else
			return self._lightColor.none
		end
	end

	local line = Line(heroPos, p)
	local blocked = false
	local l
	repeat
		l = line:next()
		if l then
			if not self:isPointInMap(l) then
				blocked = true
				break
			end

			local node = self._map:getLocation(l.x, l.y)
			if not node:isTransparent() then
				blocked = true
				break
			end
		end
	until not l

	blocked = blocked and l ~= p

	-- check neighbors for lit floor and unblock if found
	if blocked and l == p then
		local check = {-1, 0, 1}
		for x=1,3 do
			for y=1,3 do
				if not (x == 2 and y == 2) then
					local node = self._map:getLocation(p.x + check[x], p.y + check[y])
					if node:isTransparent() then
						blocked = false
						break
					end
				end
			end
			if not blocked then break end
		end
	end

	if blocked then
		if node:wasSeen() then
			return self._lightColor.dim
		else
			return self._lightColor.none
		end
	else
		node:setSeen(true)
		return self._lightColor.lit
	end
end

-- the class
return Level
