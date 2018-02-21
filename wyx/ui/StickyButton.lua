local Class = require 'lib.hump.class'
local Button = getClass 'wyx.ui.Button'

local getMousePos = love.mouse.getPosition

-- StickyButton
-- A Button that is picked up and dropped by the mouse.
local StickyButton = Class{name='StickyButton',
	inherits=Button,
	function(self, ...)
		Button.construct(self, ...)
		self:_setLeftClickCallback()
	end
}

-- destructor
function StickyButton:destroy()
	self._slot = nil
	self._entityID = nil

	if self._hiddenTooltip then
		self._hiddenTooltip:destroy()
		self._hiddenTooltip = nil
	end

	Button.destroy(self)
end

-- override Button:setCallback() so that left clicking always checks for a
-- slot to attach to.
function StickyButton:setCallback(button, func, ...)
	if button and button == 1 then return end
	Button.setCallback(self, button, func, ...)
end

-- left click callback - attach to the nearest Slot, if found.
function StickyButton:_setLeftClickCallback()
	self._callbacks['l'] = function()
		local slot = self:_findSlot()
		if slot then slot:swap(self) end
	end
end

-- insert into the nearest Slot
function StickyButton:_findSlot()
	local frames = UISystem:getIntersection()
	local x, y = getMousePos()

	if frames then
		return self:_recursiveFindSlot(frames, x, y)
	end
end

function StickyButton:_recursiveFindSlot(frames, x, y)
	local num = #frames
	for i=1,num do
		local f = frames[i]
		if f ~= self._slot and f:containsPoint(x, y) then
			if isClass('wyx.ui.Slot', f) then
				return f
			else
				local children = f:getChildren()
				if children then
					local found = self:_recursiveFindSlot(children, x, y)
					if found then return found end
				end
			end
		end
	end
end

-- set the slot that this button is socketed into
function StickyButton:setSlot(slot, hideTooltip)
	verifyClass('wyx.ui.Slot', slot)
	self._slot = slot

	if hideTooltip then
		if self._tooltip then
			self:_hideTooltip()
			self._hiddenTooltip = self._tooltip
			self._tooltip = nil
		end
	else
		if self._hiddenTooltip then
			self._tooltip = self._hiddenTooltip
			self._hiddenTooltip = nil
		end
	end

	self:onTick()
end
-- get the slot that this button is socketed into
function StickyButton:getSlot() return self._slot end

-- set the entity that this sticky button references
function StickyButton:setEntityID(id)
	verify('string', id)
	self._entityID = id
end
function StickyButton:getEntityID() return self._entityID end


-- the class
return StickyButton
