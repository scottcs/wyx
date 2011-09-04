local Class = require 'lib.hump.class'
local Frame = getClass 'pud.ui.Frame'

local pushRenderTarget, popRenderTarget = pushRenderTarget, popRenderTarget
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
	self._min = nil
	self._max = nil
	self._val = nil
	self._watched = nil
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

-- watch a table (this replaces self._val)
-- the table must be an array, but only the first item is watched
function Bar:watch(t)
	verify('table', t)
	self._watched = t
end
function Bar:unwatch() self._watched = nil end

-- onTick - check watched table
function Bar:_onTick(dt, x, y)
	if self._watched then self:setValue(self._watched[1]) end
	return Frame._onTick(self, dt, x, y)
end

-- override Frame:_drawFB()
function Bar:_drawFB()
	self._bfb = self._bfb or self:_getFramebuffer()
	pushRenderTarget(self._bfb)
	self:_drawBackground()

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

	popRenderTarget()
	self._ffb, self._bfb = self._bfb, self._ffb
end


-- the class
return Bar
