local Class = require 'lib.hump.class'
local vector = require 'lib.hump.vector'

local math_abs, math_floor = math.abs, math.floor

-- Line
-- implements Bresenham's Line Algorithm
local Line = Class{name='Line',
	function(self, p, q)
		assert(vector.isvector(p) and vector.isvector(q),
			'vectors expected in Line constructor (was %s, %s)', type(p), type(q))

		self._p = p:clone()
		self._q = q:clone()

		self._index = 1

		self._points = {}
		self._reverse = false

		self:_populate()
	end
}

-- destructor
function Line:destroy()
	self._p = nil
	self._q = nil
	self._index = nil
	self._reverse = nil
	for i in ipairs(self._points) do self._points[i] = nil end
	self._points = nil
end

function Line:_populate()
	local p, q = self._p, self._q
	local isSteep = math_abs(q.y - p.y) > math_abs(q.x - p.x)

	if isSteep then
		p.x, p.y = p.y, p.x
		q.x, q.y = q.y, q.x
	end

	if p.x > q.x then
		p.x, q.x = q.x, p.x
		p.y, q.y = q.y, p.y
		self:reverse()
	end

	local dx, dy = q.x - p.x, math_abs(q.y - p.y)
	local err = math_floor(dx / 2)

	local y = p.y
	local yStep = p.y < q.y and 1 or -1

	for x = p.x, q.x do
		if isSteep then
			self._points[#self._points+1] = vector(y, x)
		else
			self._points[#self._points+1] = vector(x, y)
		end
		err = err - dy
		if err < 0 then
			y = y + yStep
			err = err + dx
		end
	end

	self:reset()
end

function Line:next()
	local v
	if self._index > 0 and self._index <= #self._points then
		v = self._points[self._index]
		self._index = self._reverse and self._index - 1 or self._index + 1
	end
	return v
end

function Line:reset()
	self._index = self._reverse and #self._points or 1
end

function Line:reverse()
	self._reverse = not self._reverse
end


-- the class
return Line
