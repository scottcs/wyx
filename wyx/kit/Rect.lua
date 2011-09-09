local Class = require 'lib.hump.class'

local math_floor, math_ceil = math.floor, math.ceil
local round = function(x) return math_floor(x + 0.5) end
local format = string.format

-- Rect
-- provides position and size of a rectangle
-- Note: coordinates are not floored or rounded and may be floats
local Rect = Class{name='Rect',
	function(self, x, y, w, h)
		x = x or 0
		y = y or 0
		w = w or 0
		h = h or 0

		self:setSize(w, h)
		self:setPosition(x, y)
	end
}

-- destructor
function Rect:destroy()
	self._x = nil
	self._y = nil
	self._w = nil
	self._h = nil
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

function Rect:getPosition() return self._x, self._y end
function Rect:setPosition(x, y)
	self:setX(x)
	self:setY(y)
end

-- valid center adjusment flags
local _adjust = {
	round = function(x) return math_floor(x+0.5) end,
	floor = function(x) return math_floor(x) end,
	ceil = function(x) return math_ceil(x) end,
	default = function(x) return x end,
}

local _getAdjust = function(flag)
	flag = flag or 'default'
	assert(nil ~= _adjust[flag], 'unknown flag for center adjustment (%s)', flag)
	return _adjust[flag]
end

-- get and set center coords, rounding to nearest number if requested
function Rect:getCenter(flag)
	local adjust = _getAdjust(flag)
	local w, h = self:getSize()
	return self._x + adjust((w-1)/2), self._y + adjust((h-1)/2)
end

function Rect:setCenter(x, y, flag)
	local adjust = _getAdjust(flag)
	local w, h = self:getSize()
	self:setPosition(x - adjust((w-1)/2), y - adjust((h-1)/2))
end

-- get (no set) bounding box coordinates
function Rect:getBBox()
	local w, h = self:getSize()
	return self._x, self._y, self._x + (w-1), self._y + (h-1)
end

-- check if a point falls within the Rect's bounding box
function Rect:containsPoint(x, y)
	local x1, y1 = self._x, self._y
	local x2, y2 = x1 + self._w, y1 + self._h
	return x >= x1 and x <= x2 and y >= y1 and y <= y2
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

function Rect:getSize() return self._w, self._h end
function Rect:setSize(w, h)
	self:setWidth(w)
	self:setHeight(h)
end

-- clone this rect
function Rect:clone()
	return Rect(self._x, self._y, self._w, self._h)
end

-- tostring
function Rect:__tostring()
	local x, y = self:getPosition()
	local w, h = self:getSize()
	return format('(%f,%f) %fx%f', x,y, w,h)
end

-- the class
return Rect
