local Class = require 'lib.hump.class'
local MapNode = require 'pud.map.MapNode'
local MapNodeView = require 'pud.view.MapNodeView'

-- TileMapNodeView
--
local TileMapNodeView = Class{name='TileMapNodeView',
	inherits=MapNodeView,
	function(self, node, width, height)
		width = width or 32
		height = height or 32
		MapNodeView.construct(self, 0, 0, width, height)
	end
}

-- destructor
function TileMapNodeView:destroy()
	MapNodeView.destroy(self)
end

-- set the tile for this node
function TileMapNodeView:setTile(tileset, quad, bgquad)
	assert(tileset, 'tileset not specified')
	assert(quad, 'quad not specified')

	local w, h = self:getSize()
	self._fb = love.graphics.newFramebuffer(w, h)
	self._isDrawing = true
	love.graphics.setRenderTarget(self._fb)
	love.graphics.setColor(1,1,1)
	if bgquad then love.graphics.drawq(tileset, bgquad, 0, 0) end
	love.graphics.drawq(tileset, quad, 0, 0)
	love.graphics.setRenderTarget()
	self._isDrawing = false
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
