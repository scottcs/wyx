
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

function st:init()
	_timeManager = TimeManager()
end

function st:enter()
	local player = TimedObject()
	local dragon = TimedObject()
	local ifrit = TimedObject()

	player.name = 'Player'
	dragon.name = 'Dragon'
	ifrit.name = 'Ifrit'

	function player:OPEN_DOOR(...)
		print('player')
		for i=1,select('#',...) do
			print(i, select(i, ...))
		end
	end

	function dragon:onEvent(e, ...)
		print('dragon')
		for i=1,select('#',...) do
			print(i, select(i, ...))
		end
	end

	function ifrit:onEvent(e, ...)
		print('ifrit')
	end

	function player:getSpeed(ap) return 1 end
	function player:doAction(ap)
		GameEvent:notify(Event.GameStart(), 234, ap)
		return 2
	end

	function dragon:getSpeed(ap) return 1.03 end
	function dragon:doAction(ap)
		GameEvent:push(Event.MapUpdateRequest())
		return 5
	end

	function ifrit:getSpeed(ap) return 1.27 end
	function ifrit:doAction(ap)
		GameEvent:push(Event.OpenDoor(self.name))
		return 2
	end

	GameEvent:register(player.OPEN_DOOR, 'OpenDoor')
	GameEvent:register(dragon, 'GameStart')
	GameEvent:register(ifrit, 'MapUpdateRequest')

	_timeManager:register(player, 3)
	_timeManager:register(dragon, 3)
	_timeManager:register(ifrit, 3)

	-- map test
	---[[--
	local SimpleGridMapBuilder = require 'pud.level.SimpleGridMapBuilder'
	local builder = SimpleGridMapBuilder()
	local map = LevelDirector:generateStandard(builder, 100,100, 10,10, 20,35)
	--]]--
	--[[--
	local FileMapBuilder = require 'pud.level.FileMapBuilder'
	local builder = FileMapBuilder()
	local map = LevelDirector:generateStandard(builder, 'test')
	--]]--

	builder:destroy()
	print(tostring(map))
end


local _accum = 0
local TICK = 0.01

function st:update(dt)
	_accum = _accum + dt
	if _accum > TICK then
		_accum = _accum - TICK
		_timeManager:tick()
	end
end

function st:draw()
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
