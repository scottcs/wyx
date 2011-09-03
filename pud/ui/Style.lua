local Class = require 'lib.hump.class'

local colors = colors

-- Style
-- Represents a style of graphics, color, and font elements for a Frame.
local Style = Class{name='Style',
	function(self, image, quad, color, font, fontcolor)
		if type(image) == 'table' then
			fontcolor = image.fontcolor
			font = image.font
			color = image.color
			quad = image.quad
			image = image.image
		end

		color = color or colors.WHITE

		if font then
			fontcolor = fontcolor or colors.WHITE
		end

		if image then self:setImage(image) end
		if quad then self:setImageQuad(quad) end
		if color then self:setColor(color) end
		if font then self:setFont(font, fontcolor) end
	end
}

-- destructor
function Style:destroy()
	self._font = nil
	self._fontcolor = nil
	self._color = nil
	self._image = nil
	self._quad = nil
end

-- get/set font
function Style:getFont() return self._font end
function Style:setFont(font, color)
	self._font = font
	if color then self:setFontColor(color) end
end

-- get/set font color
function Style:getFontColor() return self._fontcolor end
function Style:setFontColor(color)
	verify('table', color)
	self._fontcolor = color
end

-- get/set color
function Style:getColor() return self._color end
function Style:setColor(color)
	verify('table', color)
	self._color = color
end

-- get/set image
function Style:getImage() return self._image end
function Style:setImage(image) self._image = image end

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
