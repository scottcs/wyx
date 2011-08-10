local Class = require 'lib.hump.class'
local Rect = getClass('pud.kit.Rect')

local math_max = math.max

local AnimatedTile = Class{name='AnimatedTile',
	inherits=Rect,
	function(self, width, height)
		width = width or TILEW
		height = height or TILEH
		Rect.construct(self, 0, 0, width, height)
		self._constructed = true
		self._fb = {}
		self._numFrames = 0
		self._frame = 1
	end
}

-- destructor
function AnimatedTile:destroy()
	self:clearFrames()
	self._isDrawing = nil
	self._numFrames = nil
	self._drawX = nil
	self._drawY = nil
	self._frame = nil
	self._fb = nil
	self._constructed = nil
	if self._updateCB then
		for k in pairs(self._updateCB) do self._updateCB[k] = nil end
		self._updateCB = nil
	end
	Rect.destroy(self)
end

-- don't allow resizing
function AnimatedTile:setSize(...)
	if self._constructed then
		error('Cannot resize AnimatedTile. Please destroy and create a new one.')
	else
		Rect.setSize(self, ...)
	end
end
function AnimatedTile:setWidth(...)
	if self._constructed then
		error('Cannot resize AnimatedTile. Please destroy and create a new one.')
	else
		Rect.setWidth(self, ...)
	end
end
function AnimatedTile:setHeight(...)
	if self._constructed then
		error('Cannot resize AnimatedTile. Please destroy and create a new one.')
	else
		Rect.setHeight(self, ...)
	end
end

-- draw to the framebuffer
function AnimatedTile:_drawToFB(frame, tileset, quad, bgquad)
	if self._numFrames > 0 and self._fb[frame] and tileset then
		self._isDrawing = true
		love.graphics.setRenderTarget(self._fb[frame])
		love.graphics.setColor(1,1,1)
		if bgquad then love.graphics.drawq(tileset, bgquad, 0, 0) end
		love.graphics.drawq(tileset, quad, 0, 0)
		love.graphics.setRenderTarget()
		self._isDrawing = false
	end
end

function AnimatedTile:setPosition(x, y)
	Rect.setPosition(self, x, y)
	x, y = self:getPosition()
	self._drawX = (x-1)*self:getWidth()
	self._drawY = (y-1)*self:getHeight()
end

-- draw the framebuffer
function AnimatedTile:draw()
	if self._numFrames > 0 and self._isDrawing == false then
		love.graphics.draw(self._fb[self._frame], self._drawX, self._drawY)
	end
end

-- advance the current frame to the next frame
function AnimatedTile:advance()
	if self._frame >= self._numFrames then
		self._frame = 1
	else
		self._frame = self._frame + 1
	end
end

-- set the callback to be called when update() is called
function AnimatedTile:setUpdateCallback(callback, ...)
	assert(callback and type(callback) == 'function',
		'setUpdateCallback expects a function (was %s)', type(callback))

	self._updateCB = {callback=callback, args={...}}
end

function AnimatedTile:update()
	if self._updateCB then
		self._updateCB.callback(unpack(self._updateCB.args))
	end
end

-- set the next available frame to the given tileset and quad
function AnimatedTile:setNextFrame(tileset, quad, bgquad)
	self._numFrames = self._numFrames and self._numFrames + 1 or 1

	local size = nearestPO2(math_max(self:getWidth(), self:getHeight()))
	self._fb[self._numFrames] = love.graphics.newFramebuffer(size, size)
	self:_drawToFB(self._numFrames, tileset, quad, bgquad)
end

-- clear all frames
function AnimatedTile:clearFrames()
	self._frame = 1
	self._numFrames = 0
	for i in ipairs(self._fb) do self._fb[i] = nil end
end

-- the class
return AnimatedTile
