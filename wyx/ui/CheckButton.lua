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
	self._checked = nil
	Button.destroy(self)
end

-- set the checkedCallback function and arguments
-- this will be called when the button is checked or unchecked
function CheckButton:setCheckedCallback(func, ...)
	self:setCallback('checked', func, ...)
end

-- override Button:onRelease()
function CheckButton:onRelease(button, mods)
	if button == 1 then self:_toggleCheck() end
	Button.onRelease(self, button, mods)
end

function CheckButton:check() self:_toggleCheck(true) end
function CheckButton:uncheck() self:_toggleCheck(false) end

function CheckButton:_toggleCheck(on)
	if nil == on then on = not self._checked end
	self._checked = on

	self:_callCallback('checked', self._checked)

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
