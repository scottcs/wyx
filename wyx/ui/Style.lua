local Class = require 'lib.hump.class'

local colors = colors
local cclone = colors.clone

-- Style
-- Represents a style of graphics, color, and font elements for a Frame.
local Style = Class{name='Style',
	function(self, t)
		t = t or {}
		verify('table', t)

		if t.bgimage then self:setBGImage(t.bgimage) end
		if t.bgquad then self:setBGQuad(t.bgquad) end
		if t.bgcolor then self:setBGColor(t.bgcolor) end
		if t.fgimage then self:setFGImage(t.fgimage) end
		if t.fgquad then self:setFGQuad(t.fgquad) end
		if t.fgcolor then self:setFGColor(t.fgcolor) end
		if t.borderimage then self:setBorderImage(t.borderimage) end
		if t.borderquad then self:setBorderQuad(t.borderquad) end
		if t.bordercolor then self:setBorderColor(t.bordercolor) end
		if t.bordersize then self:setBorderSize(t.bordersize) end
		if t.borderinset then self:setBorderInset(t.borderinset) end
		if t.font then self:setFont(t.font, t.fontcolor) end
	end
}

-- destructor
function Style:destroy()
	self._font = nil
	self._fontcolor = nil
	self._fgcolor = nil
	self._fgimage = nil
	self._fgquad = nil
	self._bordersize = nil
	self._borderinset = nil
	self._bordercolor = nil
	self._borderimage = nil
	self._borderquad = nil
	self._bgcolor = nil
	self._bgimage = nil
	self._bgquad = nil
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
	self._fontcolor = cclone(color)
end

-- get/set border color
function Style:getBorderColor() return self._bordercolor end
function Style:setBorderColor(color)
	verify('table', color)
	self._bordercolor = cclone(color)
end

-- get/set border image
function Style:getBorderImage() return self._borderimage end
function Style:setBorderImage(image, ...)
	if self._borderquad then self._borderquad = nil end
	self._borderimage = image
	if select('#', ...) > 0 then self:setBorderQuad(...) end
end

-- get/set border image quad
function Style:getBorderQuad() return self._borderquad end
function Style:setBorderQuad(x, y, w, h)
	self._borderquad = self:_makeQuad(self._borderimage, x, y, w, h)
end

-- get/set border size
function Style:getBorderSize() return self._bordersize end
function Style:setBorderSize(size)
	verify('number', size)
	self._bordersize = size
end

-- get/set border inset
function Style:getBorderInset() return self._borderinset end
function Style:setBorderInset(inset)
	verify('number', inset)
	self._borderinset = inset
end

-- get/set foreground color
function Style:getFGColor() return self._fgcolor end
function Style:setFGColor(color)
	verify('table', color)
	self._fgcolor = cclone(color)
end

-- get/set foreground image
function Style:getFGImage() return self._fgimage end
function Style:setFGImage(image, ...)
	if self._fgquad then self._fgquad = nil end
	self._fgimage = image
	if select('#', ...) > 0 then self:setFGQuad(...) end
end

-- get/set foreground image quad
function Style:getFGQuad() return self._fgquad end
function Style:setFGQuad(x, y, w, h)
	self._fgquad = self:_makeQuad(self._fgimage, x, y, w, h)
end

-- get/set background color
function Style:getBGColor() return self._bgcolor end
function Style:setBGColor(color)
	verify('table', color)
	self._bgcolor = cclone(color)
end

-- get/set background image
function Style:getBGImage() return self._bgimage end
function Style:setBGImage(image, ...)
	if self._bgquad then self._bgquad = nil end
	self._bgimage = image
	if select('#', ...) > 0 then self:setBGQuad(...) end
end

-- get/set background image quad
function Style:getBGQuad() return self._bgquad end
function Style:setBGQuad(x, y, w, h)
	self._bgquad = self:_makeQuad(self._bgimage, x, y, w, h)
end

function Style:_makeQuad(image, x, y, w, h)
	if not image then
		warning('Style: Image must be set before Quad.')
		return
	end

	local quad = x
	if type(quad) == 'number' then
		local iw, ih = image:getWidth(), image:getHeight()
		quad = love.graphics.newQuad(x, y, w, h, iw, ih)
	end

	assert(quad and quad.typeOf and quad:typeOf('Quad'), 'Style: invalid quad')

	return quad
end

-- return a copy of this Style
-- possibly changing some values in the copy
function Style:clone(t)
	t = t or {}
	verify('table', t)

	t.bordersize = t.bordersize or self._bordersize
	t.borderinset = t.borderinset or self._borderinset
	t.bordercolor = t.bordercolor or self._bordercolor
	t.borderimage = t.borderimage or self._borderimage
	t.borderquad = t.borderquad or self._borderquad
	t.fgcolor = t.fgcolor or self._fgcolor
	t.fgimage = t.fgimage or self._fgimage
	t.fgquad = t.fgquad or self._fgquad
	t.bgcolor = t.bgcolor or self._bgcolor
	t.bgimage = t.bgimage or self._bgimage
	t.bgquad = t.bgquad or self._bgquad
	t.font = t.font or self._font
	t.fontcolor = t.fontcolor or self._fontcolor

	return Style(t)
end


-- the class
return Style
