
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = Gamestate.new()

function st:init()
end

function st:draw()
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
	}
end

return st
