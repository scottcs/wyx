
         --[[--
       PLAY STATE
          ----
      Play the game.
         --]]--

local st = Gamestate.new()

local bgms = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'}
local bgcur = math.random(1,#bgms)
local bgm

function st:init()
	bgm = love.audio.play(Music[bgms[bgcur]])
end

function st:draw()
	love.graphics.setFont(GameFont.small)
	love.graphics.setColor(0.6, 0.6, 0.6)
	love.graphics.print(love.timer.getFPS(), 8, 8)
	love.graphics.setColor(0.9, 0.8, 0.6)
	love.graphics.print('[n]ext [p]rev [s]top [g]o', 70, 42)
	love.graphics.setFont(GameFont.big)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(bgms[bgcur], 8, 40)
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
		s = function() love.audio.stop(bgm) end,
		g = function() love.audio.play(bgm) end,
		n = function()
			love.audio.stop(bgm)
			bgcur = #bgms == bgcur and 1 or bgcur + 1
			bgm = love.audio.play(Music[bgms[bgcur]])
		end,
		p = function()
			love.audio.stop(bgm)
			bgcur = 1 == bgcur and #bgms or bgcur - 1
			bgm = love.audio.play(Music[bgms[bgcur]])
		end,
		d = function() love.audio.play(Sound.pdeath) end,
		default = function() print(key) end,
	}
end

return st
