local Class = require 'lib.hump.class'
local Rect = getClass 'wyx.kit.Rect'

local draw = love.graphics.draw
local colors = colors

local error, assert, pairs, type, unpack = error, assert, pairs, type, unpack

local math_max = math.max

local AnimatedTile = Class{name='AnimatedTile',
	inherits=Rect,
	function(self, width, height)
		width = width or TILEW
		height = height or TILEH
		Rect.construct(self, 0, 0, width, height)
		self._constructed = true
		self._frames = {}
		self._numFrames = 0
		self._curFrame = 1
	end
}

-- destructor
function AnimatedTile:destroy()
	self:clearFrames()
	self._frames = nil
	self._numFrames = nil
	self._drawX = nil
	self._drawY = nil
	self._curFrame = nil
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

function AnimatedTile:setPosition(x, y)
	Rect.setPosition(self, x, y)
	x, y = self:getPosition()
	self._drawX = (x-1)*self:getWidth()
	self._drawY = (y-1)*self:getHeight()
end

-- draw the current frame
function AnimatedTile:draw()
	local f = self._frames[self._curFrame]
	if self._numFrames > 0 and f and f.tileset then
		if f.bgquad then draw(f.tileset, f.bgquad, self._drawX, self._drawY) end
		draw(f.tileset, f.quad, self._drawX, self._drawY)
	end
end

-- advance the current frame to the next frame
function AnimatedTile:advance()
	if self._curFrame >= self._numFrames then
		self._curFrame = 1
	else
		self._curFrame = self._curFrame + 1
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
	self._frames[self._numFrames] = {
		tileset = tileset,
		quad = quad,
		bgquad = bgquad,
	}
end

-- clear all frames
function AnimatedTile:clearFrames()
	self._curFrame = 1
	for i=1,self._numFrames do
		for j in pairs(self._frames[i]) do self._frames[i][j] = nil end
		self._frames[i] = nil
	end
	self._numFrames = 0
end

-- the class
return AnimatedTile
