local Class = require 'lib.hump.class'
local MapNode = require 'pud.map.MapNode'
local MapNodeView = require 'pud.view.MapNodeView'

-- TileMapNodeView
--
local TileMapNodeView = Class{name='TileMapNodeView',
	inherits=MapNodeView,
	function(self, width, height)
		width = width or 32
		height = height or 32
		MapNodeView.construct(self, 0, 0, width, height)
	end
}

-- destructor
function TileMapNodeView:destroy()
	self._fb = nil
	self._drawX = nil
	self._drawY = nil
	self._isDrawing = nil
	self._fbcache = nil
	MapNodeView.destroy(self)
end

function TileMapNodeView:_getfb(key, tileset, quad, bgquad)
	self._fbcache = self._fbcache or setmetatable({}, {__mode = 'kv'})
	local fb = self._fbcache[key]

	if nil == fb then
		local w, h = self:getSize()
		fb = love.graphics.newFramebuffer(w, h)

		love.graphics.setRenderTarget(fb)

		love.graphics.setColor(1,1,1)
		if bgquad then love.graphics.drawq(tileset, bgquad, 0, 0) end
		love.graphics.drawq(tileset, quad, 0, 0)

		love.graphics.setRenderTarget()

		self._fbcache[key] = fb
	end

	return fb
end

-- set the tile for this node
function TileMapNodeView:setTile(key, tileset, quad, bgquad)
	if key and tileset and quad then
		self._isDrawing = true
		self._fb = self:_getfb(key, tileset, quad, bgquad)
		self._isDrawing = false
	end
end

function TileMapNodeView:setPosition(x, y)
	MapNodeView.setPosition(self, x, y)
	x, y = self:getPosition()
	self._drawX = (x-1)*self:getWidth()
	self._drawY = (y-1)*self:getHeight()
end

-- draw the frame buffer
function TileMapNodeView:draw()
	if self._fb and self._isDrawing == false then
		love.graphics.draw(self._fb, self._drawX, self._drawY)
	end
end


-- the class
return TileMapNodeView
