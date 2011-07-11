
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = GameState.new()

local TimeManager = require 'pud.timemanager'
local _timeManager

function st:init()
	_timeManager = TimeManager()
end

function st:enter()
	--GameState.switch(State.demo)
	local target = {name='Bless', rate=1, cost = 1}
	local target2 = {name='Curse', rate=1, cost = 1}
	local function rate(t)
		return t.rate and t.rate or 1
	end
	local function cost(t)
		print(tostring(t.name))
		_timeManager:releaseTimedEntity()
		return t.cost and t.cost or 1
	end

	print('begin')
	_timeManager:registerTimedEntity(400, target, rate, cost)
	_timeManager:registerTimedEntity(200, target2, rate, cost)
end

local _accum = 0
function st:update(dt)
	_accum = _accum + dt
	if _accum >= 1 then
		_accum = 0
		print('tick')
	end
	_timeManager:progressTime(dt)
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
