
         --[[--
      NEWGAME STATE
          ----
   Construct everything
  needed for a new game.
         --]]--

local st = GameState.new()


function st:init() end

function st:enter(prevState)
	print('newgame')

	-- switch to construct state
	GameState.switch(State.construct, level)
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw()
	if Console then Console:draw() end
end

function st:keypressed(key, unicode) end

return st
