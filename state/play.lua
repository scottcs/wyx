
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

-- Time Manager
local TimeManager = require 'pud.time.TimeManager'
local TimedObject = require 'pud.time.TimedObject'
local _timeManager

-- map builder
local LevelDirector = require 'pud.level.LevelDirector'

-- level view
local TileLevelView = require 'pud.level.TileLevelView'

-- events
local OpenDoorEvent = require 'pud.event.OpenDoorEvent'
local GameStartEvent = require 'pud.event.GameStartEvent'
local MapUpdateFinishedEvent = require 'pud.event.MapUpdateFinishedEvent'

function st:init()
	_timeManager = TimeManager()
	self._view = TileLevelView(100, 100)
	self._view:registerEvents()
end

function st:enter()
	local player = TimedObject()
	local dragon = TimedObject()
	local ifrit = TimedObject()

	player.name = 'Player'
	dragon.name = 'Dragon'
	ifrit.name = 'Ifrit'

	local test = false

	function player:OpenDoorEvent(e)
		if test then
			print('player')
			print(tostring(e))
		end
	end

	function dragon:onEvent(e)
		if test then
			print('dragon')
			print(tostring(e))
		end
	end

	function ifrit:onEvent(e)
		if test then
			print('ifrit')
			print(tostring(e))
		end
	end

	function player:getSpeed(ap) return 1 end
	function player:doAction(ap)
		GameEvent:notify(GameStartEvent(), 234, ap)
		return 2
	end

	function dragon:getSpeed(ap) return 1.03 end
	function dragon:doAction(ap)
		return 5
	end

	function ifrit:getSpeed(ap) return 1.27 end
	function ifrit:doAction(ap)
		GameEvent:push(OpenDoorEvent(self.name))
		return 2
	end

	local function ifritOpenDoorCB(e)
		ifrit:onEvent(e)
	end

	GameEvent:register(player, OpenDoorEvent)
	GameEvent:register(ifritOpenDoorCB, OpenDoorEvent)
	GameEvent:register(dragon, GameStartEvent)

	_timeManager:register(player, 3)
	_timeManager:register(dragon, 3)
	_timeManager:register(ifrit, 3)

	-- map test
	---[[--
	local SimpleGridMapBuilder = require 'pud.level.SimpleGridMapBuilder'
	local builder = SimpleGridMapBuilder()
	self._map = LevelDirector:generateStandard(builder, 100,100, 10,10, 20,35)
	--]]--
	--[[--
	local FileMapBuilder = require 'pud.level.FileMapBuilder'
	local builder = FileMapBuilder()
	self._map = LevelDirector:generateStandard(builder, 'test')
	--]]--

	builder:destroy()
end


local _accum = 0
local _count = 0
local TICK = 0.01

function st:update(dt)
	_accum = _accum + dt
	if _accum > TICK then
		_count = _count + 1
		_accum = _accum - TICK
		_timeManager:tick()
		if _count % 100 == 0 and self._map then
			GameEvent:push(MapUpdateFinishedEvent(self._map))
		end
	end
end

function st:draw()
	self._view:draw()
end

function st:leave()
	_timeManager:destroy()
end

function st:keypressed(key, unicode)
	switch(key) {
		escape = function() love.event.push('q') end,
	}
end

return st
