local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'

local AnimatedTile = Class{name='AnimatedTile',
	inherits=Rect,
	function(self, width, height)
		width = width or 32
		height = height or 32
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
	self._frame = nil
	self._fb = nil
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
function AnimatedTile:_drawToFB(frame, tileset, quad)
	if self._numFrames > 0 and self._fb[frame] and tileset and quad then
		self._isDrawing = true
		love.graphics.setRenderTarget(self._fb[frame])
		love.graphics.setColor(1,1,1)
		love.graphics.drawq(tileset, quad, 0, 0)
		love.graphics.setRenderTarget()
		self._isDrawing = false
	end
end

-- draw the framebuffer
function AnimatedTile:draw(x, y)
	if self._numFrames > 0 and self._isDrawing == false then
		love.graphics.draw(self._fb[self._frame], x, y)
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

-- set the next available frame to the given tileset and quad
function AnimatedTile:setNextFrame(tileset, quad)
	self._numFrames = self._numFrames and self._numFrames + 1 or 1

	local w, h = self:getSize()
	self._fb[self._numFrames] = love.graphics.newFramebuffer(w, h)
	self:_drawToFB(self._numFrames, tileset, quad)
end

-- clear all frames
function AnimatedTile:clearFrames()
	self._frame = 1
	self._numFrames = 0
	for i in ipairs(self._fb) do self._fb[i] = nil end
end

-- the class
return AnimatedTile
