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

local verify, assert, tostring = verify, assert, tostring

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
		self._attachMessages = {'ENTITY_CREATED', 'HAS_MOVED'}
		self._frames = {}
		self._curFrame = 'right'
	end
}

-- destructor
function GraphicsComponent:destroy()
	for k in pairs(self._frames) do self._frames[k] = nil end
	self._frames = nil
	self._curFrame = nil
	self._topFrame = nil
	self._tileset = nil
	self._fb = nil
	self._backfb = nil
	self._size = nil
	ViewComponent.destroy(self)
end

function GraphicsComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == data then data = property.default(prop) end

	if prop == property('TileSet') then
		verify('string', data)
		self._tileset = Image[data]
		assert(self._tileset ~= nil, 'Invalid TileSet: %s', tostring(data))
	elseif prop == property('TileCoords') then
		verify('table', data)
		local newData = {}
		for k,v in pairs(data) do
			assert(v.x and v.y, 'Invalid TileCoords: %s', tostring(v))
			verify('number', v.x, v.y)
			newData[k] = vector(v.x, v.y)
		end
		data = newData
	elseif prop == property('TileSize') then
		verify('number', data)
	elseif prop == property('Visibility') then
		verify('number', data)
	else
		error('GraphicsComponent does not support property: %s', tostring(prop))
	end

	ViewComponent._setProperty(self, prop, data)
end

function GraphicsComponent:receive(msg, ...)
	if     msg == message('ENTITY_CREATED') then self:_makeQuads(...)
	elseif msg == message('HAS_MOVED') then self:_updateFB(...)
	end
end

function GraphicsComponent:setMediator(mediator)
	ViewComponent.setMediator(self, mediator)
end

function GraphicsComponent:_newQuad(frame, coords)
	local tilesetW = self._tileset:getWidth()
	local tilesetH = self._tileset:getHeight()
	coords = coords:clone()
	coords.x, coords.y = (coords.x-1)*self._size, (coords.y-1)*self._size

	self._frames[frame] = newQuad(
		coords.x, coords.y,
		self._size, self._size,
		tilesetW, tilesetH)
end

function GraphicsComponent:_makeQuads()
	self._size = self._size or self:getProperty(property('TileSize'))
	local tileCoords = self:getProperty(property('TileCoords'))

	for frame,coords in pairs(tileCoords) do
		self._topFrame = self._topFrame or frame
		self:_newQuad(frame, coords)
	end

	if self._frames.right and not self._frames.left then
		self:_newQuad('left', tileCoords.right)
		self._frames.left:flip(true)
	end

	if self._frames.frontright and not self._frames.frontleft then
		self:_newQuad('frontleft', tileCoords.frontright)
		self._frames.frontleft:flip(true)
	end

	if self._frames.backright and not self._frames.backleft then
		self:_newQuad('backleft', tileCoords.backright)
		self._frames.backleft:flip(true)
	end
end

function GraphicsComponent:_updateFB(new, old)
	if self._mediator then
		local newFrame

		if old then
			local v = new - old
			local xstr, ystr

			if     v.x > 0 then xstr = 'right'
			elseif v.x < 0 then xstr = 'left'
			end

			if     v.y > 0 then ystr = 'front'
			elseif v.y < 0 then ystr = 'back'
			end

			if xstr and ystr and self._frames[ystr..xstr] then
				newFrame = ystr..xstr
			elseif ystr and self._frames[ystr] then
				newFrame = ystr
			elseif xstr and self._frames[xstr] then
				newFrame = xstr
			end
		end

		self._curFrame = newFrame or self._curFrame
		local frame = self._frames[self._curFrame] or self._frames[self._topFrame]

		self._drawX, self._drawY = (new.x-1)*self._size, (new.y-1)*self._size
		self._backfb = self._backfb or newFramebuffer(self._size, self._size)

		setRenderTarget(self._backfb)
		setColor(1,1,1)
		drawq(self._tileset, frame, 0, 0)
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
