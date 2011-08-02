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
		self._lighting = {
			black = {0,0,0},
			dim = {0.4, 0.4, 0.4},
			lit = {1,1,1},
		}

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
		self._needViewUpdate = true

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
	if self._hero then self._hero:setPosition(self._map:getStartVector()) end
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
end

-- get a color table of the lighting for the specified point
function Level:getLightingColor(p)
	local node = self._map:getLocation(p.x, p.y)
	local radius = self._hero:getVisibilityRadius()
	local heroPos = self._hero:getPositionVector()
	local dist = math_round(heroPos:dist(p))

	if dist > radius then
		if node:wasSeen() then
			return self._lighting.dim
		else
			return self._lighting.none
		end
	end

	node:setSeen(true)
	return self._lighting.lit
end

-- the class
return Level
