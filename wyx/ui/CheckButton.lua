local Class = require 'lib.hump.class'
local Frame = getClass 'wyx.ui.Frame'
local Button = getClass 'wyx.ui.Button'

-- CheckButton
-- a clickable Frame
local CheckButton = Class{name='CheckButton',
	inherits=Button,
	function(self, ...)
		Button.construct(self, ...)
		self._checked = false
	end
}

-- destructor
function CheckButton:destroy()
	self:_clearCheckedCallback()
	self._checked = nil
	Button.destroy(self)
end

-- clear the callback
function CheckButton:_clearCheckedCallback()
	self._checkedCallback = nil
	if self._checkedCallbackArgs then
		for k,v in self._checkedCallbackArgs do self._checkedCallbackArgs[k] = nil end
		self._checkedCallbackArgs = nil
	end
end

-- set the checkedCallback function and arguments
-- this will be called when the button is checked or unchecked
function CheckButton:setCheckedCallback(func, ...)
	verify('function', func)
	self:_clearCheckedCallback()

	self._checkedCallback = func

	local numArgs = select('#', ...)
	if numArgs > 0 then self._checkedCallbackArgs = {...} end
end

-- override Button:onRelease()
function CheckButton:onRelease(button, mods)
	if button == 'l' then self:_toggleCheck() end
	Button.onRelease(button, mods)
end

function CheckButton:check() self:_toggleCheck(true) end
function CheckButton:uncheck() self:_toggleCheck(false) end

function CheckButton:_toggleCheck(on)
	if nil == on then on = not self._checked end
	self._checked = on

	if self._checkedCallback then
		local args = self._checkedCallbackArgs
		if args then
			self._checkedCallback(self._checked, unpack(args))
		else
			self._checkedCallback(self._checked)
		end
	end

	if not self._checked then self._hovered = true end
	self._needsUpdate = true
end

-- override Frame:onHoverIn()
function CheckButton:onHoverIn(x, y)
	if self._checked then return end
	Button.onHoverIn(self, x, y)
end

-- override Frame:onHoverOut()
function CheckButton:onHoverOut(x, y)
	if self._checked then return end
	Button.onHoverOut(self, x, y)
end

-- override Frame:switchToNormalStyle()
function CheckButton:switchToNormalStyle()
	if self._checked then return end
	Button.switchToNormalStyle(self)
end

-- override Frame:switchToHoverStyle()
function CheckButton:switchToHoverStyle()
	if self._checked then return end
	Button.switchToHoverStyle(self)
end


-- the class
return CheckButton
