
         --[[--
     MAIN MENU STATE
          ----
  Display the main menu.
         --]]--

local st = RunState.new()

function st:init() end

function st:enter(prevState, nextState)
	if nil ~= nextState then
		RunState.switch(nextState, State.construct)
		--RunState.switch(nextState, State.loadgame)
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