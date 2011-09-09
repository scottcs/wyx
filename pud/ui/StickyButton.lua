local Class = require 'lib.hump.class'
local Button = getClass 'pud.ui.Button'

local getMousePos = love.mouse.getPosition

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
	local x, y = getMousePos()

	if frames then
		return self:_recursiveFindSlot(frames, x, y)
	end
end

function StickyButton:_recursiveFindSlot(frames, x, y)
	local num = #frames
	for i=1,num do
		local f = frames[i]
		if f:containsPoint(x, y) then
			if isClass('pud.ui.Slot', f) then
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

-- attach to mouse cursor
function StickyButton:attachToMouse()
	self._slot = nil
	self._attached = true
	self._hovered = false
	self:onTick()
end

-- detach from mouse cursor into slot
function StickyButton:detachFromMouse(slot)
	verifyClass('pud.ui.Slot', slot)
	self._slot = slot
	self._attached = false
	self._hovered = true
	self:onTick()
end

-- override onTick() to change position to mouse position if attached
function StickyButton:onTick(dt, x, y)
	if self._attached then
		if nil == x and nil == y then x, y = getMousePos() end
		self:setCenter(x, y, 'floor')
		return false
	end

	return Button.onTick(self, dt, x, y)
end


-- the class
return StickyButton
