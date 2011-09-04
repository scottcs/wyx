local Class = require 'lib.hump.class'
local Frame = getClass 'pud.ui.Frame'

local pushRenderTarget, popRenderTarget = pushRenderTarget, popRenderTarget
local setColor = love.graphics.setColor
local setFont = love.graphics.setFont
local gprint = love.graphics.print
local rectangle = love.graphics.rectangle

local math_floor = math.floor
local string_sub = string.sub
local string_gmatch = string.gmatch
local format = string.format

-- Text
-- A static text frame
local Text = Class{name='Text',
	inherits=Frame,
	function(self, ...)
		Frame.construct(self, ...)
		self._maxLines = 1
		self._text = {}
		self._justify = 'l'
		self._align = 't'
		self._margin = 0
		self._showCursor = false
	end
}

-- destructor
function Text:destroy()
	self:clear()
	self._text = nil
	self._justify = nil
	self._align = nil
	self._margin = nil
	self._watched = nil
	self._showCursor = nil
	Frame.destroy(self)
end

-- set the text that will be displayed
-- text can be a string or a table of strings, representing lines
-- (newline is not supported)
function Text:setText(text)
	if type(text) == 'string' then text = {text} end
	verify('table', text)

	self:clear()
	text = self:_wrap(text)

	local numLines = #text

	if numLines > self._maxLines then
		warning('setText(lines): number of lines (%d) exceeds maximum (%d)',
			numLines, self._maxLines)

		for i=1,self._maxLines do
			self._text[i] = text[i]
		end
	else
		self._text = text
	end

	self:_drawFB()
end

-- assuming width is constant, wrap lines if they're larger than the width
-- of this frame.
function Text:_wrap(text)
	local font = self._curStyle:getFont()
	if font then
		local space = font:getWidth(' ')
		local margin = self._margin or 0
		local frameWidth = self:getWidth() - (2 * margin)
		local num = #text
		local wrapped
		local wrapcount = 0

		for i=1,num do
			wrapcount = wrapcount + 1
			wrapped = wrapped or {}

			-- if width is too long, wrap
			if font:getWidth(text[i]) > frameWidth then
				local width = 0
				local here = 0

				-- check one word at a time
				for word in string_gmatch(text[i], '%s*(%S+)') do
					local wordW = font:getWidth(word)
					local prevWidth = width
					width = width + wordW

					-- if the running width of all checked words is too long, wrap
					if width > frameWidth then
						-- if it's a single word, or we're on the last line, truncate
						if width == wordW or wrapcount == self._maxLines then
							local old = word
							while #word > 0 and width > frameWidth do
								word = string_sub(word, 1, -2)
								wordW = font:getWidth(word)
								width = prevWidth + wordW
							end
							--warning('Word %q is too long, truncating to %q', old, word)
						end

						if prevWidth == 0 then
							-- single word
							width = -space
							wrapped[wrapcount] = word
						elseif wrapcount == self._maxLines then
							-- last line
							width = frameWidth - space
							wrapped[wrapcount] = format('%s %s', wrapped[wrapcount], word)
						else
							-- neither single word or last line
							width = wordW
							wrapcount = wrapcount + 1
							wrapped[wrapcount] = word
						end
					else
						-- didn't wrap, just add the word
						if wrapped[wrapcount] then
							wrapped[wrapcount] = format('%s %s', wrapped[wrapcount], word)
						else
							wrapped[wrapcount] = word
						end
					end -- if width > frameWidth

					width = width + space
				end -- for word in string_gmatch
			else
				wrapped[wrapcount] = text[i]
			end -- if font:getWidth
		end

		return wrapped and wrapped or text
	end
end

-- returns the currently set text as a table of strings, one per line
function Text:getText() return self._text end

-- show the cursor when drawing text
function Text:showCursor() self._showCursor = true end

-- hide the cursor when drawing text
function Text:hideCursor() self._showCursor = false end

-- watch a table (this replaces any text already set)
-- the table must be an array
function Text:watch(t)
	verify('table', t)
	self._watched = t
end
function Text:unwatch() self._watched = nil end

-- clear the current text
function Text:clear()
	for k in pairs(self._text) do self._text[k] = nil end
end

-- set the maximum number of lines
function Text:setMaxLines(max)
	verify('number', max)
	self._maxLines = max
end

-- set the margin between the frame edge and the text
function Text:setMargin(margin)
	verify('number', margin)
	self._margin = margin
	self:_drawFB()
end

-- set the justification
function Text:setJustifyLeft()   self._justify = 'l'; self:_drawFB() end
function Text:setJustifyRight()  self._justify = 'r'; self:_drawFB() end
function Text:setJustifyCenter() self._justify = 'c'; self:_drawFB() end

-- set the vertical alignment
function Text:setAlignTop()    self._align = 't'; self:_drawFB() end
function Text:setAlignBottom() self._align = 'b'; self:_drawFB() end
function Text:setAlignCenter() self._align = 'c'; self:_drawFB() end

-- onTick - check watched table
function Text:_onTick(dt, x, y)
	if self._watched then self:setText(self._watched) end
	return Frame._onTick(self, dt, x, y)
end

-- override Frame:_drawFB()
function Text:_drawFB()
	self._bfb = self._bfb or self:_getFramebuffer()
	pushRenderTarget(self._bfb)
	self:_drawBackground()


	if self._text and #self._text > 0 then
		if self._curStyle then
			local font = self._curStyle:getFont()
			if font then
				local height = font:getHeight()
				local margin = self._margin or 0
				local text = self._text
				local textLines = #text
				local maxLines = math_floor((self:getHeight() - (2*margin)) / height)
				local numLines = textLines > maxLines and maxLines or textLines
				local totalHeight = height * numLines
				local halfHeight = totalHeight/2
				local fontcolor = self._curStyle:getFGColor()

				setFont(font)
				setColor(fontcolor)

				for i=1,numLines do
					local line = text[i]
					local h = (i-1) * height
					local w = font:getWidth(line)
					local x, y

					if     'l' == self._justify then
						x = margin
					elseif 'c' == self._justify then
						local cx = self:getWidth() / 2
						x = math_floor(cx - (w/2))
					elseif 'r' == self._justify then
						x = self:getWidth() - (margin + w)
					else
						x = 0
						warning('Unjustified (justify is set to %q)',
							tostring(self._justify))
					end

					if     't' == self._align then
						y = margin + h
					elseif 'c' == self._align then
						local cy = self:getHeight() / 2
						y = math_floor(cy - halfHeight) + h
					elseif 'b' == self._align then
						y = self:getHeight() - (margin + totalHeight) + h
					else
						y = 0
						warning('Unaligned (align is set to %q)',
							tostring(self._align))
					end

					gprint(line, x, y)
				end -- for i=1,numLines

				-- print cursor
				if self._showCursor then
					local lastLine = text[numLines]
					local y = (totalHeight - height) + margin
					local x = font:getWidth(lastLine) + 4

					setColor(fontcolor)
					rectangle('fill', x, y, 4, height)
				end -- if self._showCursor
			end -- if font
		end -- if self._curStyle
	else
		-- print cursor when no text
		if self._showCursor then
			if self._curStyle then
				local font = self._curStyle:getFont()
				if font then
					local fontcolor = self._curStyle:getFGColor()
					local height = font:getHeight()
					local margin = self._margin or 0

					setColor(fontcolor)
					rectangle('fill', margin, margin, 4, height)
				end -- if font
			end -- if self._curStyle
		end -- if self._showCursor
	end -- if self._text

	popRenderTarget()
	self._ffb, self._bfb = self._bfb, self._ffb
end

-- the class
return Text
