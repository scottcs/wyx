local Class = require 'lib.hump.class'
local Text = getClass 'wyx.ui.Text'

local string_len = string.len
local string_sub = string.sub
local format = string.format

-- TextEntry
-- A text frame that gathers keyboard input.
local TextEntry = Class{name='TextEntry',
	inherits=Text,
	function(self, ...)
		Text.construct(self, ...)
	end
}

-- destructor
function TextEntry:destroy()
	self._isEnteringText = nil
	self:_clearCallback()
	Text.destroy(self)
end

-- clear the callback
function TextEntry:_clearCallback()
	self._callback = nil
	if self._callbackArgs then
		for k,v in pairs(self._callbackArgs) do self._callbackArgs[k] = nil end
		self._callbackArgs = nil
	end
end

-- set the callback function and arguments
-- this will be called when editing mode ends
function TextEntry:setCallback(func, ...)
	verify('function', func)
	self:_clearCallback()

	self._callback = func

	local numArgs = select('#', ...)
	if numArgs > 0 then self._callbackArgs = {...} end
end


-- override Frame:onRelease()
function TextEntry:onRelease(button, mods)
	if self._pressed then
		if 'l' == button then self:toggleEnterMode() end
	else
		self:toggleEnterMode(false)
	end
end

-- toggle whether we're entering text or not
function TextEntry:toggleEnterMode(status)
	if type(status) == 'boolean' then
		self._isEnteringText = status
	else
		self._isEnteringText = not self._isEnteringText
	end

	if self._isEnteringText then
		self:showCursor()
	else
		self:hideCursor()
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
function TextEntry:onKey(key, unicode, unicodeValue, mods)
	if not self._isEnteringText then return end

	if self._text then
		-- copy the entire text
		local text = {}
		local numLines = #self._text
		for i=1,numLines do text[i] = self._text[i] end
		
		local lineNum = numLines

		if lineNum < 1 then lineNum = 1 end
		local line = text[lineNum] or ''

		local doCallback = false

		local _stopEntering = function()
			self:toggleEnterMode(false)
			self:handleMouseRelease(love.mouse.getPosition())
		end

		local _nextLine = function()
			if self._maxLines == 1 then
				_stopEntering()
				doCallback = true
			else
				local nextLine = lineNum + 1
				if nextLine > self._maxLines then nextLine = self._maxLines end
				text[nextLine] = text[nextLine] or ''
			end
		end

		switch(key) {
			backspace = function()
				local len = string.len(line)
				line = string_sub(line, 1, -2)
				if string.len(line) == len then
					text[lineNum] = nil
					lineNum = lineNum - 1
					if lineNum < 1 then lineNum = 1 end
					line = text[lineNum] or ''
				end
			end,

			['return'] = _nextLine,
			kpenter = _nextLine,
			escape = _stopEntering,

			default = function()
				if unicode then
					line = format('%s%s', line, unicode)
				end
			end,
		}

		text[lineNum] = line
		self:setText(text)

		if doCallback then
			if self._callback then
				local args = self._callbackArgs
				if args then
					self._callback(unpack(args))
				else
					self._callback()
				end
			end
		end
	else
		warning('Text is missing!')
	end

	return true
end


-- the class
return TextEntry
