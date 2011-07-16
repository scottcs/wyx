require 'pud.util'
local Class = require 'lib.hump.class'
local round = function(x) return math.floor(x + 0.5) end

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

-- get and set position
function Rect:getX() return self._x end
function Rect:setX(x)
	verify('number', x)
	self._x = x
end

function Rect:getY() return self._y end
function Rect:setY(y)
	verify('number', y)
	self._y = y
end

function Rect:getPosition() return self:getX(), self:getY() end
function Rect:setPosition(x, y)
	self:setX(x)
	self:setY(y)
end

-- get and set center coords, rounding to nearest number if requested
function Rect:getCenter(doRound)
	local x, y = self:getPosition()
	local w, h = self:getSize()

	w = doRound and round(w/2) or w/2
	h = doRound and round(h/2) or h/2

	return x + w, y + h
end
function Rect:setCenter(x, y, doRound)
	verify('number', x, y)

	local w, h = self:getSize()
	w = doRound and round(w/2) or w/2
	h = doRound and round(h/2) or h/2

	self:setX(x - w)
	self:setY(y - h)
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
end

function Rect:getHeight() return self._h end
function Rect:setHeight(h)
	verify('number', h)
	self._h = h
end

function Rect:getSize() return self:getWidth(), self:getHeight() end
function Rect:setSize(w, h)
	self:setWidth(w)
	self:setHeight(h)
end

-- the class
return Rect
