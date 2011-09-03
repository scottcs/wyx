local Class = require 'lib.hump.class'

local colors = colors

-- Style
-- Represents a style of graphics, color, and font elements for a Frame.
local Style = Class{name='Style',
	function(self, t)
		verify('table', t)

		t.fgcolor = t.fgcolor or colors.BLACK
		t.bgcolor = t.bgcolor or colors.WHITE

		if t.image then self:setImage(t.image) end
		if t.quad then self:setImageQuad(t.quad) end
		if t.fgcolor then self:setFGColor(t.fgcolor) end
		if t.bgcolor then self:setBGColor(t.bgcolor) end
		if t.font then self:setFont(t.font) end
	end
}

-- destructor
function Style:destroy()
	self._font = nil
	self._fgcolor = nil
	self._bgcolor = nil
	self._image = nil
	self._quad = nil
end

-- get/set font
function Style:getFont() return self._font end
function Style:setFont(font) self._font = font end

-- get/set foreground color
function Style:getFGColor() return self._fgcolor end
function Style:setFGColor(color)
	verify('table', color)
	self._fgcolor = color
end

-- get/set background color
function Style:getBGColor() return self._bgcolor end
function Style:setBGColor(color)
	verify('table', color)
	self._bgcolor = color
end

-- get/set image
function Style:getImage() return self._image end
function Style:setImage(image) 
	if self._quad then self._quad = nil end
	self._image = image
end

-- get/set image quad
function Style:getQuad() return self._quad end
function Style:setImageQuad(x, y, w, h)
	if not self._image then
		warning('Style: Image must be set before ImageQuad.')
		return
	end

	local quad = x
	if type(quad) == 'number' then
		local iw, ih = self._image:getWidth(), self._image:getHeight()
		quad = love.graphics.newQuad(x, y, w, h, iw, ih)
	end

	assert(quad and quad.typeOf and quad:typeOf('Quad'), 'Style: invalid quad')

	self._quad = quad
end


-- the class
return Style
