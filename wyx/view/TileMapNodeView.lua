local Class = require 'lib.hump.class'
local MapNodeView = getClass 'wyx.view.MapNodeView'
local math_max = math.max

local newQuad = love.graphics.newQuad
local draw = love.graphics.draw
local setColor = love.graphics.setColor
local colors = colors

local verifyClass, setmetatable, pairs = verifyClass, setmetatable, pairs

-- TileMapNodeView
--
local TileMapNodeView = Class{name='TileMapNodeView',
	inherits=MapNodeView,
	function(self, node, width, height)
		verifyClass('wyx.map.MapNode', node)
		width = width or TILEW
		height = height or TILEH
		MapNodeView.construct(self, 0, 0, width, height)
		self._node = node
		self:_resetKey()
	end
}

-- destructor
function TileMapNodeView:destroy()
	self._set = nil
	self._quad = nil
	self._bgquad = nil
	self._drawX = nil
	self._drawY = nil
	self._isDrawing = nil
	self._node = nil
	MapNodeView.destroy(self)
end

function TileMapNodeView:_resetKey()
	local mt = self._node:getMapType()
	self._key = mt:getKey()
end

-- update the tile for this node if it has changed
function TileMapNodeView:update()
	self:_resetKey()
end

function TileMapNodeView:getKey() return self._key end
function TileMapNodeView:getNode() return self._node end

-- set the tile for this node
function TileMapNodeView:setTile(tileset, quad, bgquad)
	if tileset and quad then
		self._set = tileset
		self._quad = quad
		self._bgquad = bgquad
	end
end

function TileMapNodeView:setPosition(x, y)
	MapNodeView.setPosition(self, x, y)
	x, y = self:getPosition()
	self._drawX = (x-1)*self:getWidth()
	self._drawY = (y-1)*self:getHeight()
end

-- draw the tile
function TileMapNodeView:draw()
	if self._set and self._quad then
		if self._bgquad then
			draw(self._set, self._bgquad, self._drawX, self._drawY)
		end
		draw(self._set, self._quad, self._drawX, self._drawY)
	end
end


-- the class
return TileMapNodeView
