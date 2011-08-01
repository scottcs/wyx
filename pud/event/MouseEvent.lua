local Class = require 'lib.hump.class'
local InputEvent = require 'pud.event.InputEvent'
local Vector = require 'pud.kit.Vector'

-- MouseEvent
--
local MouseEvent = Class{name='MouseEvent',
	inherits=InputEvent,
	function(self, x, y, button, grabbed, visible, modifiers)
		InputEvent.construct(self, modifiers)
		self._pos = Vector(x, y)
		self._button = button
		self._grabbed = grabbed
		self._visible = visible
	end
}

-- destructor
function MouseEvent:destroy()
	self._pos = nil
	self._button = nil
	self._grabbed = nil
	self._visible = nil
	InputEvent.destroy(self)
end

-- get the button pressed
function MouseEvent:getButton() return self._button end

-- get the X coordinate of the mouse when the button was pressed
function MouseEvent:getX() return self._pos.x end

-- get the Y coordinate of the mouse when the button was pressed
function MouseEvent:getY() return self._pos.y end

-- get the position of the mouse when the button was pressed
function MouseEvent:getPosition() return self:getX(), self:getY() end

-- get a Vector of the position of the mouse when the button was pressed
function MouseEvent:getPositionVector() return self._pos end

-- return true if the mouse was grabbed when the button was pressed
function MouseEvent:wasGrabbed() return self._grabbed end

-- return true if the mouse was visible when the button was pressed
function MouseEvent:wasVisible() return self._visible end

-- the class
return MouseEvent
