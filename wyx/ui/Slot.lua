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

	self:_clearVerificationCallback()
	self:_clearInsertCallback()
	self._verificationCallback = nil
	self._insertCallback = nil
	self._hideTooltips = nil

	Frame.destroy(self)
end

-- verify that a button is allowed to be socketed in this Slot
function Slot:verifyButton(button)
	local verified = true

	if self._verificationCallback then
		local args = self._verificationCallbackArgs
		if args then
			verified = self._verificationCallback(button, unpack(args))
		else
			verified = self._verificationCallback(button)
		end
	end

	return verified
end

-- swap the given StickyButton with the current one
function Slot:swap(button)
	verifyClass('wyx.ui.StickyButton', button)
	local otherSlot = button:getSlot()
	local otherButton
	local oldButton = self:remove()

	if not otherSlot:isEmpty() then otherButton = otherSlot:remove() end

	local verified, oldVerified = false, true
	if oldButton then oldVerified = otherSlot:verifyButton(oldButton) end
	verified = self:verifyButton(button)

	if verified and oldVerified then
		if oldButton then otherSlot:insert(oldButton, oldVerified) end
		self:insert(button, verified)
	else
		if oldButton then self:insert(oldButton, true) end
		otherSlot:insert(button, true)
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

			if self._insertCallback then
				local args = self._insertCallbackArgs
				if args then
					self._insertCallback(button, unpack(args))
				else
					self._insertCallback(button)
				end
			end
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
	end

	return oldButton
end

function Slot:setVerificationCallback(func, ...)
	verify('function', func)
	self:_clearVerificationCallback()

	self._verificationCallback = func

	local numArgs = select('#', ...)
	if numArgs > 0 then self._verificationCallbackArgs = {...} end
end

function Slot:setInsertCallback(func, ...)
	verify('function', func)
	self:_clearInsertCallback()

	self._insertCallback = func

	local numArgs = select('#', ...)
	if numArgs > 0 then self._insertCallbackArgs = {...} end
end

-- clear the verification callback
function Slot:_clearVerificationCallback()
	self._verificationCallback = nil
	if self._verificationCallbackArgs then
		for k,v in self._verificationCallbackArgs do
			self._verificationCallbackArgs[k] = nil
		end
		self._verificationCallbackArgs = nil
	end
end

-- clear the insert callback
function Slot:_clearInsertCallback()
	self._insertCallback = nil
	if self._insertCallbackArgs then
		for k,v in self._insertCallbackArgs do
			self._insertCallbackArgs[k] = nil
		end
		self._insertCallbackArgs = nil
	end
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
