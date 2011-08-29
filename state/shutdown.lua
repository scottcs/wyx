
         --[[--
     SHUTDOWN STATE
          ----
 Destroy everything that
 was created in the Menu
 State, Shutdown and exit.
         --]]--

local st = GameState.new()

function st:init() end

function st:enter(prevState)
	print('shutdown')
	love.event.push('q')
end

function st:leave() end

function st:destroy() end

function st:update(dt) end

function st:draw() end

function st:keypressed(key, unicode) end

return st
