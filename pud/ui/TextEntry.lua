local Class = require 'lib.hump.class'
local Text = getClass 'pud.ui.Text'
local KeyboardEvent = getClass 'pud.event.KeyboardEvent'

local string_len = string.len
local string_sub = string.sub
local format = string.format

-- TextEntry
-- A text frame that gathers keyboard input.
local TextEntry = Class{name='TextEntry',
	inherits=Text,
	function(self, ...)
		Text.construct(self, ...)

		InputEvents:register(self, KeyboardEvent)
	end
}

-- destructor
function TextEntry:destroy()
	self._isEnteringText = nil

	-- Frame will unregister all InputEvents
	Text.destroy(self)
end

-- override Frame:onRelease()
function TextEntry:onRelease(button, mods)
	if self._pressed then
		if 'l' == button then
			self._isEnteringText = not self._isEnteringText
		end
	end
end

-- override Frame:onHoverIn()
function TextEntry:onHoverIn(x, y)
	if self._isEnteringText then return end
	Text.onHoverIn(self, x, y)
end

-- override Frame:onHoverOut()
function TextEntry:onHoverOut(x, y)
	if self._isEnteringText then return end
	Text.onHoverOut(self, x, y)
end

-- override Frame:switchToNormalStyle()
function TextEntry:switchToNormalStyle()
	if self._isEnteringText then return end
	Text.switchToNormalStyle(self)
end

-- override Frame:switchToHoverStyle()
function TextEntry:switchToHoverStyle()
	if self._isEnteringText then return end
	Text.switchToHoverStyle(self)
end

-- capture text input if in editing mode
function TextEntry:KeyboardEvent(e)
	if not self._isEnteringText then return end

	if self._text then
		-- copy the entire text
		local text = {}
		local numLines = #self._text
		for i=1,numLines do text[i] = self._text[i] end
		
		local lineNum = numLines

		if lineNum < 1 then lineNum = 1 end
		local line = text[lineNum] or ''

		local key = e:getKey()
		switch(key) {
			backspace = function()
				line = string_sub(line, 1, -2)
				if string.len(line) < 1 then
					text[lineNum] = nil
					lineNum = lineNum - 1
					if lineNum < 1 then lineNum = 1 end
					line = text[lineNum] or ''
				end
			end,

			['return'] = function()
				local nextLine = lineNum + 1
				if nextLine > self._maxLines then nextLine = self._maxLines end
				text[nextLine] = text[nextLine] or ''
			end,

			escape = function()
				self._isEnteringText = false
				self:_handleMouseRelease(love.mouse.getPosition())
			end,

			default = function()
				local unicode = e:getUnicode()
				if unicode then
					line = format('%s%s', line, unicode)
				end
			end,
		}

		text[lineNum] = line
		self:setText(text)
		self:_drawFB()
	else
		warning('Text is missing!')
	end
end


-- the class
return TextEntry
