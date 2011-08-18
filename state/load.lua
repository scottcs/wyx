
         --[[--
       LOAD STATE
          ----
   Load game resources.
         --]]--

local st = GameState.new()

local math_max = math.max

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
		debug = love.graphics.newImageFont('font/lofi_verysmall.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
	}

end

function st:enter()
	self.fadeColor = {0,0,0,1}
	self.nextState = State.play
	self.lines = self.lines or {
		{
			text = "Loading...",
			font = GameFont.big,
			color = {1, 0, 0},
			x = WIDTH/2,
			y = HEIGHT/2,
		},
	}

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
	local loadTime = math_max(1, stop - start)
	cron.after(.1 + loadTime, self.fadeout, self)
end

function st:fadeout()
	tween(0.3, self.fadeColor, {0,0,0,1}, 'outQuint',
		GameState.switch, self.nextState)
end

function st:draw()
	for _,l in ipairs(self.lines) do
		love.graphics.setFont(l.font)
		love.graphics.setColor(l.color)
		love.graphics.print(l.text,
			l.x - l.font:getWidth(l.text)/2, l.y-l.font:getHeight())
	end

	-- fader
	if self.fadeColor[4] ~= 0 then
		local r,g,b,a = love.graphics.getColor()
		love.graphics.setColor(self.fadeColor)
		love.graphics.rectangle('fill', 0, 0, WIDTH, HEIGHT)
		love.graphics.setColor(r,g,b,a)
	end
end


return st
