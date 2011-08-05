local Class = require 'lib.hump.class'
local math_max = math.max
local math_floor = math.floor

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
		self._fb = love.graphics.newFramebuffer(size, size)
		local imageData = self._fb:getImageData()
		local fbW = imageData:getWidth()
		local fbH = imageData:getHeight()
		self._fbX = math_floor(WIDTH/2 - w/2)
		self._fbY = math_floor(HEIGHT - h*1.5)
		self._message = message
		self._finish = love.timer.getMicroTime() + seconds + 0.3
		self._fadeColor = {1,1,1,0}
		self:_drawFB()
		self._inID = tween(0.3, self._fadeColor, {1,1,1,1}, 'inSine')
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
	local time = love.timer.getMicroTime()
	if time > self._finish then
		self._finish = nil
		self._outID = tween(0.3, self._fadeColor, {1,1,1,0}, 'outQuint')
	end
end

function MessageHUD:_drawFB()
	self._isDrawing = true
	love.graphics.setRenderTarget(self._fb)

	love.graphics.setFont(self._font)

	love.graphics.setColor(0,0,0,0.7)
	love.graphics.rectangle('fill', 0, 0, self._w, self._h)

	love.graphics.setColor(1,1,1)
	love.graphics.print(self._message, MARGIN, MARGIN)

	love.graphics.setRenderTarget()
	self._isDrawing = false
end

function MessageHUD:draw()
	if self._isDrawing == false then
		love.graphics.setColor(self._fadeColor)
		love.graphics.draw(self._fb, self._fbX, self._fbY)
	end
end


-- the class
return MessageHUD
