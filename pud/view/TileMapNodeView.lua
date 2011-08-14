local Class = require 'lib.hump.class'
local MapNodeView = getClass 'pud.view.MapNodeView'
local math_max = math.max

local newFramebuffer = love.graphics.newFramebuffer
local newQuad = love.graphics.newQuad
local setRenderTarget = love.graphics.setRenderTarget
local drawq = love.graphics.drawq
local draw = love.graphics.draw
local setColor = love.graphics.setColor
local nearestPO2 = nearestPO2

-- TileMapNodeView
--
local TileMapNodeView = Class{name='TileMapNodeView',
	inherits=MapNodeView,
	function(self, node, width, height)
		verifyClass('pud.map.MapNode', node)
		width = width or TILEW
		height = height or TILEH
		MapNodeView.construct(self, 0, 0, width, height)
		self._node = node
		self:_resetKey()
	end
}

-- destructor
function TileMapNodeView:destroy()
	self._fb = nil
	self._drawX = nil
	self._drawY = nil
	self._isDrawing = nil
	self._node = nil
	MapNodeView.destroy(self)
end

local _fbcache = setmetatable({}, {__mode = 'kv'})
function TileMapNodeView:_getfb(tileset, quad, bgquad)
	local fb = _fbcache[self._key]

	if nil == fb then
		local size = nearestPO2(math_max(self:getWidth(), self:getHeight()))
		fb = newFramebuffer(size, size)

		setRenderTarget(fb)

		setColor(1,1,1)
		if bgquad then drawq(tileset, bgquad, 0, 0) end
		drawq(tileset, quad, 0, 0)

		setRenderTarget()

		_fbcache[self._key] = fb
	end

	return fb
end

function TileMapNodeView:_resetKey()
	self._key = self._node:getMapType():getKey()
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
		self._isDrawing = true
		self._fb = self:_getfb(tileset, quad, bgquad)
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
		draw(self._fb, self._drawX, self._drawY)
	end
end

-- class function to reset the framebuffer cache
function TileMapNodeView.resetCache()
	for k in pairs(_fbcache) do _fbcache[k] = nil end
end


-- the class
return TileMapNodeView
