
         --[[--
     SHUTDOWN STATE
          ----
 Destroy everything that
 was created in the Menu
 State, Shutdown and exit.
         --]]--

local st = RunState.new()
local mt = {__tostring = function() return 'RunState.shutdown' end}
setmetatable(st, mt)

function st:init() end

function st:enter(prevState)
	love.event.push('q')
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, scancode, isrepeat) end

return st
