
         --[[--
       INTRO STATE
          ----
   Display the splash
   screens with fading.
         --]]--

local st = RunState.new()

function st:init() end

function st:enter(prevState)
	print('intro')
	RunState.switch(State.menu)
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, unicode) end

return st
