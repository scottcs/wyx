local Class = require 'lib.hump.class'

local colors = colors

-- Style
-- Represents a style of graphics, color, and font elements for a Frame.
local Style = Class{name='Style',
	function(self, image, color, font, fontcolor)
		if type(image) == 'table' then
			fontcolor = image.fontcolor
			font = image.font
			color = image.color
			image = image.image
		end

		if font then
			fontcolor = fontcolor or colors.WHITE
		end

		if image then self:setImage(image) end
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
end

-- get/set font
function Style:setFont(font, color)
	self._font = font
	if color then self:setFontColor(color) end
end
function Style:getFont() return self._font end

-- get/set font color
function Style:setFontColor(color)
	verify('table', color)
	self._fontcolor = color
end
function Style:getFontColor() return self._fontcolor end

-- get/set color
function Style:setColor(color)
	verify('table', color)
	self._color = color
end
function Style:getColor() return self._color end

-- get/set image
function Style:setImage(image) self._image = image end
function Style:getImage() return self._image end


-- the class
return Style
