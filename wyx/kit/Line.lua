local Class = require 'lib.hump.class'

local math_abs, math_floor = math.abs, math.floor

-- Line
-- implements Bresenham's Line Algorithm
local Line = Class{name='Line',
	function(self, px, py, qx, xy)
		verify('number', px, py, qx, qy)

		self._px, self._py = px, py
		self._qx, self._qy = qx, qy

		self._index = 1

		self._pointsX = {}
		self._pointsY = {}
		self._reverse = false

		self:_populate()
	end
}

-- destructor
function Line:destroy()
	self._px = nil
	self._py = nil
	self._qx = nil
	self._qy = nil
	self._index = nil
	self._reverse = nil
	for i in ipairs(self._pointsX) do self._pointsX[i] = nil end
	self._pointsX = nil
	for i in ipairs(self._pointsY) do self._pointsY[i] = nil end
	self._pointsY = nil
end

function Line:_populate()
	local px, py = self._px, self._py
	local qx, qy = self._qx, self._qy
	local isSteep = math_abs(qy - py) > math_abs(qx - px)

	if isSteep then
		px, py = py, px
		qx, qy = qy, qx
	end

	if px > qx then
		px, qx = qx, px
		py, qy = qy, py
		self:reverse()
	end

	local dx, dy = qx - px, math_abs(qy - py)
	local err = math_floor(dx / 2)

	local y = py
	local yStep = py < qy and 1 or -1

	for x = px, qx do
		if isSteep then
			self._pointsX[#self._pointsX+1] = y
			self._pointsY[#self._pointsY+1] = x
		else
			self._pointsX[#self._pointsX+1] = x
			self._pointsY[#self._pointsY+1] = y
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
	local x, y
	if self._index > 0 and self._index <= #self._pointsX then
		x, y = self._pointsX[self._index], self._pointsY[self._index]
		self._index = self._reverse and self._index - 1 or self._index + 1
	end
	return x, y
end

function Line:reset()
	self._index = self._reverse and #self._pointsX > 0 or 1
end

function Line:reverse()
	self._reverse = not self._reverse
end


-- the class
return Line
