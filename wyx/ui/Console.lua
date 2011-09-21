local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Text = getClass 'wyx.ui.Text'
local TextEntry = getClass 'wyx.ui.TextEntry'
local Deque = getClass 'wyx.kit.Deque'
local InputCommandEvent = getClass 'wyx.event.InputCommandEvent'
local command = require 'wyx.ui.command'
local ui = require 'ui.Console'
local depths = require 'wyx.system.renderDepths'

local format, match = string.format, string.match
local unpack = unpack
local colors = colors

-- Console
-- Provides a feedback and command console for debugging and cheating.
local Console = Class{name='Console',
	inherits=Frame,
	function(self)
		Frame.construct(self, ui.main.x, ui.main.y, ui.main.w, ui.main.h)
		self:setNormalStyle(ui.main.normalStyle)
		self:setDepth(depths.console)

		-- don't call self:hide() here because it will unregister keys
		self._show = false

		self._buffer = Deque()
		self._firstLine = 0

		UISystem:registerKeys(ui.keysID, ui.keys)
		InputEvents:register(self, InputCommandEvent)
	end
}

-- destructor
function Console:destroy()
	InputEvents:unregisterAll(self)
	UISystem:unregisterKeys(ui.keysOnShowID)
	UISystem:unregisterKeys(ui.keysID)
	self._buffer:destroy()
	self._buffer = nil
	self._firstLine = nil
	Frame.destroy(self)
end

function Console:InputCommandEvent(e)
	local cmd = e:getCommand()
	--local args = e:getCommandArgs()
	--
	switch(cmd) {
		CONSOLE_TOGGLE = function() self:toggle() end,
		CONSOLE_HIDE = function() self:hide() end,
		CONSOLE_PAGEUP = function() self:pageup() end,
		CONSOLE_PAGEDOWN = function() self:pagedown() end,
		CONSOLE_TOP = function() self:top() end,
		CONSOLE_BOTTOM = function() self:bottom() end,
		CONSOLE_CLEAR = function() self:clearBuffer() end,
	}
end


function Console:_setDrawColor()
	local sb = ui.scrollback
	local color = (self._firstLine == 0) and sb.normalcolor or sb.scrollcolor
	self:setColor(color)
	self._needsUpdate = true
end

function Console:clearBuffer()
	self._buffer:clear()
	self._firstLine = 0
	self:_setDrawColor()
end

function Console:pageup()
	self._firstLine = self._firstLine + ui.scrollback.lines
	local max = 1+(self._buffer:size() - ui.scrollback.lines)
	if self._firstLine > max then self._firstLine = max end
	self:_setDrawColor()
end

function Console:pagedown()
	self._firstLine = self._firstLine - ui.scrollback.lines
	if self._firstLine < 0 then self._firstLine = 0 end
	self:_setDrawColor()
end

function Console:bottom()
	self._firstLine = 0
	self:_setDrawColor()
end

function Console:top()
	self._firstLine = 1+(self._buffer:size() - ui.scrollback.lines)
	self:_setDrawColor()
end

local colorStyles = {}
function Console:print(color, message, ...)
	local style = ui.line.normalStyle

	if type(color) == 'string' and colors[color] then
		color = colors[color]
	end

	if type(color) == 'table' then
		style = colorStyles[color]
		if not style then
			style = ui.line.normalStyle:clone({fontcolor = color})
			colorStyles[color] = style
		end
		self:_print(style, message, ...)
	else
		self:_print(style, color, message, ...)
	end
end

function Console:_print(style, msg, ...)
	if select('#', ...) > 0 then msg = format(msg, ...) end
	local text = self:_makeText(style, msg)
	self:addChild(text)
	self._buffer:push_front(text)

	while self._buffer:size() > ui.scrollback.bufferSize do
		local popped = self._buffer:pop_back()
		self:removeChild(popped)
		popped:destroy()
	end

	if self._firstLine == 0 then
		self._needsUpdate = true
	end
end

function Console:_updateForeground()
	local count = ui.scrollback.lines
	local drawY = ui.scrollback.startY
	local skip = 1

	for t in self._buffer:iterate() do
		if skip >= self._firstLine and count > 0 then
			drawY = drawY - ui.line.h
			t:setPosition(ui.scrollback.x, drawY)
			t:show()
			count = count - 1
		else
			t:hide()
		end
		skip = skip + 1
	end
end

-- make a text line
function Console:_makeText(style, text)
	local f = Text(0, 0, ui.line.w, ui.line.h)
	f:setNormalStyle(style)
	f:setText(text)
	f:hide()

	return f
end

-- override Frame:show and hide to register/unregister keys
function Console:show()
	UISystem:registerKeys(ui.keysOnShowID, ui.keysOnShow)
	Frame.show(self)
end
function Console:hide()
	Frame.hide(self)
	UISystem:unregisterKeys(ui.keysOnShowID)
end


-- the class
return Console
