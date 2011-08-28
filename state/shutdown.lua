
         --[[--
     SHUTDOWN STATE
          ----
 Destroy everything that
 was created in the Menu
 State, Shutdown and exit.
         --]]--

local st = GameState.new()

function st:enter(prevState)
	print('shutdown')
	love.event.push('q')
end

return st
