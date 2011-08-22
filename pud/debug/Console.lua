local Class = require 'lib.hump.class'
local Deque = getClass 'pud.kit.Deque'

local format = string.format
local gprint = love.graphics.print
local draw = love.graphics.draw
local pushRenderTarget, popRenderTarget = pushRenderTarget, popRenderTarget
local rectangle = love.graphics.rectangle
local setColor = love.graphics.setColor
local setFont = love.graphics.setFont
local colors = colors

local MARGIN = 8
local BUFFER_SIZE = 1000
local FONT = GameFont.console
local FONT_H = FONT:getHeight()
local DRAWLINES = math.floor(HEIGHT/FONT_H)-2
local START_Y = math.floor(HEIGHT - (MARGIN + FONT_H*2))

-- Console
--
local Console = Class{name='Console',
	function(self)
		self._buffer = Deque()
		self._firstLine = 0
		self._drawColor = colors.WHITE

		local size = nearestPO2(math.max(WIDTH, HEIGHT))
		self._ffb = love.graphics.newFramebuffer(size, size)
		self._bfb = love.graphics.newFramebuffer(size, size)

		self:_drawFB()
	end
}

-- destructor
function Console:destroy()
	self._buffer:destroy()
	self._buffer = nil
	self._drawColor = nil
	self._show = nil
	self._firstLine = nil
	self._ffb = nil
	self._bfb = nil
end

function Console:_setDrawColor()
	self._drawColor = self._firstLine == 0 and colors.WHITE or colors.ORANGE
end

function Console:clear()
	self._buffer:clear()
	self._firstLine = 0
	self:_setDrawColor()
	self:_drawFB()
end

function Console:pageup()
	self._firstLine = self._firstLine + DRAWLINES
	local max = 1+(self._buffer:size() - DRAWLINES)
	if self._firstLine > max then self._firstLine = max end
	self:_setDrawColor()
	self:_drawFB()
end

function Console:pagedown()
	self._firstLine = self._firstLine - DRAWLINES
	if self._firstLine < 0 then self._firstLine = 0 end
	self:_setDrawColor()
	self:_drawFB()
end

function Console:bottom()
	self._firstLine = 0
	self:_setDrawColor()
	self:_drawFB()
end

function Console:top()
	self._firstLine = 1+(self._buffer:size() - DRAWLINES)
	self:_setDrawColor()
	self:_drawFB()
end

function Console:hide() self._show = false end
function Console:show() self._show = true end
function Console:toggle() self._show = not self._show end
function Console:isVisible() return self._show == true end

function Console:print(msg, ...)
	if select('#', ...) > 0 then msg = format(msg, ...) end
	self._buffer:push_front(msg)
	if self._buffer:size() > BUFFER_SIZE then self._buffer:pop_back() end
	if self._firstLine == 0 then self:_drawFB() end
end

function Console:_drawFB()
	pushRenderTarget(self._bfb)

	setColor(colors.BLACK_A70)
	rectangle('fill', 0, 0, WIDTH, HEIGHT)

	local count = DRAWLINES
	local skip = 1
	local drawX, drawY = MARGIN, START_Y

	setFont(FONT)
	setColor(colors.GREY90)

	for line in self._buffer:iterate() do
		if skip >= self._firstLine then
			gprint(line, drawX, drawY)

			drawY = drawY - FONT_H
			count = count - 1

			if count <= 0 then break end
		end
		skip = skip + 1
	end

	popRenderTarget()

	self._ffb, self._bfb = self._bfb, self._ffb
end

function Console:draw()
	if self._show and self._ffb then
		setColor(self._drawColor)
		draw(self._ffb, 0, 0)
	end
end


-- the class
return Console
