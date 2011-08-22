
         --[[--
     SHUTDOWN STATE
          ----
Shutdown the game and exit.
         --]]--

local st = GameState.new()

function st:init()
end

function st:enter(prev)
	HeroDB:destroy()
	EnemyDB:destroy()
	ItemDB:destroy()

	love.event.push('q')
end

return st
