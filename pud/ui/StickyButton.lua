local Class = require 'lib.hump.class'
local Button = getClass 'pud.ui.Button'

-- StickyButton
-- A Button that is picked up and dropped by the mouse.
local StickyButton = Class{name='StickyButton',
	inherits=Button,
	function(self, ...)
		Button.construct(self, ...)
		self:_setLeftClickCallback()
		self._attached = false
	end
}

-- destructor
function StickyButton:destroy()
	self._slot = nil
	self._attached = nil
	Button.destroy(self)
end

-- override Button:setCallback() so that left clicking always attaches or
-- detaches from the Mouse.
function StickyButton:setCallback(button, func, ...)
	if button and button == 'l' then return end
	Button.setCallback(self, button, func, ...)
end

-- left click callback - attach or unattach from the mouse cursor and
-- add/remove self from nearest overlapping Slot.
function StickyButton:_setLeftClickCallback()
	self._callbacks['l'] = function()
		local slot = self._slot or self:_findSlot()
		if slot then slot:swap(self) end
	end
end

-- insert into the nearest Slot (unattach from mouse cursor)
function StickyButton:_findSlot()
	local frames = UISystem:getIntersection()

	if frames then
		local num = #frames
		for i=1,num do
			local f = frames[i]
			if isClass('pud.ui.Slot', f) then
				return f
			end
		end
	end
end

-- attach to mouse cursor
function StickyButton:attachToMouse()
	self._slot = nil
	self._attached = true
end

-- detach from mouse cursor into slot
function StickyButton:detachFromMouse(slot)
	verifyClass('pud.ui.Slot', slot)
	self._slot = slot
	self._attached = false
end

-- override onTick() to change position to mouse position if attached
function StickyButton:onTick(dt, x, y)
	if self._attached then self:setCenter(x, y) end
	return Button.onTick(self, dt, x, y)
end


-- the class
return StickyButton
