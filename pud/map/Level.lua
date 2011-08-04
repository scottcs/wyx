local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

-- map classes
local Map = require 'pud.map.Map'
local MapDirector = require 'pud.map.MapDirector'
local FileMapBuilder = require 'pud.map.FileMapBuilder'
local SimpleGridMapBuilder = require 'pud.map.SimpleGridMapBuilder'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'
local ZoneTriggerEvent = require 'pud.event.ZoneTriggerEvent'
local MapNode = require 'pud.map.MapNode'
local DoorMapType = require 'pud.map.DoorMapType'

-- events
local CommandEvent = require 'pud.event.CommandEvent'
local OpenDoorCommand = require 'pud.command.OpenDoorCommand'

-- entities
local HeroEntity = require 'pud.entity.HeroEntity'

-- time manager
local TimeManager = require 'pud.time.TimeManager'
local TICK = 0.01

local math_floor = math.floor
local math_round = function(x) return math_floor(x+0.5) end

local _testFiles = {
	'test1',
	'test2',
	'test3',
	'test4',
	'test5',
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

function Level:_attemptMove(entity)
	local moved = false

	if entity:wantsToMove() then
		local to = entity:getMovePosition()
		local node = self._map:getLocation(to.x, to.y)

		local oldEntityPos = entity:getPositionVector()
		entity:move(to, node)
		local entityPos = entity:getPositionVector()

		if entityPos ~= oldEntityPos then
			moved = true
			local zonesFrom = self._map:getZonesFromPoint(oldEntityPos)
			local zonesTo = self._map:getZonesFromPoint(entityPos)

			if zonesFrom then
				for zone in pairs(zonesFrom) do
					if zonesTo and zonesTo[zone] then
						zonesTo[zone] = nil
					else
						GameEvents:push(ZoneTriggerEvent(entity, zone, true))
					end
				end
			end

			if zonesTo then
				for zone in pairs(zonesTo) do
					GameEvents:push(ZoneTriggerEvent(entity, zone, false))
				end
			end
		end

		if node:getMapType():isType(DoorMapType('shut')) then
			local command = OpenDoorCommand(entity, to, self._map)
			CommandEvents:push(CommandEvent(command))
		end
	end

	return moved
end

function Level:_moveEntities()
	local heroMoved = self:_attemptMove(self._hero)
	if heroMoved then
		self._needViewUpdate = true
		self:_bakeLights()
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
		self:_bakeLights(true)
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
	if command:is_a(OpenDoorCommand) then
		command:setOnComplete(self._bakeLights, self)
	end
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
	local new_first

	for j=row,radius do
		local dx, dy = -j-1, -j
		local blocked = false

		while dx <= 0 do
			dx = dx + 1

			-- translate the dx, dy coordinates into map coordinates
			local mp = vector(c.x + dx * x.x + dy * x.y, c.y + dx * y.x + dy * y.y)
			-- lSlope and rSlope store the slopes of the left and right
			-- extremeties of the square we're considering
			local lSlope, rSlope = (dx-0.5)/(dy+0.5), (dx+0.5)/(dy-0.5)

			if last > lSlope then break end
			if not (first < rSlope) then
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

function Level:_resetLights(blackout)
	-- make old lit positions dim
	for x=1,self._map:getWidth() do
		self._lightmap[x] = self._lightmap[x] or {}
		for y=1,self._map:getHeight() do
			if blackout then
				self._lightmap[x][y] = 'black'
			else
				self._lightmap[x][y] = self._lightmap[x][y] or 'black'
				if self._lightmap[x][y] == 'lit' then self._lightmap[x][y] = 'dim' end
			end
		end
	end
end

function Level:_bakeLights(blackout)
	local radius = self._hero:getVisibilityRadius()
	local heroPos = self._hero:getPositionVector()

	self:_resetLights(blackout)

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
			vector(_mult[1][oct], _mult[2][oct]),
			vector(_mult[3][oct], _mult[4][oct]))
	end
end

-- get a color table of the lighting for the specified point
function Level:getLightingColor(p)
	local color = self._lightmap[p.x][p.y] or 'black'
	return self._lightColor[color]
end

-- the class
return Level