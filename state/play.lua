
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

-- Time Manager
local TimeManager = require 'pud.timemanager'
local TimedObject = require 'pud.timedobject'
local _timeManager

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

	function player:getSpeed(ap) return 1 end
	function player:doAction(ap)
		print(self.name..'   ap: '..tostring(ap))
		GameEvent:trigger('OPEN_DOOR', self.name, 234, ap)
		return 2
	end

	function dragon:getSpeed(ap) return 1.03 end
	function dragon:doAction(ap)
		print(self.name..'   ap: '..tostring(ap))
		GameEvent:push('OPEN_DOOR', self.name)
		return 5
	end

	function ifrit:getSpeed(ap) return 1.27 end
	function ifrit:doAction(ap)
		print(self.name..'   ap: '..tostring(ap))
		GameEvent:push('OPEN_DOOR', self.name)
		return 2
	end

	function player:OPEN_DOOR(...)
		print('player OPEN_DOOR')
		for i=1,select('#',...) do
			print(i..': '..(select(i,...)))
		end
	end

	function dragon:onEvent(e, ...)
		print('dragon '..e)
		for i=1,select('#',...) do
			print(i..': '..(select(i,...)))
		end
	end

	function ifrit:onEvent(e, ...)
		print('ifrit '..e)
	end

	local function testi(...)
		print('testi')
		for i=1,select('#',...) do
			print(i..': '..(select(i,...)))
		end
	end

	print(type(player))
	GameEvent:register(player, 'OPEN_DOOR')
	GameEvent:register(dragon, 'OPEN_DOOR')
	GameEvent:register(ifrit, 'OPEN_DOOR')
	GameEvent:register(testi, 'OPEN_DOOR')

	print('begin')
	_timeManager:register(player, 3)
	_timeManager:register(dragon, 3)
	_timeManager:register(ifrit, 3)
end

local _accum = 0
local _count = 0
local TICK = 0.1
function st:update(dt)
	_accum = _accum + dt
	if _accum > TICK then
		_count = _count + 1
		_accum = _accum - TICK
		print(_count)
		_timeManager:tick()
	end
end

function st:draw()
end

function st:leave()
	_timeManager:destroy()
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
	}
end

return st
