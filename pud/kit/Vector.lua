local Class = require 'lib.hump.class'

local _isVector = function(v) return v and v.is_a and v:is_a(Vector) end

-- Vector
-- rewritten from Hump's vector to make it a class and add destructor.
-- Hump's vectors were never destroyed, causing serious memory leaks.
local Vector = Class{name='Vector',
	function(self, x, y)
		if _isVector(x) then
			self.x, self.y = x.x, x.y
		else
			self.x, self.y = x or 0, y or 0
		end
	end
}

-- destructor
function Vector:destroy()
	self.x = nil
	self.y = nil
end

function Vector:clone()
	return Vector(self.x, self.y)
end

function Vector:unpack()
	return self.x, self.y
end

function Vector:__tostring()
	return '('..tonumber(self.x)..','..tonumber(self.y)..')'
end

function Vector.__unm(a)
	return Vector(-a.x, -a.y)
end

function Vector.__add(a,b)
	assert(_isVector(a) and _isVector(b),
		'Add: wrong argument types (Vectors expected, were %s and %s)',
		type(a), type(b))
	return Vector(a.x+b.x, a.y+b.y)
end

function Vector.__sub(a,b)
	assert(_isVector(a) and _isVector(b),
		'Sub: wrong argument types (Vectors expected, were %s and %s)',
		type(a), type(b))
	return Vector(a.x-b.x, a.y-b.y)
end

function Vector.__mul(a,b)
	if type(a) == 'number' then
		return Vector(a*b.x, a*b.y)
	elseif type(b) == 'number' then
		return Vector(b*a.x, b*a.y)
	else
		assert(_isVector(a) and _isVector(b),
			'Mul: wrong argument types (Vector or number expected, were %s and %s)',
			type(a), type(b))
		return a.x*b.x + a.y*b.y
	end
end

function Vector.__div(a,b)
	assert(_isVector(a) and type(b) == 'number',
		'wrong argument types (expected Vector / number, were %s / %s)',
		type(a), type(b))
	return Vector(a.x / b, a.y / b)
end

function Vector.__eq(a,b)
	return a.x == b.x and a.y == b.y
end

function Vector.__lt(a,b)
	return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function Vector.__le(a,b)
	return a.x <= b.x and a.y <= b.y
end

function Vector.permul(a,b)
	assert(_isVector(a) and _isVector(b),
		'permul: wrong argument types (Vectors expected, were %s and %s)',
		type(a), type(b))
	return Vector(a.x*b.x, a.y*b.y)
end

function Vector:len2()
	return self.x * self.x + self.y * self.y
end

function Vector:len()
	return sqrt(self:len2())
end

function Vector.dist(a, b)
	assert(_isVector(a) and _isVector(b),
		'dist: wrong argument types (Vectors expected, were %s and %s)',
		type(a), type(b))
	return (b-a):len()
end

function Vector:normalize_inplace()
	local l = self:len()
	self.x, self.y = self.x / l, self.y / l
	return self
end

function Vector:normalized()
	return self / self:len()
end

function Vector:rotate_inplace(phi)
	local c, s = cos(phi), sin(phi)
	self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
	return self
end

function Vector:rotated(phi)
	return self:clone():rotate_inplace(phi)
end

function Vector:perpendicular()
	return Vector(-self.y, self.x)
end

function Vector:projectOn(v)
	assert(_isVector(v),
		'cannot project onto anything other than a Vector (was %s)', type(v))
	return (self * v) * v / v:len2()
end

function Vector:mirrorOn(other)
	assert(_isVector(other),
		'cannot mirror on anything other than a Vector (was %s)', type(v))
	return 2 * self:projectOn(other) - self
end

function Vector:cross(other)
	assert(_isVector(other),
		'cross: wrong argument types (Vector expected, was %s)', type(other))
	return self.x * other.y - self.y * other.x
end

-- the class
return Vector
