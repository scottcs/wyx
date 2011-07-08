
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = Gamestate.new()

function st:draw()
	love.graphics.setFont(GameFont.small)
	love.graphics.print(love.timer.getFPS(), 0, 0)
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
		s = function() love.audio.play(Sound.pdeath) end,
		default = function() print(key) end,
	}
end

return st
