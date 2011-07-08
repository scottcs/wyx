
         --[[--
       INTRO STATE
          ----
   Display the splash
   screens with fading.
         --]]--

local st = Gamestate.new()

function st:init()
	print('init')
end

function st:enter(prev)
	print('enter '..tostring(prev))
end

function st:update(dt)
end

function st:draw()
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
	}
end

return st
