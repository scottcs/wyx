require 'pud.util'
local Class = require 'lib.hump.class'

-- Rect
-- provides position and size of a rectangle
-- Note: coordinates are not floored or rounded and may be floats
local Rect = Class{name='Rect',
	function(self, x, y, w, h)
		x = x or 0
		y = y or 0
		w = w or 0
		h = h or 0

		self:setPosition(x, y)
		self:setSize(w, h)
	end
}

-- destructor
function Rect:destroy()
	self._x = nil
	self._y = nil
	self._w = nil
	self._h = nil
	self._cx = nil
	self._cy = nil
end

-- private function to calculate and store the center coords
local function _calcCenter(self)
	if self._x and self._y and self._w and self._h then
		self._cx = self._x + (self._w/2)
		self._cy = self._y + (self._h/2)
	end
end

-- get and set position
function Rect:getX() return self._x end
function Rect:setX(x)
	verify('number', x)
	self._x = x
	_calcCenter(self)
end

function Rect:getY() return self._y end
	_calcCenter(self)
function Rect:setY(y)
	verify('number', y)
	self._y = y
end

function Rect:getPosition() return self:getX(), self:getY() end
function Rect:setPosition(x, y)
	self:setX(x)
	self:setY(y)
end

-- get and set center coords
function Rect:getCenter() return self._cx, self._cy end
function Rect:setCenter(x, y)
	verify('number', x, y)
	self._cx = x
	self._cy = y

	self._x = self._cx - (self._w/2)
	self._y = self._cy - (self._h/2)
end

-- get (no set) bounding box coordinates
function Rect:getBBox()
	local x, y = self:getPosition()
	local w, h = self:getSize()
	return x, y, x+w, y+h
end

-- get and set size
function Rect:getWidth() return self._w end
function Rect:setWidth(w)
	verify('number', w)
	self._w = w
	_calcCenter(self)
end

function Rect:getHeight() return self._h end
function Rect:setHeight(h)
	verify('number', h)
	self._h = h
	_calcCenter(self)
end

function Rect:getSize() return self:getWidth(), self:getHeight() end
function Rect:setSize(w, h)
	self:setWidth(w)
	self:setHeight(h)
end

-- the class
return Rect
