
         --[[--
       LOAD STATE
          ----
   Load game resources.
         --]]--

local st = GameState.new()

local _loading = 'Loading...'
local _x, _y

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

	_x = WIDTH/2 - GameFont.big:getWidth(_loading)/2
	_y = HEIGHT/2 - GameFont.big:getHeight()/2
end

function st:enter()
	self.fadeColor = {0,0,0,1}
	tween(0.3, self.fadeColor, {0,0,0,0}, 'inSine',
		self.load, self)
end

function st:load()
	local start = love.timer.getMicroTime()

	-- load normal fonts
	for _,size in ipairs{14, 15, 16, 18, 20, 24} do
		local f = Font[size]
	end

	-- fade out to next state
	-- load time is added to cron time because next update dt will be
	-- close to stop - start
	local stop = love.timer.getMicroTime()
	cron.after(0.1 + (stop - start), self.fadeout, self)
end

function st:fadeout()
	tween(0.3, self.fadeColor, {0,0,0,1}, 'outQuint',
		GameState.switch, self.nextState)
end

function st:draw()
	love.graphics.setFont(GameFont.big)
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.print(_loading, _x, _y)

	-- fader
	if self.fadeColor[4] ~= 0 then
		local r,g,b,a = love.graphics.getColor()
		love.graphics.setColor(self.fadeColor)
		love.graphics.rectangle('fill', 0, 0, WIDTH, HEIGHT)
		love.graphics.setColor(r,g,b,a)
	end
end

return st
