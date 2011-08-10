local Class = require 'lib.hump.class'
local Rect = getClass 'pud.kit.Rect'

local CommandEvent = getClass 'pud.event.CommandEvent'
local MoveCommand = getClass 'pud.command.MoveCommand'

local math_max = math.max

-- EntityView
--
local EntityView = Class{name='EntityView',
	inherits=Rect,
	function(self, entity, width, height)
		verifyClass('pud.entity.Entity', entity)

		width = width or TILEW
		height = height or TILEH
		Rect.construct(self, 0, 0, width, height)
		self._constructed = true
		self._entity = entity
		self._movingLeft = false
		CommandEvents:register(self, CommandEvent)
	end
}

-- destructor
function EntityView:destroy()
	CommandEvents:unregisterAll(self)
	self._entity = nil
	self._fb = nil
	self._movingLeft = nil
	self._isDrawing = nil
	self._quad = nil
	self._constructed = nil
	Rect.destroy(self)
end

-- don't allow resizing
function EntityView:setSize(...)
	if self._constructed then
		error('Cannot resize EntityView. Please destroy and create a new one.')
	else
		Rect.setSize(self, ...)
	end
end
function EntityView:setWidth(...)
	if self._constructed then
		error('Cannot resize EntityView. Please destroy and create a new one.')
	else
		Rect.setWidth(self, ...)
	end
end
function EntityView:setHeight(...)
	if self._constructed then
		error('Cannot resize EntityView. Please destroy and create a new one.')
	else
		Rect.setHeight(self, ...)
	end
end

-- flip quad if moving left
function EntityView:CommandEvent(e)
	local command = e:getCommand()
	if not isClass(MoveCommand, command) then return end
	if command:getTarget() ~= self._entity then return end

	local v = command:getVector()
	if (self._movingLeft and v.x > 0)
		or (not self._movingLeft and v.x < 0)
	then
		self._movingLeft = v.x < 0
		self._quad:flip(1)
		self:_drawFB()
	end
end

function EntityView:set(tileset, quad, bgset, bgquad)
	assert(tileset and quad, 'must specify tileset and quad')

	self._tileset = tileset
	self._quad = quad
	self._bgset = bgset
	self._bgquad = bgquad

	self:_drawFB()
end


-- draw to the framebuffer
function EntityView:_drawFB()
	local size = nearestPO2(math_max(self:getWidth(), self:getHeight()))
	self._fb = love.graphics.newFramebuffer(size, size)

	self._isDrawing = true
	love.graphics.setRenderTarget(self._fb)

	love.graphics.setColor(1,1,1)
	if self._bgquad then
		love.graphics.drawq(self._bgset, self._bgquad, 0, 0)
	end
	love.graphics.drawq(self._tileset, self._quad, 0, 0)

	love.graphics.setRenderTarget()
	self._isDrawing = false
end

-- draw the framebuffer
function EntityView:draw()
	if self._isDrawing == false then
		local x, y = self._entity:getPosition()
		local drawX = (x-1)*self:getWidth()
		local drawY = (y-1)*self:getHeight()
		love.graphics.draw(self._fb, drawX, drawY)
	end
end

-- the class
return EntityView
