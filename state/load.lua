
         --[[--
       LOAD STATE
          ----
   Load game resources.
         --]]--

local st = Gamestate.new()

local _loading = 'Loading...'
local x, y

function st:init()
	-- load game fonts
	GameFont = {
		small = love.graphics.newImageFont('font/lofi_small.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		big = love.graphics.newImageFont('font/lofi_big.png',
			'0123456789!@#$%()-=+,.":;/\\?\' ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
	}

	x = WIDTH/2 - GameFont.big:getWidth(_loading)/2
	y = HEIGHT/2 - GameFont.big:getHeight()/2

	Timer.add(0.5, self.load)
end

function st:load()
	-- load normal fonts
	for _,size in ipairs{14, 15, 16, 18, 20, 24} do
		local f = Font[size]
	end

	-- load music
	for i=97,96+NUM_MUSIC do local m = Music[string.char(i)] end

	Gamestate.switch(State.demo)
end

function st:draw()
	love.graphics.setFont(GameFont.big)
	love.graphics.print(_loading, x, y)
end

function st:keypressed(key, unicode)
	case(key) {
		escape = function() love.event.push('q') end,
	}
end

return st
