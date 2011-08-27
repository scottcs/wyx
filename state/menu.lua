
         --[[--
     MAIN MENU STATE
          ----
  Display the main menu.
         --]]--

local st = GameState.new()

function st:init()
end

function st:enter(prev)
	if prev == State.intro then
		GameState.switch(State.initialize)
	else
		GameState.switch(State.shutdown)
	end
end

function st:update(dt)
end

function st:draw()
end

function st:keypressed(key, unicode)
end

return st
