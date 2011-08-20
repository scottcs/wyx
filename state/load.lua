
         --[[--
       LOAD STATE
          ----
   Load game resources.
         --]]--

local st = GameState.new()

-- global entity databases
local HeroEntityDB = getClass 'pud.entity.HeroEntityDB'
local EnemyEntityDB = getClass 'pud.entity.EnemyEntityDB'
local ItemEntityDB = getClass 'pud.entity.ItemEntityDB'

local math_max = math.max
local colors = colors

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
		verysmall = love.graphics.newImageFont('font/lofi_verysmall.png',
			'0123456789!@#$%^&*()-=+[]{}:;\'"<>,.?/\\ ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
		console = love.graphics.newImageFont('font/grafx2.png',
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ..
			'abcdefghijklmnopqrstuvwxyz' ..
			'0123456789`~!@#$%^&*()_+-={}[]\\/|<>,.;:\'" '),
	}
end

function st:enter()
	self.fadeColor = colors.clone(colors.BLACK)
	self.nextState = State.play
	self.lines = self.lines or {
		{
			text = "Loading...",
			font = GameFont.big,
			color = colors.RED,
			x = WIDTH/2,
			y = HEIGHT/2,
		},
	}

	local numLines = #self.lines
	for i=1,numLines do
		local l = self.lines[i]
		l.drawX = l.x - l.font:getWidth(l.text)/2
		l.drawY = l.y - l.font:getHeight()
	end

	self._fadeIn = 0
end

function st:load()
	local start = love.timer.getTime()

	-- load normal fonts
	for _,size in ipairs{14, 15, 16, 18, 20, 24} do
		local f = Font[size]
	end

	-- load entities
	HeroDB = HeroEntityDB()
	EnemyDB = EnemyEntityDB()
	ItemDB = ItemEntityDB()

	HeroDB:load()
	EnemyDB:load()
	ItemDB:load()

	local loadTime = love.timer.getTime() - start
	self._fadeOut = loadTime
end

function st:update(dt)
	if self._fadeIn then
		self._fadeIn = self._fadeIn + dt
		if self._fadeIn > 0.3 then
			self._fadeIn = nil
			tween(0.3, self.fadeColor, colors.BLACK_A00, 'inSine',
				self.load, self)
		end
	end

	if self._fadeOut then
		self._fadeOut = self._fadeOut + dt
		if self._fadeOut > 1 then
			self._fadeOut = nil
			tween(0.3, self.fadeColor, colors.BLACK, 'outQuint',
				GameState.switch, self.nextState)
		end
	end
end

function st:draw()
	local numLines = #self.lines
	for i=1,numLines do
		local l = self.lines[i]
		love.graphics.setFont(l.font)
		love.graphics.setColor(l.color)
		love.graphics.print(l.text, l.drawX, l.drawY)
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
