local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'

local AnimatedTile = Class{name='AnimatedTile',
	inherits=Rect,
	function(self, width, height)
		width = width or 32
		height = height or 32
		Rect.construct(self, 0, 0, width, height)
		self._tilesets = {}
		self._quads = {}
		self:_resizeFrameBuffer()
	end
}

-- destructor
function AnimatedTile:destroy()
	self._fb = nil
	self._isDrawing = nil
	self:clearFrames()
	Rect.destroy(self)
end

-- overload Rect size functions to also resize framebuffer
function AnimatedTile:setWidth(width)
	Rect.setWidth(self, width)
	self:_resizeFramebuffer()
end
function AnimatedTile:setHeight(height)
	Rect.setHeight(self, height)
	self:_resizeFramebuffer()
end
function AnimatedTile:setSize(width, height)
	Rect.setSize(self, width, height)
	self:_resizeFramebuffer()
end

-- resize the framebuffer after size has changed
function AnimatedTile:_resizeFramebuffer()
	local w, h = self:getSize()
	self._fb = love.graphics.newFramebuffer(w, h)
	self:_drawToFB()
end

-- draw to the framebuffer
function AnimatedTile:_drawToFB()
	if self._fb and self._frame then
		self._isDrawing = true
		local tileset = self._tilesets[self._frame]
		local quad = self._quads[self._frame]
		love.graphics.setRenderTarget(self._fb)
		love.graphics.drawq(tileset, quad, 0, 0)
		love.graphics.setRenderTarget()
		self._isDrawing = false
	end
end

-- draw the framebuffer
function AnimatedTile:draw()
	if self._fb and self._isDrawing == false then
		love.graphics.draw(self._fb, self:getX(), self:getY())
	end
end

-- advance the current frame to the next frame
function AnimatedTile:_advanceFrame()
	if not self._frame then return end

	if self._frame >= self._numFrames then
		self._frame = 1
	else
		self._frame = self._frame + 1
	end
end

-- set the next available frame to the given tileset and quad
function AnimatedTile:setNextFrame(tileset, quad)
	verify('table', tileset, quad)

	self._frame = self._frame or 1
	self._numFrames = self._numFrames and self._numFrames + 1 or 1

	self._tilesets[self._numFrames] = tileset
	self._quads[self._numFrames] = quad
end

-- clear all frames
function AnimatedTile:clearFrames()
	self._frame = nil
	self._numFrames = nil
	for i in ipairs(self._tilesets) do self._tilesets[i] = nil end
	for i in ipairs(self._quads) do self._quads[i] = nil end
	self._tilesets = nil
	self._quads = nil
end

-- advance to the next frame and redraw
function AnimatedTile:update()
	self:_advanceFrame()
	self:_drawToFB()
end

-- the class
return AnimatedTile
