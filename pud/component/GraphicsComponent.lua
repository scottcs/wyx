local Class = require 'lib.hump.class'
local Component = require 'pud.component.Component'
local property = require 'pud.component.property'
local vector = require 'lib.hump.vector'


-- GraphicsComponent
--
local GraphicsComponent = Class{name='GraphicsComponent',
	inherits=Component,
	function(self, properties)
		Component.construct(self, properties)
		self._attachMessages = {'HAS_MOVED', 'DRAW'}
		self:_makeQuad()
		local size = nearestPO2(self._properties[property('TileSize')])
	end
}

-- destructor
function GraphicsComponent:destroy()
	self._tileset = nil
	self._quad = nil
	self._fb = nil
	self._backfb = nil
	Component.destroy(self)
end

function GraphicsComponent:_addProperty(prop, data)
	prop = property(prop)
	if prop == property('TileSet') then
		verify('string', data)
		self._tileset = Image[data]
		assert(self._tileset ~= nil, 'Invalid TileSet: %s', tostring(data))
	elseif prop == property('TileCoords') then
		verify('table', data)
		assert(data.x and data.y, 'Invalid TileCoords: %s', tostring(data))
		verify('number', data.x, data.y)
		data = vector(data.x, data.y)
	elseif prop == property('TileSize') then
		verify('number', data)
	elseif prop == property('Visibility') then
		verify('number', data)
	else
		error('GraphicsComponent does not support property: %s', tostring(prop))
	end

	self._properties[prop] = data
end

function GraphicsComponent:receive(msg, ...)
	if     msg == message('DRAW') then self:draw(...)
	elseif msg == message('HAS_MOVED') then self:_updateFB(...)
	end
end

function GraphicsComponent:_makeQuad()
	local size = self._properties[property('TileSize')]
	local pos = self._properties[property('TileCoords')]
	pos.x, pos.y = (pos.x-1)*size (pos.y-1)*size

	self._quad = love.graphics.newQuad(
		pos.x, pos.y, size, size,
		self._tileset:getWidth(), self._tileset:getHeight())
end

function GraphicsComponent:_updateFB(v)
	if (self._movingLeft and v.x > 0)
		or (not self._movingLeft and v.x < 0)
	then
		self._movingLeft = v.x < 0
		self._quad:flip(1)
	end

	local pos = self._entity:getPositionVector()
	local size = self._properties[property('TileSize')]
	self._drawX, self.drawY = (pos.x-1)*size, (pos.y-1)*size

	if not self._backfb then
		self._backfb = love.graphics.newFramebuffer(size, size)
	end

	love.graphics.setRenderTarget(self._backfb)
	--[[
	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle(0, 0, size, size)
	]]--
	love.graphics.setColor(1,1,1)
	love.graphics.drawq(self._quad)
	love.graphics.setRenderTarget()

	self._fb, self._backfb = self._backfb, self._fb
end

function GraphicsComponent:draw()
	if self._fb then
		love.graphics.setColor(1,1,1)
		love.graphics.draw(self._fb, self._drawX, self._drawY)
	end
end


-- the class
return GraphicsComponent
