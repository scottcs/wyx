
         --[[--
       INTRO STATE
          ----
   Display the splash
   screens with fading.
         --]]--

local st = RunState.new()

function st:init() end

function st:enter(prevState)
	--RunState.switch(State.menu, 'initialize', 'construct')
	RunState.switch(State.uitest)
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, unicode) end

return st
