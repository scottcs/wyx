local Class = require 'lib.hump.class'
local InputEvent = getClass 'wyx.event.InputEvent'

-- MouseEvent
--
local MouseEvent = Class{name='MouseEvent',
	inherits=InputEvent,
	function(self, x, y, button, grabbed, visible, istouch, modifiers)
		InputEvent.construct(self, 'Mouse Event', modifiers)
		self._x, self._y = x, y
		self._button = button
		self._grabbed = grabbed
		self._visible = visible
    self._istouch = istouch
	end
}

-- destructor
function MouseEvent:destroy()
	self._x = nil
	self._y = nil
	self._button = nil
	self._grabbed = nil
	self._visible = nil
  self._istouch = nil
	InputEvent.destroy(self)
end

-- get the button pressed
function MouseEvent:getButton() return self._button end

-- get the X coordinate of the mouse when the button was pressed
function MouseEvent:getX() return self._x end

-- get the Y coordinate of the mouse when the button was pressed
function MouseEvent:getY() return self._y end

-- get the position of the mouse when the button was pressed
function MouseEvent:getPosition() return self:getX(), self:getY() end

-- return true if the mouse was grabbed when the button was pressed
function MouseEvent:wasGrabbed() return self._grabbed end

-- return true if the mouse was visible when the button was pressed
function MouseEvent:wasVisible() return self._visible end

-- return true if the event was touch based
function MouseEvent:wasTouch() return self._istouch end

function MouseEvent:__tostring()
	return self:_msg('(%d,%d) b: %s, g: %s, v: %s, m: %s',
		self._x, self._y, tostring(self._button), tostring(self._grabbed),
		tostring(self._visible), IntpuEvent.__tostring(self))
end


-- the class
return MouseEvent
