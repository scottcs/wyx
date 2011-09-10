local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'

local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle

-- Bar
-- represents a value in bar form
local Bar = Class{name='Bar',
	inherits=Frame,
	function(self, ...)
		self._margins = {0, 0, 0, 0}
		Frame.construct(self, ...)
	end
}

-- destructor
function Bar:destroy()
	self:unwatch()
	self._min = nil
	self._max = nil
	self._val = nil
	Frame.destroy(self)
end

-- set the minimum and maximum value for the bar
function Bar:setLimits(min, max)
	verify('number', min, max)
	if max < min then min, max = max, min end
	self._min, self._max = min, max
	self:setValue(self._val or max)
end

function Bar:setValue(val)
	verify('number', val)

	local min, max = self._min, self._max
	if min and max then
		val = val >= min and (val <= max and val or max) or min
	end

	self._min = self._min or val
	self._max = self._max or val
	self._val = val

	self:_drawFB()
end

function Bar:setMargins(l, t, r, b)
	t = t or l
	r = r or l
	b = b or t
	verify('number', l, t, r, b)

	self._margins[1] = l
	self._margins[2] = t
	self._margins[3] = r
	self._margins[4] = b

	self:_drawFB()
end

-- watch a function. this function will be polled every tick for a return
-- value, which will replace the value of this Bar object.
function Bar:watch(func, ...)
	verify('function', func)
	self:unwatch()
	self._watched = func
	if select('#', ...) > 0 then
		self._watchedArgs = {...}
	end
end

-- stop watching a function.
function Bar:unwatch()
	self._watched = nil
	if self._watchedArgs then
		for k in pairs(self._watchedArgs) do self._watchedArgs[k] = nil end
		self._watchedArgs = nil
	end
end

-- onTick - check watched table
function Bar:onTick(dt, x, y)
	if self._watched then
		local value
		if self._watchedArgs then
			value = self._watched(unpack(self._watchedArgs))
		else
			value = self._watched()
		end

		if value then
			self:setValue(value)
		end
	end

	return Frame.onTick(self, dt, x, y)
end

-- override Frame:_drawFB()
function Bar:_drawForeground()
	if self._min and self._max and self._val then
		if self._curStyle then
			local x = self._margins[1]
			local y = self._margins[2]
			local w = self:getWidth() - (x + self._margins[3])
			local h = self:getHeight() - (y + self._margins[4])
			local percent = (self._val - self._min) / (self._max - self._min)
			w = w * percent

			local color = self._curStyle:getFGColor()
			setColor(color)
			rectangle('fill', x, y, w, h)
		end
	end
end


-- the class
return Bar
