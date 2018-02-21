
         --[[--
       INTRO STATE
          ----
   Display the splash
   screens with fading.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.intro' end}
setmetatable(st, mt)

function st:init() end

function st:enter(prevState)
	RunState.switch(State.initialize, 'menu')
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, scancode, isrepeat) end

return st
