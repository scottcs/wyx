local Class = require 'lib.hump.class'
local Frame = getClass 'pud.ui.Frame'

local pushRenderTarget, popRenderTarget = pushRenderTarget, popRenderTarget
local setColor = love.graphics.setColor
local setFont = love.graphics.setFont
local gprint = love.graphics.print

local math_floor = math.floor
local string_sub = string.sub

-- Text
-- A static text frame
local Text = Class{name='Text',
	inherits=Frame,
	function(self, ...)
		Frame.construct(self, ...)
		self._text = {}
		self._justify = 'l'
		self._margin = 0
	end
}

-- destructor
function Text:destroy()
	for k,v in pairs(self._text) do self._text[k] = nil end
	self._text = nil
	self._justify = nil
	self._margin = nil
	Frame.destroy(self)
end

-- set the text that will be displayed
-- text can be a string or a table of strings, representing lines
-- (newline is not supported)
function Text:setText(text)
	if type(text) == 'string' then text = {text} end
	verify('table', text)

	local font
	if self._curStyle then
		font = self._curStyle:getFont()
	end
	font = font or GameFont.small

	-- assuming width is constant, clip lines if they're larger than the width
	-- of this frame.
	local w = font:getWidth('W')
	local margin = self._margin or 0
	local frameWidth = self:getWidth() - (2 * margin)
	local max = math_floor(frameWidth/w)
	local num = #text
	for i=1,num do
		print(font:getWidth(text[i]), frameWidth, max)
		if font:getWidth(text[i]) > frameWidth then
			local clipped = string_sub(text[i], 1, max)
			warning('Clipping text %q to %q (%d max)', text[i], clipped, max)
			text[i] = clipped
		end
	end

	self._text = text
	self:_drawFB()
end

-- returns the currently set text as a table of strings, one per line
function Text:getText() return self._text end

-- set the margin between the frame edge and the text
function Text:setMargin(margin)
	verify('number', margin)
	self._margin = margin
	self:_drawFB()
end

-- set the justification
function Text:setJustifyLeft()   self._justify = 'l' end
function Text:setJustifyRight()  self._justify = 'r' end
function Text:setJustifyCenter() self._justify = 'c' end

-- override Frame:_drawFB()
function Text:_drawFB()
	self._bfb = self._bfb or self:_getFramebuffer()
	pushRenderTarget(self._bfb)
	self:_drawBackground()

	local numLines = self._text and #self._text or 0

	if numLines > 0 then
		if self._curStyle then
			local font = self._curStyle:getFont()
			if font then
				local height = font:getHeight()
				local margin = self._margin or 0
				local fontcolor = self._curStyle:getFontColor()

				setFont(font)
				setColor(fontcolor)

				for i=1,numLines do
					local line = self._text[i]
					local h = (i-1) * height
					local w = font:getWidth(line)
					local y = margin + h
					local x

					if     'l' == self._justify then
						x = margin
					elseif 'c' == self._justify then
						local cx = self:getWidth() / 2
						x = math_floor(cx - (w/2))
					elseif 'r' == self._justify then
						x = self:getWidth() - (margin + w)
					else
						x, y = 0, 0
						warning('Unjustified (justify is set to %q)',
							tostring(self._justify))
					end

					gprint(line, x, y)
				end
			end
		end
	end

	popRenderTarget()
	self._ffb, self._bfb = self._bfb, self._ffb
end

-- the class
return Text
