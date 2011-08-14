local Class = require 'lib.hump.class'
local ViewComponent = getClass 'pud.component.ViewComponent'
local property = require 'pud.component.property'
local message = require 'pud.component.message'
local vector = require 'lib.hump.vector'

local newFramebuffer = love.graphics.newFramebuffer
local newQuad = love.graphics.newQuad
local setRenderTarget = love.graphics.setRenderTarget
local drawq = love.graphics.drawq
local draw = love.graphics.draw
local setColor = love.graphics.setColor
local nearestPO2 = nearestPO2

-- GraphicsComponent
--
local GraphicsComponent = Class{name='GraphicsComponent',
	inherits=ViewComponent,
	function(self, properties)
		ViewComponent._addRequiredProperties(self, {
			'TileSet',
			'TileSize',
			'TileCoords',
			'Visibility',
		})
		ViewComponent.construct(self, properties)
		self._attachMessages = {'HAS_MOVED', 'DRAW'}
	end
}

-- destructor
function GraphicsComponent:destroy()
	self._tileset = nil
	self._quad = nil
	self._fb = nil
	self._backfb = nil
	self._size = nil
	ViewComponent.destroy(self)
end

function GraphicsComponent:_setProperty(prop, data)
	prop = property(prop)
	data = data or property.default(prop)
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
	if msg == message('HAS_MOVED') then self:_updateFB(...) end
end

function GraphicsComponent:setMediator(mediator)
	ViewComponent.setMediator(self, mediator)
	self._size = self._mediator:query(property('TileSize'))
	self:_makeQuad()
end

function GraphicsComponent:_makeQuad()
	local pos = self._mediator:query(property('TileCoords'))
	verify('table', pos)
	pos.x, pos.y = (pos.x-1)*self._size, (pos.y-1)*self._size

	self._quad = newQuad(
		pos.x, pos.y, self._size, self._size,
		self._tileset:getWidth(), self._tileset:getHeight())
end

function GraphicsComponent:_updateFB(new, old)
	if self._mediator then
		if old then
			local v = new - old
			if (self._movingLeft and v.x > 0)
				or (not self._movingLeft and v.x < 0)
			then
				self._movingLeft = v.x < 0
				self._quad:flip(1)
			end
		end

		self._drawX, self._drawY = (new.x-1)*self._size, (new.y-1)*self._size

		self._backfb = self._backfb or newFramebuffer(self._size, self._size)

		setRenderTarget(self._backfb)
		setColor(1,1,1)
		drawq(self._tileset, self._quad, 0, 0)
		setRenderTarget()

		self._fb, self._backfb = self._backfb, self._fb
	end
end

function GraphicsComponent:draw()
	if self._fb then
		setColor(1,1,1)
		draw(self._fb, self._drawX, self._drawY)
	end
end


-- the class
return GraphicsComponent
