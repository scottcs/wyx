require 'pud.util'
local Class = require 'lib.hump.class'
local Vector = require 'pud.kit.Vector'

local math_floor, math_ceil = math.floor, math.ceil
local round = function(x) return math_floor(x + 0.5) end

-- Rect
-- provides position and size of a rectangle
-- can call as Rect(x, y, w, h) or Rect(positionVector, sizeVector)
-- Note: coordinates are not floored or rounded and may be floats
local Rect = Class{name='Rect',
	function(self, x, y, w, h)
		x = x or 0
		y = y or 0
		w = w or 0
		h = h or 0

		local pos, size = x, y

		if not Vector.isVector(pos) then
			pos = Vector(x, y)
			size = Vector(w, h)
		end

		self:setSize(size)
		self:setPosition(pos)
	end
}

-- destructor
function Rect:destroy()
	self._pos = nil
	self._size = nil
end

-- get and set position
function Rect:getX() return self._pos.x end
function Rect:setX(x)
	verify('number', x)
	self._pos.x = x
end

function Rect:getY() return self._pos.y end
function Rect:setY(y)
	verify('number', y)
	self._pos.y = y
end

function Rect:getPosition() return self._pos:unpack() end
function Rect:getPositionVector() return self._pos:clone() end
-- call as setPosition(x, y) or setPosition(Vector)
function Rect:setPosition(pos, y)
	if not Vector.isVector(pos) then
		verify('number', pos, y)
		pos = Vector(pos, y)
	end
	self._pos = pos
end

-- valid center adjusment flags
local _adjust = {
	round = function(v)
		v.x = math_floor(v.x+0.5)
		v.y = math_floor(v.y+0.5)
		return v
	end,
	floor = function(v)
		v.x = math_floor(v.x)
		v.y = math_floor(v.y)
		return v
	end,
	ceil = function(v)
		v.x = math_ceil(v.x)
		v.y = math_ceil(v.y)
		return v
	end,
	default = function(v) return v end,
}

local _getAdjust = function(flag)
	flag = flag or 'default'
	assert(nil ~= _adjust[flag], 'unknown flag for center adjustment (%s)', flag)
	return _adjust[flag]
end

-- get and set center coords, rounding to nearest number if requested
function Rect:getCenter(flag) return self:getCenterVector(flag):unpack() end
function Rect:getCenterVector(flag)
	local adjust = _getAdjust(flag)
	return self._pos + adjust(self._size/2)
end

-- call as setCenter(x, y, flag) or setCenter(Vector, flag)
function Rect:setCenter(center, y, flag)
	if not Vector.isVector(center) then
		verify('number', center, y)
		center = Vector(center, y)
	else
		flag = y
	end

	local adjust = _getAdjust(flag)
	self:setPosition(center - adjust(self._size/2))
end

-- get (no set) bounding box coordinates
function Rect:getBBox()
	local tl, br = self:getBBoxVectors()
	return tl.x, tl.y, br.x, br.y
end
function Rect:getBBoxVectors()
	return self._pos, self._pos + self._size
end

-- check if a point falls within the Rect's bounding box
-- call as contains(x, y) or contains(Vector)
function Rect:containsPoint(p, y)
	if not Vector.isVector(p) then
		verify('number', p, y)
		p = Vector(p, y)
	end
	local tl, br = self:getBBoxVectors()
	return p >= tl and p <= br
end

-- get and set size
function Rect:getWidth() return self._size.x end
function Rect:setWidth(w)
	verify('number', w)
	self._size.x = w
end

function Rect:getHeight() return self._size.y end
function Rect:setHeight(h)
	verify('number', h)
	self._size.y = h
end

function Rect:getSize() return self._size:unpack() end
function Rect:getSizeVector() return self._size:clone() end
-- call as setSize(w, h) or setSize(Vector)
function Rect:setSize(size, h)
	if not Vector.isVector(size) then
		verify('number', size, h)
		size = Vector(size, h)
	end
	self._size = size
end

-- tostring
function Rect:__tostring()
	local x, y = self:getPosition()
	local w, h = self:getSize()
	return '('..x..','..y..') '..w..'x'..h
end

-- the class
return Rect
