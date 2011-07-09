
         --[[--
       INTRO STATE
          ----
   Display the splash
   screens with fading.
         --]]--

local st = GameState.new()

function st:init()
end

function st:enter(prev)
	GameState.switch(State.load)
end

function st:update(dt)
end

function st:draw()
end

function st:keypressed(key, unicode)
end

return st
