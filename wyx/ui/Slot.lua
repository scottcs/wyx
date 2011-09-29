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

	self._hideTooltips = nil
	self._id = nil

	Frame.destroy(self)
end

-- get/set an arbitrary id
function Slot:setID(id) self._id = id end
function Slot:getID() return self._id end

-- verify that a button is allowed to be socketed in this Slot
function Slot:verifyButton(button)
	local verified = true

	if self:_callbackExists('verify') then
		local id = self:getID()
		verified = self:_callCallback('verify', button, id)
	end

	return verified == true
end

-- swap the given StickyButton with the current one
function Slot:swap(button)
	verifyClass('wyx.ui.StickyButton', button)
	local otherSlot = button:getSlot()

	local myButtonOK = true
	local yourButtonOK = self:verifyButton(button)
	
	if self._button then
		myButtonOK = otherSlot:verifyButton(self._button)
	end

	if myButtonOK and yourButtonOK then
		local myButton = self:remove()
		local yourButton = otherSlot:remove()

		if myButton then otherSlot:insert(myButton, true) end
		self:insert(yourButton, true)
	end
end

-- insert the given button
function Slot:insert(button, verified)
	local inserted = false

	if not self._button then
		verified = verified or self:verifyButton(button)

		if verified then
			inserted = true
			self._button = button
			self:addChild(self._button, self._depth - 1)
			self._button:setSlot(self, self._hideTooltips)
			self._button:setCenter(self:getCenter())

			local id = self:getID()
			self:_callCallback('insert', button, id)
		end
	end

	return inserted
end

-- remove the current button
function Slot:remove()
	local oldButton

	if self._button then
		self:removeChild(self._button)
		oldButton = self._button
		self._button = nil

		local id = self:getID()
		self:_callCallback('remove', oldButton, id)
	end

	return oldButton
end

function Slot:setVerificationCallback(func, ...)
	self:setCallback('verify', func, ...)
end

function Slot:setInsertCallback(func, ...)
	self:setCallback('insert', func, ...)
end

function Slot:setRemoveCallback(func, ...)
	self:setCallback('remove', func, ...)
end

-- return true if the slot is empty
function Slot:isEmpty() return self._button == nil end

-- return the current button without removing it
function Slot:getButton() return self._button end

-- hide tooltips of attached buttons
function Slot:hideTooltips() self._hideTooltips = true end
function Slot:showTooltips() self._hideTooltips = false end


-- override Frame:_drawForeground() to not draw if a button is in the slot
function Slot:_drawForeground()
	if not self._button then
		Frame._drawForeground(self)
	end
end


-- the class
return Slot
