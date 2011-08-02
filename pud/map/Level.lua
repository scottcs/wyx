local Class = require 'lib.hump.class'

-- map classes
local Map = require 'pud.map.Map'
local MapDirector = require 'pud.map.MapDirector'
local FileMapBuilder = require 'pud.map.FileMapBuilder'
local SimpleGridMapBuilder = require 'pud.map.SimpleGridMapBuilder'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'

-- events
local CommandEvent = require 'pud.event.CommandEvent'

-- entities
local HeroEntity = require 'pud.entity.HeroEntity'

-- time manager
local TimeManager = require 'pud.time.TimeManager'
local TICK = 0.01

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
end

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

	-- listen for hero commands
	CommandEvents:register(self, CommandEvent)
end

function Level:CommandEvent(e)
	local command = e:getCommand()
	if command:getTarget() ~= self._hero then return end
	self._doTick = true
end

-- the class
return Level
