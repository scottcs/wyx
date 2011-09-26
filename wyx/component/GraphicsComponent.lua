local Class = require 'lib.hump.class'
local ViewComponent = getClass 'wyx.component.ViewComponent'
local LightingStatusRequest = getClass 'wyx.event.LightingStatusRequest'
local property = require 'wyx.component.property'
local message = require 'wyx.component.message'

local newQuad = love.graphics.newQuad
local drawq = love.graphics.drawq
local setColor = love.graphics.setColor
local colors = colors
local cmult = colors.multiply

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
			'RenderDepth',
			'Tint',
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
			'ATTACHMENT_ATTACHED',
			'ATTACHMENT_DETACHED',
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
	elseif prop == property('Tint') then
		verifyAny(data, 'table', 'string', 'nil')

		if type(data) == 'table' then
			local num = #data
			assert(num, 'Tint must be an array')

			for i=1,num do
				local d = data[i]
				verify('number', d)
				assert(d >= 0 and d <= 255, 'Invalid Tint value %d', d)
			end

			self._tint = data
		elseif type(data) == 'string' then
			assert(colors[data], 'No such color %q for Tint', data)
			self._tint = colors[data]
		end
	elseif prop == property('TileSize')
		or prop == property('RenderDepth') then
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
	self:_calculateDraw()
end

function GraphicsComponent:receive(sender, msg, ...)
	if     msg == message('ENTITY_CREATED')
		and sender == self._mediator
	then self:_makeQuads(...)

	elseif msg == message('SCREEN_STATUS')
		and sender == self._mediator
	then self:_setScreenStatus(...)

	elseif msg == message('HAS_MOVED') then
		self:_calculateDraw(...)

	elseif (msg == message('CONTAINER_INSERTED')
		or msg == message('ATTACHMENT_ATTACHED'))
		and sender == self._mediator
	then self._doDraw = false

	elseif (msg == message('CONTAINER_REMOVED')
		or msg == message('ATTACHMENT_DETACHED'))
		and sender == self._mediator
	then self._doDraw = true
	end

	ViewComponent.receive(self, sender, msg, ...)
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

function GraphicsComponent:_calculateDraw(newX, newY, oldX, oldY)
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

		if newX and newY then
			self._drawX, self._drawY = (newX-1)*self._size, (newY-1)*self._size
		end
	end
end

function GraphicsComponent:draw()
	if self._mediator and self._lit == 'lit' and self._doDraw then
		local frame = self._frames[self._curFrame] or self._frames[self._topFrame]

		if self._tint then
			setColor(cmult(self._color, self._tint))
		else
			setColor(self._color)
		end

		drawq(self._tileset, frame, self._drawX, self._drawY)
	end
end


-- the class
return GraphicsComponent
