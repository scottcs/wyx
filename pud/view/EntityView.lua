local Class = require 'lib.hump.class'
local Rect = require 'pud.kit.Rect'
local Entity = require 'pud.entity.Entity'

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
	end
}

-- destructor
function EntityView:destroy()
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
function EntityView:set(tileset, quad, bgquad)
	assert(tileset and quad, 'must specify tileset and quad')

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
