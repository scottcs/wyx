local Class = require 'lib.hump.class'
local math_max = math.max
local math_floor = math.floor

local getMicroTime = love.timer.getMicroTime
local newFramebuffer = love.graphics.newFramebuffer
local setFont = love.graphics.setFont
local gprint = love.graphics.print
local rectangle = love.graphics.rectangle
local setRenderTarget = love.graphics.setRenderTarget
local draw = love.graphics.draw
local setColor = love.graphics.setColor
local colors = colors
local nearestPO2 = nearestPO2

local MARGIN = 8

-- MessageHUD
--
local MessageHUD = Class{name='MessageHUD',
	function(self, message, seconds)
		self._font = GameFont.big
		self._fontH = GameFont.big:getHeight()
		local w = self._font:getWidth(message) + MARGIN*2
		local h = self._fontH + MARGIN*2
		self._w, self._h = w, h
		local size = nearestPO2(math_max(w, h))
		self._fb = newFramebuffer(size, size)
		local imageData = self._fb:getImageData()
		local fbW = imageData:getWidth()
		local fbH = imageData:getHeight()
		self._fbX = math_floor(WIDTH/2 - w/2)
		self._fbY = math_floor(HEIGHT - h*3)
		self._message = message
		self._finish = getMicroTime() + seconds + 0.3
		self._fadeColor = colors.clone(colors.WHITE_A00)
		self:_drawFB()
		self._inID = tween(0.3, self._fadeColor, colors.WHITE, 'inSine')
	end
}

-- destructor
function MessageHUD:destroy()
	tween.stop(self._inID)
	tween.stop(self._outID)
	self._font = nil
	self._fontH = nil
	self._fb = nil
	self._fbX = nil
	self._fbY = nil
	self._x = nil
	self._y = nil
	self._w = nil
	self._h = nil
	self._message = nil
	self._faseColor = nil
	self._finish = nil
	self._inID = nil
	self._outID = nil
end

function MessageHUD:update(dt)
	if not self._finish then return end
	local time = getMicroTime()
	if time > self._finish then
		self._finish = nil
		self._outID = tween(0.3, self._fadeColor, colors.WHITE_A00, 'outQuint')
	end
end

function MessageHUD:_drawFB()
	self._isDrawing = true
	setRenderTarget(self._fb)

	setFont(self._font)

	setColor(colors.BLACK_A70)
	rectangle('fill', 0, 0, self._w, self._h)

	setColor(colors.WHITE)
	gprint(self._message, MARGIN, MARGIN)

	setRenderTarget()
	self._isDrawing = false
end

function MessageHUD:draw()
	if self._isDrawing == false then
		setColor(self._fadeColor)
		draw(self._fb, self._fbX, self._fbY)
	end
end


-- the class
return MessageHUD
