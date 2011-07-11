
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local TimeManager = require 'pud.timemanager'
local TimedObject = require 'pud.timedobject'
local _timeManager

function st:init()
	_timeManager = TimeManager()
end

function st:enter()
	--GameState.switch(State.demo)
	local player = TimedObject()
	local dragon = TimedObject()
	local ifrit = TimedObject()

	player.name = 'Player'
	dragon.name = 'Dragon'
	ifrit.name = 'Ifrit'

	function player:getSpeed(ap) return 1 end
	function player:doAction(ap)
		print(self.name..'   ap: '..tostring(ap))
		return 2
	end

	function dragon:getSpeed(ap) return 1.03 end
	function dragon:doAction(ap)
		print(self.name..'   ap: '..tostring(ap))
		return 5
	end

	function ifrit:getSpeed(ap) return 1.27 end
	function ifrit:doAction(ap)
		print(self.name..'   ap: '..tostring(ap))
		return 2
	end

	print('begin')
	_timeManager:register(player, 3)
	_timeManager:register(dragon, 3)
	_timeManager:register(ifrit, 3)
end

local _accum = 0
local _count = 0
function st:update(dt)
	_accum = _accum + dt
	if _accum > 1 then
		_count = _count + 1
		_accum = _accum - 1
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
