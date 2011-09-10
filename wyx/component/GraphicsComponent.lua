local Class = require 'lib.hump.class'
local ViewComponent = getClass 'wyx.component.ViewComponent'
local LightingStatusRequest = getClass 'wyx.event.LightingStatusRequest'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

local newFramebuffer = love.graphics.newFramebuffer
local newQuad = love.graphics.newQuad
local setRenderTarget = love.graphics.setRenderTarget
local drawq = love.graphics.drawq
local draw = love.graphics.draw
local setColor = love.graphics.setColor
local nearestPO2 = nearestPO2
local colors = colors

local verify, assert, tostring = verify, assert, tostring
local vec2_equal = vec2.equal

local COLOR_DIM = colors.GREY40
local COLOR_NORMAL = colors.WHITE

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
			'VisibilityBonus',
		})
		ViewComponent.construct(self, properties)
		self:_addMessages(
			'ENTITY_CREATED',
			'HAS_MOVED',
			'SCREEN_STATUS',
			'CONTAINER_INSERTED',
			'CONTAINER_REMOVED',
			'TIME_POSTTICK')
		self._frames = {}
		self._curFrame = 'right'
		self._lit = 'black'
		self._doDraw = true
		self._color = COLOR_NORMAL
	end
}

-- destructor
function GraphicsComponent:destroy()
	for k in pairs(self._frames) do self._frames[k] = nil end
	self._frames = nil
	self._curFrame = nil
	self._topFrame = nil
	self._tileset = nil
	self._ffb = nil
	self._bfb = nil
	self._size = nil
	ViewComponent.destroy(self)
end

function GraphicsComponent:_setProperty(prop, data)
	prop = property(prop)
	if nil == prop then return end
	if nil == data then data = property.default(prop) end

	if prop == property('TileSet') then
		verify('string', data)
		self._tileset = Image[data]
		assert(self._tileset ~= nil, 'Invalid TileSet: %s', tostring(data))
	elseif prop == property('TileCoords') then
		verify('table', data)
		for k,v in pairs(data) do
			verify('string', k)
			assert(#v == 2, 'Invalid TileCoords: %s', tostring(v))
			verify('number', v[1], v[2])
		end
	elseif prop == property('TileSize') then
		verify('number', data)
	elseif prop == property('Visibility')
		or prop == property('VisibilityBonus')
	then
		verifyAny(data, 'number', 'expression')
	else
		error('GraphicsComponent does not support property: %s', tostring(prop))
	end

	ViewComponent._setProperty(self, prop, data)
end

function GraphicsComponent:_setScreenStatus(status)
	self._lit = status
	if status == 'dim' then
		self._color = COLOR_DIM
	else
		self._color = COLOR_NORMAL
	end
	self:_updateFB()
end

function GraphicsComponent:receive(sender, msg, ...)
	if     msg == message('ENTITY_CREATED')
		and sender == self._mediator
	then self:_makeQuads(...)

	elseif msg == message('SCREEN_STATUS')
		and sender == self._mediator
	then self:_setScreenStatus(...)

	elseif msg == message('HAS_MOVED') then
		self:_updateFB(...)

	elseif msg == message('CONTAINER_INSERTED')
		and sender == self._mediator
	then self._doDraw = false

	elseif msg == message('CONTAINER_REMOVED')
		and sender == self._mediator
	then self._doDraw = true
	end
end

function GraphicsComponent:getProperty(p, intermediate, ...)
	local prop = self._properties[p]

	if     p == property('TileSet') then
		return prop
	elseif p == property('TileCoords') then
		return prop
	else
		return ViewComponent.getProperty(self, p, intermediate, ...)
	end
end

function GraphicsComponent:setMediator(mediator)
	ViewComponent.setMediator(self, mediator)
end

function GraphicsComponent:_newQuad(frame, coords)
	local tilesetW = self._tileset:getWidth()
	local tilesetH = self._tileset:getHeight()
	local x, y = (coords[1]-1)*self._size, (coords[2]-1)*self._size

	self._frames[frame] = newQuad(
		x, y,
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
	elseif self._frames.left and not self._frames.right then
		self:_newQuad('right', tileCoords.left)
		self._frames.right:flip(true)
	end

	if self._frames.frontright and not self._frames.frontleft then
		self:_newQuad('frontleft', tileCoords.frontright)
		self._frames.frontleft:flip(true)
	elseif self._frames.frontleft and not self._frames.frontright then
		self:_newQuad('frontright', tileCoords.frontleft)
		self._frames.frontright:flip(true)
	end

	if self._frames.backright and not self._frames.backleft then
		self:_newQuad('backleft', tileCoords.backright)
		self._frames.backleft:flip(true)
	elseif self._frames.backleft and not self._frames.backright then
		self:_newQuad('backright', tileCoords.backleft)
		self._frames.backright:flip(true)
	end
end

function GraphicsComponent:_updateFB(newX, newY, oldX, oldY)
	if self._mediator then
		local newFrame

		if oldX and oldY then
			local x, y = newX-oldX, newY-oldY
			local xstr, ystr

			if     x > 0 then xstr = 'right'
			elseif x < 0 then xstr = 'left'
			end

			if     y > 0 then ystr = 'front'
			elseif y < 0 then ystr = 'back'
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

		if newX and newY then
			self._drawX, self._drawY = (newX-1)*self._size, (newY-1)*self._size
		end
		self._bfb = self._bfb or newFramebuffer(self._size, self._size)

		setRenderTarget(self._bfb)
		setColor(colors.WHITE)
		drawq(self._tileset, frame, 0, 0)
		setRenderTarget()

		self._ffb, self._bfb = self._bfb, self._ffb
	end
end

function GraphicsComponent:draw()
	if self._lit == 'lit' and self._ffb and self._doDraw then
		setColor(self._color)
		draw(self._ffb, self._drawX, self._drawY)
	end
end


-- the class
return GraphicsComponent
