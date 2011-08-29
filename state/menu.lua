
         --[[--
     MAIN MENU STATE
          ----
  Display the main menu.
         --]]--

local st = RunState.new()

function st:init() end

function st:enter(prevState)
	print('menu')
	if prevState == State.intro then
		RunState.switch(State.initialize, State.newgame)
	else
		RunState.switch(State.shutdown)
	end
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, unicode) end

return st
