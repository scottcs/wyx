local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'
local Entity = require 'pud.entity.Entity'

local EntityPositionEvent = require 'pud.event.EntityPositionEvent'

-- EntityView
--
local EntityView = Class{name='EntityView',
	inherits=Rect,
	function(self, entity, width, height)
		assert(entity and entity.is_a and entity:is_a(Entity),
			'entity must be an instance of class Entity (was %s (%s))',
			tostring(entity), type(entity))

		width = width or TILEW
		height = height or TILEH
		Rect.construct(self, 0, 0, width, height)
		self._constructed = true
		self._entity = entity
		GameEvents:register(self, EntityPositionEvent)
	end
}

-- destructor
function EntityView:destroy()
	GameEvents:unregisterAll(self)
	self._entity = nil
	self._fb = nil
	self._isDrawing = nil
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

-- draw to the framebuffer
function EntityView:set(tileset, quad, bgset, bgquad)
	assert(tileset and quad, 'must specify tileset and quad')

	local w, h = self:getSize()
	self._fb = love.graphics.newFramebuffer(w, h)

	self._isDrawing = true
	love.graphics.setRenderTarget(self._fb)

	love.graphics.setColor(1,1,1)
	if bgquad then love.graphics.drawq(bgset, bgquad, 0, 0) end
	love.graphics.drawq(tileset, quad, 0, 0)

	love.graphics.setRenderTarget()
	self._isDrawing = false
end

-- draw the framebuffer
function EntityView:draw()
	if self._isDrawing == false then
		local pos = self:getPositionVector()
		local drawX = (pos.x-1)*self:getWidth()
		local drawY = (pos.y-1)*self:getHeight()
		love.graphics.draw(self._fb, drawX, drawY)
	end
end

function EntityView:getPositionVector()
	return self._isAnimating
		and self._animatedPosition
		or self._entity:getPositionVector()
end

function EntityView:EntityPositionEvent(e)
	local entity = e:getEntity()
	if entity ~= self._entity then return end

	local target = e:getDestination()
	self:setPosition(target.x, target.y)
	if not self_isAnimating then
		self._animatedPosition = e:getOrigin()
		self._isAnimating = true
		tween(0.15, self._animatedPosition, target, 'outQuint',
			function(self) self._isAnimating = false end, self)
	end
end

-- the class
return EntityView
