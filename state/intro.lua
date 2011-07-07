local intro = Gamestate.new()

function intro:init()
	print('init')
end

function intro:enter(prev)
	print('enter '..tostring(prev))
end

function intro:update(dt)
end

function intro:draw()
end

function intro:keyreleased(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
		s = function() love.audio.play(Sound.hit) end,
		default = function() print(key) end,
	}
end

return intro
