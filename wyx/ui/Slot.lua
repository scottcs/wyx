local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'

local setColor = love.graphics.setColor
local draw = love.graphics.draw
local colors = colors

-- Slot
-- A place to stick a StickyButton.
local Slot = Class{name='Slot',
	inherits=Frame,
	function(self, ...)
		Frame.construct(self, ...)
	end
}

-- destructor
function Slot:destroy()
	self._button = nil
	Frame.destroy(self)
end

-- swap the given StickyButton with the current one
function Slot:swap(button)
	local oldButton = self._button

	if self._button then
		self._button:setDepth(10)
		self:removeChild(self._button)
		self._button:attachToMouse()
		self._button = nil
	end

	if button and oldButton ~= button then
		verifyClass('wyx.ui.StickyButton', button)

		self._button = button
		self:addChild(self._button, self._depth - 1)
		self._button:detachFromMouse(self)
		self._button:setCenter(self:getCenter())
	end

	if oldButton then oldButton:attachToMouse() end
end

-- override Frame:_drawForeground() to not draw if a button is in the slot
function Slot:_drawForeground()
	if not self._button then
		Frame._drawForeground(self)
	end
end


-- the class
return Slot
