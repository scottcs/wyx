require 'pud.util'
local Class = require 'lib.hump.class'

local math_floor, math_ceil = math.floor, math.ceil
local round = function(x) return math_floor(x + 0.5) end

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

function Rect:getPosition() return self:getX(), self:getY() end
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
	local x = self._x + adjust(self._w/2)
	local y = self._y + adjust(self._h/2)
	return x, y
end
function Rect:setCenter(x, y, flag)
	verify('number', x, y)
	local adjust = _getAdjust(flag)
	self:setPosition(x - adjust(self._w/2), y - adjust(self._h/2))
end

-- get (no set) bounding box coordinates
function Rect:getBBox()
	local x1, y1 = self:getPosition()
	local x2, y2 = x1 + self:getWidth(), y1 + self:getHeight()
	return x1, y1, x2, y2
end

-- check if a point falls within the Rect's bounding box
function Rect:containsPoint(x, y)
	local x1, y1, x2, y2 = self:getBBox()
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

function Rect:getSize() return self:getWidth(), self:getHeight() end
function Rect:setSize(w, h)
	self:setWidth(w)
	self:setHeight(h)
end

-- tostring
function Rect:__tostring()
	local x, y = self:getPosition()
	local w, h = self:getSize()
	return '('..x..','..y..') '..w..'x'..h
end

-- the class
return Rect
